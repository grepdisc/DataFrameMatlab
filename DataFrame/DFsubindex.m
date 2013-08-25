function [Data Meta] = DFsubindex(Data,groupBy,indexBy,indexName,inclNaNEmpty,isAscendVec)
% DFSUBINDEX
%       index a data frame within independent groups
%
%    [IndexedData Meta] = DFsubindex(Data,groupBy,indexBy,indexName,inclNaNEmpty,isAscendVec)
%
% parameters
%----------------------------------------------------------------
%    "Data"       - a dataframe
%    "groupBy"    - a cell array of field names within which to index independently
%    "indexBy"    - a cell array of field names by which to index
%    "indexName"  - a string containing the name for the indexed field
%    "inclNaNEmpty" - boolean whether to ignore NaNs
%                     and empty strings (default=0)
%                     or to set all NaNs equal and all empty strings equal (1)
%    "isAscendVec"- a logical vector whether each column
%                   is indexed in ascending order (true is default)
%
% outputs
%----------------------------------------------------------------
%    "IndexedData" - an indexed version of Data
%    "Meta"        - a data frame which is a LUT between values and index
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
errMsg1 = '2nd and 3rd inputs "groupBy" and "indexBy" must be cell arrays';
try
    assert(nargin >= 3);
    groupBy = checkFields(groupBy);
    indexBy = checkFields(indexBy);
catch    
    error('ccbr:BadInput',errMsg1);
end

if nargin < 4 || isempty(indexName) 
   error('ccbr:BadInput','field name required for indexed field');
end

if nargin < 5 || isempty(inclNaNEmpty)
   inclNaNEmpty = false;
end

fields = [groupBy, indexBy];

% Check that fields are present
assert(all(isfield(Data,fields)), ...
    'ccbr:BadInput','Some requested fields are not present in input');

% Check that no fields will be overwritten
assert(not(isfield(Data,indexName)), ...
    'ccbr:BadInput','Cannot create a field that already exists in Data');

% Ensure that every relevant column is 1D and has an equal number of rows
[isOkay, numRows] = DFverify(DFkeepcol(Data,fields),true);
assert(isOkay == 1,'ccbr:BadInput','fields must be arrays of size N x 1');
% QC is complete

%
% first sort by indexBy
% second make groups and apply numbers

[idx, val, spIdx] = DFindex(Data,groupBy); % ignores NaNs here
Data.(indexName) = nan(numRows,1);
for i = 1:numel(idx)
    D = DFkeeprow(DFkeepcol(Data,indexBy,1),idx{i});
    D = DFaddindex(D,indexBy,indexName,inclNaNEmpty,isAscendVec);
    Data.(indexName)(idx{i}) = D.(indexName); 
end

if nargout > 1
   Meta = DFsort(DFkeepcol(Data,[fields,indexName],1),[groupBy,indexName],1,true);
end

function fields = checkFields(fields)
%    CHECKFIELDS
%        check input fields to ensure they are valid
%
    assert(not(isempty(fields)) && ...
        (iscellstr(fields) || ischar(fields)));
    if ischar(fields)
        fields = cellstr(fields); 
    end
