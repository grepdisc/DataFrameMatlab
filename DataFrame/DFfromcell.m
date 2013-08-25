function S = DFfromcell(C,header)
% DFFROMCELL
%    Converts a nxm cell array C and mx1 cell array header of strings
%    to a 1x1 structure S of m fields called each of which is nx1
%
%    S = DFfromcell(C,header)
%
% parameters
% ----------------------------------------------------------------
%    "C"      - a cell array whose columns contain uniformly strings,
%               numbers or logicals
%    "header" - a cell array of strings of column headers
% output
% ----------------------------------------------------------------
%    "S"      - a data frame
% ----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute

% QC
[n, m] = size(C);
if nargin > 1
    assert(m == numel(header) && iscellstr(header), 'ccbr:BadInput', ...
        'DFfromcell requires a matrix and a cell array of strings as input');
else
    header = generate_headers(m);
end

assert(iscell(C),'ccbr:BadInput','first input of DFfromcell required to be a cell array');

% Generate structure
for i = 1:numel(header)
    if iscellstr(C(:,i))
        S.(header{i}) = C(:,i);
    else
        try
            S.(header{i}) = cell2mat(C(:,i));
        catch
            errMsg = sprintf('please check format within column %0.0f of input');
            error('ccbr:BadInput',errMsg);
        end
    end
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
