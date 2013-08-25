function [Data Meta] = DFaddindex(Data,fields,indexNames,inclNaNEmpty,isAscendVec)
% DFADDINDEX
%       index a data frame for any number of fields
%
%    [IndexedData Meta] = DFaddindex(Data,fields,indexNames,inclNaNEmpty,isAscendVec)
%
% parameters
%----------------------------------------------------------------
%    "Data"       - a dataframe
%    "fields"     - a cell array of field names in "Data" to index
%    "indexNames" - a cell array of names for the indexed fields, a single
%                   name results in one index, multiple names result in
%                   one index per name, if empty (default), results in a single
%                   index per name, with the ith name being "id<fields{i}>"
%    "inclNaNEmpty" - boolean whether to ignore NaNs and empty strings (default=0)
%                     or to set all NaNs equal and all empty strings equal (=1)
%    "isAscendVec"- a logical vector whether each input field
%                   is sorted ascending (true is default)
%
% outputs
%----------------------------------------------------------------
%    "IndexedData" - an indexed version of Data
%    "Meta"        - a cell array of data frames, where each cell contains
%                    a LUT between values and index
%----------------------------------------------------------------
%
% Note: if NaN's or empty strings should be included in the indexing,
%       it is suggested to set inclNaNEmpty=true, otherwise, all rows
%       containing any NaNs will receive an index of 0.
%
%    Hy Carrinski
%    Broad Institute
%    Based on DFindex

% QC the input
if nargin < 2 || isempty(fields) || not(iscellstr(fields) || ischar(fields))
    error('ccbr:BadInput','Second input "fields" must be a cell array');
end
if ischar(fields)
    fields = cellstr(fields); 
end

if nargin < 3 || isempty(indexNames) 
   indexNames = cellfun(@(x) ['id' upper(x(1)) x(2:end) ], fields, 'UniformOutput',false);
end
if ischar(indexNames)
    indexNames = cellstr(indexNames); 
end

if nargin < 4 || isempty(inclNaNEmpty)
   inclNaNEmpty = false;
end

% Check that fields are present
assert(all(isfield(Data,fields)), ...
    'ccbr:BadInput','Some requested fields are not present in input');

% Check that no fields will be overwritten
assert(not(any(isfield(Data,indexNames))), ...
    'ccbr:BadInput','Cannot create a field that already exists in Data');

numFields = numel(fields);
% Check whether there is a single index field or an equal number of index fields
if numel(indexNames) == numFields
    isIndividualIndex = true;
elseif isscalar(indexNames)
    isIndividualIndex = false;
else
    error('ccbr:BadInput','Number of indices must be 1 or equal to number of index fields');
end

% Ensure that every relevant column is 1D and has an equal number of rows
[isOkay numRows] = DFverify(DFkeepcol(Data,fields),true);
assert(isOkay == 1,'ccbr:BadInput','fields must be arrays of size N x 1');

if nargin < 5 || isempty(isAscendVec)
   isAscendVec = true(numFields,1);
elseif isscalar(isAscendVec)
   isAscendVec = repmat(isAscendVec,numFields,1);
else
   isAscendVec = isAscendVec(:);
end
% QC is complete

% Index
if isIndividualIndex
    Meta = cell(numFields,1);
    for i = 1:numFields
        [Meta{i}.(fields{i}), tmpI, Data.(indexNames{i})] = ...
                                       uniquenotmiss(Data.(fields{i}),inclNaNEmpty);
        % permit reversal of sort order
        if not(isAscendVec(i))
            [Meta{i}.(fields{i}), Data.(indexNames{i})] = ...
                reverseIndex(Meta{i}.(fields{i}), Data.(indexNames{i}));
        end
        Meta{i}.(indexNames{i}) = transpose(1:numel(tmpI));
    end
else
    keyIdx = zeros(numRows,numFields);
    for i = 1:numFields
        [vals{i}, tmpI, keyIdx(:,i) ] = uniquenotmiss(Data.(fields{i}),inclNaNEmpty);
        % permit reversal of sort order
        if not(isAscendVec(i))
            [vals{i}, keyIdx(:,i)] = reverseIndex(vals{i},keyIdx(:,i));
        end
    end
    % when NaNs and empties are included, they are treated like any other value
    % from here on, if they are not included, a single NaN results in an index
    % of 0 for the entire row
    badRows = any(keyIdx == 0, 2);
    if any(badRows)
        [uniqKey, tmpI, Data.(indexNames{1})] = unique(keyIdx,'rows');
    else
        % flag rows of keyIdx for which any element is 0
        keyIdx(badRows,:) = 0;
        [uniqKey, tmpI, Data.(indexNames{1})] = unique(keyIdx,'rows');

        % adjust indexing so that these rows index to 0.
        indexOfZero = 1;
        uniqKey(indexOfZero,:) = [];
        tmpI(indexOfZero)      = [];
        Data.(indexNames{1})   = Data.(indexNames{1}) - indexOfZero;
    end
    if nargout > 1
        for i = 1:numFields
            Meta{1}.(fields{i}) = vals{i}(uniqKey(:,i));
        end
        Meta{1}.(indexNames{1}) = transpose(1:numel(tmpI));
    end
end

function [v, k] = reverseIndex(v,k)
% REVERSEINDEX
%    reverse the order of a vector of values and
%    a (longer) vector of keys into an index
%    treating an index of 0 as a special case
    v = v(end:-1:1);
    maxK = max(k);
    k = maxK + 1 - k;
    % reset NaNs and empties to index of zero
    k(k > maxK, 1) = 0; 
