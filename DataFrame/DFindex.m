function [dataIndex, Values, sparseIdx] = ...
    DFindex(Data,fields,excludeIdx,Values,isND,inclNaNEmpty)
% DFINDEX
%        Generates an index for a structure of arrays for any number of fields
%
%    [dataIndex ] = DFindex(Data,fields) 
%    [dataIndex, Values ] = DFindex(Data,fields) 
%    [dataIndex, Values, sparseIdx] = DFindex(Data,fields) 
%    [dataIndex, Values, sparseIdx] = ...
%            DFindex(Data,fields,excludeIdx,Values,isND,inclNaNEmpty) 
%
% parameters
%----------------------------------------------------------------
%    "Data"         - a data frame
%    "fields"       - a cell array of field names in "Data"
%    "excludeIdx"   - an optional list of indices to remove from consideration
%    "Values"       - a structure of fields of alphanumerically sorted unique values by which to index 
%    "isND"         - boolean whether dataIndex is N-dim (default=1) or linear 
%    "inclNaNEmpty" - boolean whether to ignore NaNs and empty strings (default=0)
%                     or to set all NaNs equal and all empty strings equal (=1)
%
% outputs
%----------------------------------------------------------------
%    "dataIndex" - an N-dim or linear cell array of sets of indices: each set of
%                  indices represents a unique coordinate of values from "fields"
%                  if sparseIdx is defined (nargout=3), then dataIndex is linear,
%                  has zero empty cells, and requires sparseIdx for indexing
%    "Values"    - a structure containing field names from "fields" and containing
%                  unique values from Data.(fieldname) in alphanumerically ascending order
%    "sparseIdx" - a M by N matrix of subscripts. Each row of N values are subscripts
%                  into a unique coordinate of N-Dimensional dataIndex. M is the
%                  number of non-empty coordinates of dataIndex
%----------------------------------------------------------------
%    
%  Note: the order of the sets is ascending by Values such that:
%        dataIndexNDim = reshape(dataIndex,structfun(@numel,Values)');
%        This function requires uniquenotmiss and DFverify in order to run
%
%    Hy Carrinski
%    Broad Institute
%    Created  21Jan2007
%    Modified 16Nov2008


% QC the input
assert(nargin >= 2 && not(isempty(fields)), ...
    'ccbr:BadInput','DFindex requires at least two inputs');

% Allow index to match other data structure
if nargin < 4 || isempty(Values) || ~isstruct(Values)
    isInputValues = 1;
else
    isInputValues = 0;
    assert(all(structfun(@issorted,Values)),'ccbr:BadInput',...
        'Values must be sorted in ascending order');
end
% Allow single dimensional output (default is multidimensional)
if nargin < 5 || isempty(isND)
    isND = 1;
end
if nargin < 6 || isempty(inclNaNEmpty)
   inclNaNEmpty = false;
end

% Make sure fields is a cell array of strings
if ischar(fields)
    fields = cellstr(fields); 
end
assert(iscellstr(fields),'ccbr:BadInput','Cell array fields must contain strings');

% Check that fields are present
assert(all(isfield(Data,fields)),'ccbr:BadInput', ...
    'Some requested fields are not present in Data');

% Ensure that every column is 1D and has an equal number of rows
[isOkay, numRows] = DFverify(Data,true);
assert(isOkay == 1,'ccbr:BadInput','Fields in Data must be arrays of size N x 1');

%Find class of each field to be able to exclude some rows
numFields = numel(fields);
formats = cell(numFields,1);
for i = 1:numFields
    formats{i} = class(Data.(fields{i}));
    if strcmpi(formats{i},'double') && exist('excludeIdx','var') 
        Data.(fields{i})(excludeIdx) = NaN;  % Ignore these entire rows
    elseif strcmpi(formats{i},'cell') && exist('excludeIdx','var') 
        Data.(fields{i})(excludeIdx) = {''}; % Ignore these entire rows
    end 
end
if isInputValues
    for i = 1:numFields
         Values.(fields{i}) = uniquenotmiss(Data.(fields{i}),inclNaNEmpty);
    end
else
    Values = DFkeepcol(Values,fields); % Limit Values to input field names
    UnsortedValues = Values;
    for i = 1:numFields
         Values.(fields{i}) = uniquenotmiss(Values.(fields{i}),inclNaNEmpty);
    end
    if not(isequalwithequalnans(Values,UnsortedValues))
        warning('ccbr:BadInput','elements in structure Values re-ordered by DFindex');
    end
    Values = orderfields(Values,fields);
    if not(isequalwithequalnans(Values,UnsortedValues))
        warning('ccbr:BadInput','fields in structure Values re-ordered by input fields');
    end
end

% Generate vectors of indices into Values ( "keys" ) for each
% pair ("field name", "unique value") from Data
% vals must contain the unique members from Values.(fields{i})
% in the same order
% We want keyIdx to contain numbers that correctly map
% to an index of Values.(Field)
keyIdx = zeros(numRows,numFields);
for i = 1:numFields
    [ vals tmpI origIdx ] = uniquenotmiss(Data.(fields{i}),inclNaNEmpty);
    matchIdx1             = ismember(vals,Values.(fields{i}));
    if inclNaNEmpty && isnumeric(vals) && any(isnan(Values.(fields{i})))
        matchIdx1 = or(matchIdx1,isnan(vals));
    end
    % remove non-indexed unique values from vals
    vals(not(matchIdx1))  = [];
    tmpI = [];
    matchIdx2             = ismember(Values.(fields{i}),vals);
    if inclNaNEmpty && isnumeric(vals) && any(isnan(Values.(fields{i})))
        matchIdx2 = or(matchIdx2,isnan(Values.(fields{i})));
    end
    idxIntoValues            = zeros(size(matchIdx1));
    % because vals and Values are both sorted in ascending order
    idxIntoValues(matchIdx1) = find(matchIdx2);
    % pad first element of idxIntoValues (for origIdx == 0)
    idxIntoValues            = [0; idxIntoValues];
    % offset origIdx by one ( min(origIdx+1) == 1 ) and index into
    keyIdx(:,i)              = idxIntoValues(origIdx+1);    
end

% flag rows of keyIdx for which any element is 0.
goodRows                = all(keyIdx,2); % a logical vector
keyIdx(not(goodRows),:) = 0;

% Reverse columns so UNIQUE sorts rows properly
[sparseIdx,I,J] = unique(keyIdx(:, end:-1:1), 'rows');
% sparseIdx contains the unique rows of keyIdx
% J has the index of sparseIdx in the order of keyIdx
% i.e., group id for rows of keyIdx
% i.e., sparseIdx(J,:) equals keyIdx

% If rows contain any NaN or empty strings, sparseIdx(1,:) equals 0
% remove those rows, and make those indices of J to contain 0's
if not(all(goodRows))
    sparseIdx(1,:) = [];
    I              = [];
    J              = J - 1;
end
% Check whether sparseIdx is now empty
if isempty(sparseIdx)
    dataIndex = {};
    sparseIdx = {};  % UNSURE about {} vs []
    warning('ccbr:EmptyArray','dataIndex is empty');
    return
end

% Restore column ordering to match field order
sparseIdx = sparseIdx(:, end:-1:1);

% Row vector containing size of each dimension and a
% minimum of two elements
sizFullIdx = transpose(structfun(@numel, Values));
if isscalar(sizFullIdx)
    sizFullIdx = [sizFullIdx, 1];
end

% Generate single dimensional list of present indices
% from full n-dim index
dimFactor = [1, cumprod(sizFullIdx(1:end-1))];
presentIdx = sparseIdx(:,1);
for i = 2:size(sparseIdx,2)
    presentIdx = presentIdx + (sparseIdx(:,i) - 1) * dimFactor(i);
end

% Modify J to hold indices to full n-dim index
J(goodRows) = presentIdx(J(goodRows));

% Sort J into the same order as presentIdx
[idGroup, sortIdxJ] = sort(J,'ascend');

% Remove rows for which J is 0
sortIdxJ(idGroup==0) = [];
idGroup( idGroup==0) = [];

% Find the size of the blocks in the sorted J
sizGroup = diff(find([1; diff(idGroup); 1])); 

% Convert the index into the unsorted J to a cell array
dataList = mat2cell(sortIdxJ, sizGroup);

% Check whether sparse case
if nargout == 3
    %sparse case
    dataIndex = dataList;
else
    % Initialize index
    dataIndex = cell(prod(sizFullIdx),1);

    % Loop over full dataIndex to fill each cell with matching indices (if any)
    for i = 1:numel(presentIdx)
        dataIndex{presentIdx(i)} = dataList{i};
    end
    % convert output to an N-dimensional cell array
    if isND
        dataIndex = reshape(dataIndex,sizFullIdx);
    end
end
