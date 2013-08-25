function [ Vals, Freq, Hists ] = DFvalues(S,inclNaNEmpty)
% DFVALUES
%
%         Returns structure with field names matching input data frame,
%         but containing only unique (non-empty) values for each field
%
%       Values = DFvalues(S)
%     [ Values, Freq, Hists ] = DFvalues(S,inclNaNEmpty)
%
% parameters
% ----------------------------------------------------------------
%    "S"            - a data frame
%    "inclNaNEmpty" - boolean whether to ignore NaNs and empty strings (default=0)
%                     or to set all NaNs equal and all empty strings equal (=1)
% output
% ----------------------------------------------------------------
%    "Values"  - a structure containing field names identical to "S"
%                  but containing unique values from Data.(fieldname)
%                  in ascending order
%    "Freq"    - a structure containing field names identical to "S"
%                  containing integer frequencies exactly matched to
%                  the values stored in Values
%    "Hists"   - a structure containing field names identical to "S"
%                  containing data frames with values and frequencies
%                  identical to those stored in Values and Freq
% ----------------------------------------------------------------
% 
%   Hy Carrinski
%   Broad Institute

if nargin < 2 || isempty(inclNaNEmpty)
   inclNaNEmpty = false;
end

Vals = [];
flds = fieldnames(S);
if nargout <= 1
    for i = 1:numel(flds)
        currFld = flds{i};
        Vals.(currFld) = uniquenotmiss(S.(currFld),inclNaNEmpty);
    end
else
    Freq = [];
    for i = 1:numel(flds)
        currFld = flds{i};
        [ Vals.(currFld), indexValues, indexVector ] = ...
            uniquenotmiss(S.(currFld),inclNaNEmpty);
        numValues = numel(Vals.(currFld));
        Freq.(currFld) = nan(numValues,1);
        % NaN/empty have index of zero if ignored
        % and positive index if included, so looping
        % over values starting from 1 will work in
        % both cases
        for j = 1:numValues
            Freq.(currFld)(j) = nnz(indexVector == j);
        end
     end
     if nargout > 2
         Hists = [];
         for i = 1:numel(flds)
             currFld = flds{i};
             Hists.(currFld).value     = Vals.(currFld);
             Hists.(currFld).frequency = Freq.(currFld);
         end
     end
end


%Vals = structfun(@(x) uniquenotmiss(x,inclNaNEmpty),S,'UniformOutput',false);

