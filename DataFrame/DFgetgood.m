function [S numRows] = DFgetgood(S,options);
% DFGETGOOD
%        DFgetgood loads and qc's a file
%
%    [Data numRows] = DFgetgood(filepath)
%    [Data numRows] = DFgetgood(filepath,options)
%
% parameters
%----------------------------------------------------------------
%    "filepath" - path to a file (string) or structure representing file
%    "options"  -  structure used by DFread
% outputs
%----------------------------------------------------------------
%    "Data"     - a data frame 
%    "numRows"  - double number of rows in structure.
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
if nargin < 2
    options = [];
end

switch class(S)
   case 'char'
        filepath = S;
        S = DFread(filepath,[],[],options);
   case 'cell'
        filepath = S{1};
        S = DFread(filepath,[],[],options);
   case 'struct'
        filepath = 'First input';
   otherwise
        error('ccbr:BadInput','input to getqcdfile is not of an acceptable class');
end
[ isOkay numRows] = DFverify(S,true);
if isOkay < 1
    error('ccbr:BadInput',[filepath ' is not tab-delimited text (failed QC)']);
end
