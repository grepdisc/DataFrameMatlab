function S = DFcat(S,varargin)
% DFCAT
%     S = DFcat(S,Sadd1,Sadd2,Sadd3,...,Saddk)
%
%     Concatenates rows of one data frame onto another data frame
%
% parameters
%----------------------------------------------------------------
%    "S"       -  DF, possibly empty (e.g., "struct([])"), to which to append rows
%    "Sadd"    -  DF containing rows to append
% outputs
%----------------------------------------------------------------
%    "S"       -  DF including all rows from inputs
%----------------------------------------------------------------
%    Note: syntax S = DFcat(S,Sadd,isCheck) is not longer supported
%          since the integrity of "Sadd" is always checked
% 
% Concatenates rows from DF Sadd onto DF S
% Hy Carrinski
% Broad Institute

assert(isstruct(S),'ccbr:BadInput','bad inputs for DFcat');

if nargin < 2
    warning('ccbr:BadInput','DFcat expects 2 inputs, returning original data frame');
    return
end

numToCat = numel(varargin);
isAllStruct  = cellfun(@isstruct,varargin);
if numToCat > 1 && not(isAllStruct(2))
    isAllStruct(2) = [];
    varargin{2}    = [];
    numToCat       = numToCat - 1;
end

assert(all(isAllStruct),'ccbr:BadInput','bad inputs for DFcat');

if (numToCat == 1)
   S = DFsinglecat(S,varargin{1});
else
   S = DFmultcat(S,varargin);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = DFsinglecat(S,Sadd)
% Concatenates rows from DF Sadd onto DF S

    if isempty(Sadd)
        return
    elseif isempty(S)
        S = Sadd;
        return
    end

    fields1 = fieldnames(S);
    fields2 = fieldnames(Sadd);

    assert(isequal(numel(fields1), numel(fields2)) && ...
       all(ismember(fields1,fields2)),'ccbr:BadInput', ...
       'Fields between S and Sadd must match');

    % Ensure that each column is 1D and has an equal number of rows
    isOkay = DFverify(Sadd,true);
    assert(isOkay > 0, 'ccbr:NotDF','Each field must be an equal length column vector');
    % passed QC

    % Perform concatenation
    for i = 1:numel(fields1)
       currFld = fields1{i};
       S.(currFld) = cat(1, S.(currFld),Sadd.(currFld));
    end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = DFmultcat(S,CellSadd)
% Concatenates rows from cell array of DF CellSadd onto DF S

    % Verify inputs and identify empty data frames (zero rows)
    [ isOkayS numRowS ] = DFverify(S,true);
    for i = numel(CellSadd):-1:1
        [isOkaySadd(i), numRowSadd(i)] = DFverify(CellSadd{i},true);
    end
    % Ensure that each column is 1D and has an equal number of rows
    assert(isOkayS > 0 && all(isOkaySadd > 0), ...
        'ccbr:NotDF','Each field must be an equal length column vector');
    % passed initial QC

    % handle empty CellSadd elements
    if any(numRowSadd == 0)
        if all(numRowSadd == 0)
           return;
        end
        CellSadd(  numRowSadd == 0) = [];
        numRowSadd(numRowSadd == 0) = [];
    end
    
    % handle empty S
    if (numRowS == 0)
       S             = CellSadd{1};
       numRowS       = numRowSadd(1);
       CellSadd(1)   = [];
       numRowSadd(1) = [];
    end

    % All empty data frames have been removed
    numToCat = numel(CellSadd);
    cols = fieldnames(S);
    for i = numToCat:-1:1
        appendCols = fieldnames(CellSadd{i});
        assert(isequal(numel(cols), numel(appendCols)) && ...
           all(ismember(cols,appendCols)),'ccbr:BadInput', ...
            'Concatenation only among data frames with matching fields');
    end
    % passed final QC

    % Perform concatenation
    for i = 1:numel(cols)
        holder      = cell(numToCat,1);
        currFld     = cols{i};
        for j = 1:numToCat
            holder{j} = CellSadd{j}.(currFld);
        end
        S.(currFld) = cat(1,S.(currFld),holder{:});
    end    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
