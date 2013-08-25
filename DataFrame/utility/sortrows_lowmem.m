function [x,ndx] = sortrows_lowmem(x,col)
%sortrows_lowmem Sort rows in ascending order.
%   Y = sortrows_lowmem(X) sorts the rows of the matrix X in ascending order as a
%   group. X is a 2-D real non-sparse matrix
%   sortrows_lowmem is a modified version of MATLAB's sortrows
%   function for cases where memory is very limited   

%   Notes
%   -----
%   sortrows_lowmem uses a stable version of quicksort.  NaN values are sorted
%   as if they are higher than all other values, including +Inf.

n = size(x,2);
if nargin > 1 
    if isnumeric(col)
        col = double(col);
    else
        error('MATLAB:sortrows_lowmem:COLnotNumeric', 'COL must be numeric.');
    end
    if ( ~isreal(col) || numel(col) ~= length(col) ||...
            any(floor(col) ~= col) || any(abs(col) > n) || any(col == 0) )
        error('MATLAB:sortrows_lowmem:COLmismatchX',...
            'COL must be a vector of column indices into X.');
    end
    if numel(col) < n
        x_orig = x;
    end
    % use sort to avoid reordering the columns
    x = x(:,sort(abs(col),'ascend'));
else
    col = 1:n;
end

if isreal(x) && ~issparse(x)
    if n > 3
        % Call MEX-file for non-sparse real arrays
        % with greater than 3 elements per row
        ndx = sortrowsc(x, col);
    else
        ndx = sort_back_to_front(x, col);
    end
else
    error('ccbr:sortrows_lowmem:BadInput',...
        'use sortrows when input is sparse or non-real');
end

% Rearrange input rows according to the output of the sort algorithm.
if numel(col) < n
    x = x_orig;
    x_orig = [];
    x = x(ndx,:);
else
    x = x(ndx,:);
end

%--------------------------------------------------
function ndx = sort_back_to_front(x, col)
% NDX = SORT_BACK_TO_FRONT(X, COL) sorts the rows of X by sorting each
% column from back to front.  This is the sortrows algorithm used in MATLAB
% 6.0 and earlier.

[m,n] = size(x);
ndx = (1:m)';
for k = n:-1:1
    if (col(k) < 0)
        [ignore,ind] = sort(x(ndx,k),'descend');
    else
        [ignore,ind] = sort(x(ndx,k),'ascend');
    end
    ndx = ndx(ind);
end

