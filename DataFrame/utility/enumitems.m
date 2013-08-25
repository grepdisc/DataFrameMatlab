function cellIdMat = enumitems(cellId, cellName)
% ENUMITEMS
%      cellIdMat = enumitems(cellId, cellName)
%
%      maps bits between reagents and products
%
% parameters
% ---------------------------------------------------------------
% "cellId"    - an 1xn cell array of m_i x 1 arrays of doubles where
%               i ranges from 1 to n
% "cellName"  - an 1xn cell array of m_i x 1 cell arrays of strings
%               where each string corresponds to an Id (optional)
%
% outputs
% ---------------------------------------------------------------
% "cellIdMat"  - an 1xn cell array of n-dimensional matrices of
%               doubles each matrix has exactly n-dimensions and
%               has m_i values in the ith dimension
%
% Notes: is called by unmergeStruct
%        Could modify enumitems to allow cellName to contain numbers as
%        well as strings and could convert cellID and cellName to be 
%        structures instead
% Hy Carrinski
% Broad Institute
% 05 Feb 2009

if nargin > 1
    error('Second input "cellName" not yet supported');
end

% array of numbers of items per set
numItems = cellfun(@numel,cellId);

% number of sets of items
numSets  = numel(numItems);

% preallocate memory
if numSets > 1
    cellIdMat{1} = nan(numItems);
    cellIdMat    = repmat(cellIdMat(1),1,numSets);
end

% generate the sets
for i = 1:numSets
    currSets     = numItems;         % init temporary variable
    currDims     = ones(1,numSets);  % init temporary variable
    if ( numSets == 1 )
        currDims = [ currDims 1 ];   % account for single set case
    end
    currSets(i)  = 1;
    currDims(i)  = numItems(i);
    cellIdMat{i} = repmat(reshape(cellId{i},currDims),currSets);
end

% Examples of operations to perform on the outputs:

% cellIdArray = cellfun(@(x) x(:), cellIdMat, 'UniformOutput', false);
% matItems    = cell2mat(cellIdArray);

% Optionally, can treat cellName interchangeably with "cellId"

% The following works only if each element of cellId is sorted indices 1:m_i
% cellNameArray = cellfun(@x(x,y) y(x), cellIdArray, cellName, ...
%                 'UniformOutput', false);
