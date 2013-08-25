function [isComplete numRows] = DFverify(S,isColumnar,checkType)
% DFVERIFY
%       test whether a structure contains fields of identical sizes
%
%    [isComplete numRows] = DFverify(S,isColumnar,checkType)
% parameters
% ----------------------------------------------------------------
%    "S"          - a 1x1 structure of arrays of any type
%    "isColumnar" - optional boolean to require fields to be column
%                   vectors (default = false)
%    "checkType"  - optional boolean to require fields to be of
%                   supported classes which includes: any numeric
%                   type, logical and cellstr (default = false)
% output
% ----------------------------------------------------------------
%    "isComplete" - values: 1 if all fields are the same size [and columnar]
%                           0 if one or more fields is a different size
%                          -1 if one or more fields is not a column vector,
%                             but all fields are the same size
%                          -2 if there is a field of an unsupported type
%    "numRows"    - number of rows in structure
%                   maximum dimension of array in 1st field of structure
% ----------------------------------------------------------------
%    Useful for verifying input read from or written to delimited text files
%    A DF which is an empty structure returns isComplete = 1 and numRows = 0
% 
%    Hy Carrinski
%    Broad Institute

if nargin < 2 || isempty(isColumnar)
    isColumnar = false;
end
assert(isstruct(S) && isscalar(S), 'ccbr:BadInput', ...
    'Input must be a DF (1x1 structure of arrays)');
if nargin < 3 || isempty(checkType)
    checkType = false;   % IS THIS IMPLEMENTED?
end
% Argument checking complete

isComplete = 1;
if isempty(S)
    numRows = 0;
    return
end
flds = fieldnames(S);
size_1st = size(S.(flds{1}));
for k = 1:numel(flds)
    currVec = S.(flds{k});
    size_kth = size(currVec);
    if not(checkType) || not(isempty(currVec)) || islogical(currVec) || ...
        isnumeric(currVec) || iscellstr(currVec) 
        if isequal(size_1st,size_kth)                 % same size
            if not(isColumnar) || ...
               isequal(size_1st(1), prod(size_kth))
                continue;     % success
            else
                isComplete = -1;
            end
        else
            isComplete = 0;
        end
    else
        isComplete = -2;
    end
    numRows = nan;
    return
end
if nnz(size_1st) > 1
    numRows = max(size_1st);
else
    numRows = 0;
end
