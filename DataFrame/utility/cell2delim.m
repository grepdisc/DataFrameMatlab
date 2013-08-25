function str = cell2delim(c,delim)
% CELL2DELIM
%        converts a cell array of strings to a delimited string
%
%    str = cell2delim(c,delim)
%
% parameters
%----------------------------------------------------------------
%    "c"        - an array of cells containing strings or numbers
%    "delim"    - a multi character delimiter or printf string to
%                 use as a delimiter (default is a single space).
%                 delimiter is printed literally and NOT converted
%                 using sprintf
% outputs
%----------------------------------------------------------------
%    "str"      - a row vector of characters consisting of the
%                 elements of "c" delimited by "delim"
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    Created  16 July  2009

if nargin < 2
    delim = ' ';
end

assert(not(isempty(c)) && iscellstr(c) && ischar(delim), ...
    'ccbr:BadInput','cell arrays of strings is required input');
c        = vertcat(transpose(c(:)), repmat({delim},1,numel(c)));
str      = horzcat(c{:});
str((end-numel(delim)+1):end) = [];
