function [C, header] = DFtocell(S)
% DFTOcell
%       Converts a dataframe with m fields, each of which is nx1,
%       into a nxm matrix M and mx1 cell array of strings
%
%    [C, Header] = DFtocell(S)
%
% parameters
% ----------------------------------------------------------------
%    "S"      - a data frame
% output
% ----------------------------------------------------------------
%    "C"      - a cell array with columns containing cells matching format's of S's fields.
%    "header" - a cell array of strings (column headers)
% ----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute

% QC
[isOkay, numRows] = DFverify(S,true,true);
assert(isOkay==1, 'ccbr:BadInput', ...
    ['DFtocell requires a data frame of cells containing numeric, ' ...
    'cell string, or logical arrays as input']);
% Generate header
header = fieldnames(S);
if isnan(numRows) || numRows == 0
    C = [];
    return
end
C = cell(numRows, numel(header));
for i = 1:numel(header)
    currFld = header{i};
    if iscell(S.(currFld)
        C(:,i) = S.(currFld);
    else
        C(:,i) = num2cell(S.(currFld));
    end
end
