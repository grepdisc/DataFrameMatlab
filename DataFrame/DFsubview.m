function outCharMat = DFsubview(S,colName,varargin)
% DFSUBVIEW
%        Display a few rows from a structure
%
%     outCharMat = DFsubview(S)
%     outCharMat = DFsubview(S,colName,idx)
%     outCharMat = DFsubview(S,colName,idx,colWidth,options)
%
% parameters
% ----------------------------------------------------------------
%    "S"            - a data frame
%    "colName"      - a field within S. Show only unique values
%                     and frequency of each value. "idx" is now
%                     and index into these unique values
%    "idx"          - a logical or positive integer index into S
%    "colWidth"     - a positive integer equal to the maximum width per column
%    "options"      - structure of options for formatting same as DFwrite
%                     supporting additional fields
%                     "isPrintIndex" - a logical determining if an index column is printed
%                     "maxDig"       - a positive integer giving a number
%                                      beyond which decimals will be truncated
% output
% ----------------------------------------------------------------
%    "outCharMat"   - a matrix of type character displaying frequency distribution
% ----------------------------------------------------------------
%
%     Hy Carrinski
%     Broad Institute
%
%   Requires DFkeepcol.m, DFvalues.m, DFview.m

% Prepare inputs 
if nargin < 2 || isempty(colName)
    error('ccbr:BadInput', 'second input is required');
else
    assert(ischar(colName) && isfield(S,colName), ...
        'ccbr:BadInput', 'second input must be a field name');
end

S = DFkeepcol(S,colName);
[~,~,Sh] = DFvalues(S);
outCharMat = DFview(Sh.(colName),varargin{:});
