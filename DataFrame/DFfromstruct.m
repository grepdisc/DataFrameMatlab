function [SNew, errmsg] = DFfromstruct(S)
% DFFROMSTRUCT
%       Converts a structure array to a data frame to
%
%    [SNew, errmsg] = DFtostruct(S)
% parameters
% ----------------------------------------------------------------
%    "S"         -  a DF or a structure array
% output
% ----------------------------------------------------------------
%    "SNew"      -  a structure array or a DF depending on "isReverse"
%    "errmsg"    -  error message
% ----------------------------------------------------------------
% 
%    Hy Carrinski
%    Broad Institute

fields  = fieldnames(S);
numRows = numel(S);
SNew    = struct([]);    
errmsg  ='';

if isscalar(S) || isempty(S)
    errmsg = sprintf('Structure unchanged, since expected a structure' ...
                       'array with greater than one element');
    error('ccbr:BadInput','errmsg');
end

% perform conversion
for i = 1:numel(fields)
    currFld = fields{i};
    SNew(1).(currFld) = vertcat(S.(currFld)); 
end

% confirm conversion
[isOkayNew, numRowsNew] = DFverify(SNew);
assert(isequal(numRows,numRowsNew),
   'ccbr,BadInput', sprintf(['Could not convert S: S had %g rows ' ...
   'and SNew had %g rows'], numRows, numRowsNew));
