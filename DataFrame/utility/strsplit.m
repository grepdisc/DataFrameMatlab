function c = strsplit(d,s)
% STRSPLIT
%          split a string into a cell array based on a single character delimiter
%
%    c = strsplit(d,s)
%
% parameters
%----------------------------------------------------------------
%    "d"   -  a delimiter character
%    "s"   -  a string
% outputs
%----------------------------------------------------------------
%    "c"   -  a cell array of strings
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    Required by DFread

if iscell(s)
   if numel(s) > 1
      warnStr = 'Only first cell from cell array converted to string';
   else
      warnStr = 'Cell converted to string';
   end
   s = s{1};
   warning('ccbr:BadInput',warnStr);
end
assert(ischar(s),'ccbr:BadInput','Inputs to strsplit must be of type character');
assert(isscalar(d) && ischar(d), 'ccbr:BadInput', 'Delimiter must be a single character');
delimIdx       = find(double(s) == double(d));
numDelim       = numel(delimIdx);
numChar        = numel(s); 
dropShortStart = 0;
dropShortEnd   = 0;
c              = cell(1, numDelim+1);
%c              = repmat({''}, 1, numDelim+1);
if numDelim == 0
   c{1} = s;
   return
end
if min(delimIdx) == 1
   startIdx = 2;
   startStart = 2;
   c{1} = '';
   dropShortStart = 1;
else
   startIdx   = 1;
   startStart = 1;
end
if max(delimIdx) == numChar;
   endIdx = numDelim-1;
   endEnd = numChar-1;
   c{end} = '';
   dropShortEnd = 1;
else
   endIdx = numDelim;
   endEnd = numChar;
end
if numDelim < 2
   if ~dropShortStart
      c{startIdx} = s(startStart:delimIdx(startIdx)-1);
   end
   if ~dropShortEnd
      c{endIdx+1} = s(delimIdx(endIdx)+1:endEnd);
   end
else  % delimiter present multiple times in string
      c{startIdx} = s(startStart:delimIdx(startIdx)-1); 
      c{endIdx+1} = s(delimIdx(endIdx)+1:endEnd);
      for i = startIdx:endIdx-1
         c{i+1} = s(delimIdx(i)+1:delimIdx(i+1)-1);
      end
end
% clean up empty cells
c(cellfun('isempty',c)) = {''};
