function S = DFfrommat(M,header)
% DFFROMMAT
%    Converts a nxm matrix M and mx1 cell array header of strings
%    to a 1x1 structure S of m fields called each of which is nx1
%
%    S = DFfrommat(M,header)
%
% parameters
% ----------------------------------------------------------------
%    "M"      - a matrix of type numeric or logical
%    "header" - a cell array of strings of column headers
% output
% ----------------------------------------------------------------
%    "S"      - a 1x1 structure of arrays of any type
% ----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    Created 05Mar2008

% QC
[n, m] = size(M);
if nargin > 1
    assert(m == numel(header) && iscellstr(header), 'ccbr:BadInput', ...
        'DFfrommat requires a matrix and a cell array of strings as input');
else
    header = generate_headers(m);
end

% Generate structure
for i = 1:numel(header)
    S.(header{i}) = M(:,i);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function header = generate_headers(numCols)
%   header = generate_headers(numCols)
%   makes columns names for a given number of columns
    part1               = repmat('Column', numCols, 1);
    part2               = num2str(transpose((1:numCols)));
    part2(part2 == ' ') = '0'; % replace spaces with zeros
    header              = mat2cell([part1 part2],ones(numCols,1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
