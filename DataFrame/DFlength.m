function numRows = DFlength(S)
% DFLENGTH
%       count number of rows in a data frame
%
%    numRows = DFlength(S)
% parameters
% ----------------------------------------------------------------
%    "S"          - a 1x1 structure of arrays of any type
% output
% ----------------------------------------------------------------
%    "numRows"    - number of rows in data frame
%                   maximum dimension of array in 1st field of structure
% ----------------------------------------------------------------
% Depends on DFverify
% 
%    Hy Carrinski
%    Broad Institute

[isOkay, numRows] = DFverfiy(S);
