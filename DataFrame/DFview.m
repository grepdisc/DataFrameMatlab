function outCharMat = DFview(S,idx,colWidth,options)
%
%     outCharMat = DFview(S)
%     outCharMat = DFview(S,idx)
%     outCharMat = DFview(S,idx,colWidth,options)
%
% parameters
% ----------------------------------------------------------------
%    "S"            - a 1x1 structure of arrays of any type
%                     e.g., double, int, char or cell array of strings 
%                     e.g., S.fieldname(index)
%    "idx"          - a logical or positive integer index into S
%    "colWidth"     - a positive integer equal to the maximum width per column
%    "options"      - structure of options for formatting same as DFwrite
%                     supporting additional fields
%                     "isPrintIndex" - a logical determining if an index column is printed
%                     "maxDig"       - a positive integer giving a number
%                                      beyond which decimals will be truncated
% output
% ----------------------------------------------------------------
%    "outCharMat"   - a matrix of type character containing data from S
% ----------------------------------------------------------------
%
%     Created 14 December 2008
%     Hy Carrinski
%     Broad Institute
%
%    Note: currently grows output matrix as loops over fields, since
%    widths of numerical fields are difficult to estimate. Could adopt
%    a preallocation approach similar to DFwrite if desired

% Prepare inputs 
fields = fieldnames(S);
if nargin < 2 || isempty(idx)
    idx = 1:numel(S.(fields{1}));
end
if nargin < 3 || isempty(colWidth)
    colWidth = inf;
end
if nargin < 4 || isempty(options)
   options = struct([]);
elseif not(isstruct(options))
   error('ccbr:BadInput',['"options" is required to be ' ...
         'a structure with a format string per field']);
end
if isfield(options,'isPrintIndex')
    isPrintIndex = options.isPrintIndex;
else
    isPrintIndex = false;
end
if isfield(options,'maxDig')
    maxDig = options.maxDig;
else
    maxDig = 6; % number of digits before and after decimal
end
if islogical(idx)
    idx = find(idx);
end
numRows = numel(idx);

% Add index
if isPrintIndex
    unpaddedStrings = num2str(idx(:));
    currWidth       = max(size(unpaddedStrings,2),numel('Index'));
    currWidth       = min(currWidth,colWidth) + 1;
    outCharMat      = [addpad('Index',currWidth); ...
                       addpad(unpaddedStrings,currWidth,false)];
else
    outCharMat      = [];
end
% Generate output character matrix
S = DFkeeprow(S,idx);
for i = 1:numel(fields)
    currFld = fields{i};
    currVec = S.(currFld);
    if iscellstr(currVec)
        initWidth     = max(cellfun(@numel,currVec));
        currWidth     = getwidth(initWidth,colWidth,numel(currFld));
        paddedStrings = cellfun(@(x) addpad(x,currWidth,true), ...
                         currVec,'UniformOutput',false);
        charMat       = [ addpad(currFld,currWidth); ...
                          cell2mat(paddedStrings) ];
   elseif isnumeric(currVec) || islogical(currVec)
        if isfield(options,currFld)
            numFormat = options.(currFld);
        elseif isfield(options,'defaultFmt')
            numFormat = options.defaultFmt;
        else
            numFormat = getformat(abs(currVec),maxDig);
        end
        unpaddedStrings = num2str(currVec,numFormat);
        initWidth       = size(unpaddedStrings,2);
        currWidth       = getwidth(initWidth,colWidth,numel(currFld));
        charMat         = [ addpad(currFld,currWidth); ...
                            addpad(unpaddedStrings,currWidth,false) ];
   else
       error('ccbr:BadInput',...
             [ class(currVec) ' is not yet supported' ]);
   end
   outCharMat = [ outCharMat, charMat];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = addpad(x, num, isPadRight)
% ADDPAD
%     addpad - add whitespace padding to end of string
%
%     x = addpad(x, num, isPadRight)
%
%     isPadRight is logical, default=true

    if nargin < 3 || isempty(isPadRight)
        isPadRight = true;
    end
    space = ' ';
    if isempty(x)
        x = repmat(space,1,num);
    elseif size(x,2) >= num
        x = [ x(:,1:(num-1)) repmat(space,size(x,1),1) ];
    elseif isPadRight
        x = [ x repmat(space,size(x,1),num-size(x,2)) ];
    else
        x = [ repmat(space,size(x,1),num-size(x,2)-1), ...
              x, repmat(space,size(x,1),1) ];
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function numFormat = getformat(vals, maxDig)
% GETFORMAT
%     getformat - generate sprintf-style format string for numbers
%
%     numFormat = getformat(vals, maxDig)

    if islogical(vals)
        numFormat = '%0.0f';
        return;
    end
    logVals   = log10(vals);
    maxDigits = min(max(ceil(abs(max(logVals))),1),maxDig);
    if all(vals(~isnan(vals)) == round(vals(~isnan(vals)))) 
        minDigits = 0;
    else
        minDigits = 1 + min(max(ceil(abs(min(logVals))),0),maxDig-1);
    end
    numFormat = [ '%' sprintf('%0.0f.%0.0f',maxDigits,minDigits) 'f'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function width = getwidth(initWidth, colWidth, headWidth)
% GETWIDTH
%     getwidth - calculate output column width
%
%     width = getwidth(initWidth, colWidth, headWidth)

    width = min(max(initWidth,headWidth), colWidth) + 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%
%UNIT TEST DESCRIPTION
% Required
% 1. Show a DF
% 2. Show fields of types: double, int, cellstr, char (?)
% 3. Have at least one space between field names and between field values
% Optional
% 1. Add index
% 2. Show specific rows based on logical or integer index
% 3. Trim field's length
% 4. Define number of decimal places
