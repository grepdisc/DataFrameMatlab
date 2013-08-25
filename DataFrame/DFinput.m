function [Data, origHeader, Err, rawData] = DFinput(filename,varargin)
% DFINPUT
%        load in a tab delimited text file
%
%    Data = DFinput(filename)
%    Data = DFinput(filename,opts)
%    Data = DFinput(filename,'fileDir',file_directory, ... )
%    [Data, original_header, Err, rawData] = DFinput(filename,opts, ... )
%
% parameters
%----------------------------------------------------------------
%    "filename"     -  char array of the filename or path to the file
%    "options"      -  structure with fields to override defaults (optional)
%    "name","value" -  pairs of parameter names and values (case-insensitive)
%        "fileDir"     -  char array of the directory containing the file
%        "readLength"  -  number of lines of file to determine column formats
%        "hasColNames" -  boolean (default=true) column names in a header row
%        "isStrings"   -  boolean formats are all strings (true) or determined
%                         from file (default=false) 
%        "isNumbers"   -  boolean formats are all numbers (true) or determined
%                         from file (default=false) 
%        "delim"       -  delimiter (default='\t')   
%        "isCSV"       -  boolean (default=true) whether to NOT preserve quotes
%                         and to use ',' as delimiter
%        "maxLines"    -  maximum number of lines (default=inf) of data to read
%        "commentLines"-  number of lines of comments before column names
%        "BufSize"     -  number of bytes for longest string (default=4095)
%        "isRobust"    -  read file line by line and parse each column into a
%                          cell array (default=false).  Typically used ONLY for
%                          parsing badly formatted (e.g., instrument) files.
%                          Format string currently unsupported with this option.
%        "EmptyString" -  string to read as an empty string (default='NaN')
%        "num"         -  cell array of names of columns with numerical format
%        "str"         -  cell array of names of columns with string format
%        "keep"        -  cell array of names of columns to keep
%        "ignore"      -  cell array of names of columns to ignore
% outputs
%----------------------------------------------------------------
%    "Data"       - data frame: a 1x1 structure where each field is a
%                   column vector of type double, logical, int or cell string
%    "origHeader" - cell array of strings of the original header
%    "Err"        - status of read: (displayed if value is not "0")
%                       "0" is good
%                       "1" columns are of different lengths
%                       "2" number of rows read is not number of lines in file
%                       "3" both 1 and 2
%    "rawData"    - a 2D cell array which is the raw output from textscan
%----------------------------------------------------------------
%     Present heuristics
%     1. columns for which every row is a number or is blank --> double array
%        columns which do not meet this criterion --> cell array of strings
%
% 
%     DFinput depends on DFverify, strsplit
%     Broad Institute
%     Hy Carrinski
%
% See also DFwrite.m DFview.m
%
% Add method to consider columns with same names and blank columns
% Potential bugs in the data frame toolbox:
%     If a column name is repeated, that might cause an error
%     The output formatting may not be identical to the input
%     formatting for every number.
%
% Possible: options may also be implemented with case-insensitive,
%     abbreviation allowing, parameter-value pair system like
%     gridfit and many built-in matlab functions
%

% list of subfunctions
% lineread - read file line by line
% assign_formats - determines formats of columns of tab-delimited text file
% discover_format - find formats and return a comma separated list
% convert_and_evaluate_formats  -  evaluate formats by converting data
% read_header - Read header and position fid location at beginning of data
% make_header - generates a header for data without a header
% generate_headers - makes columns names for a given number of columns
% clean_header -  ensure that all fields of header are okay for matlab fieldnames
% check_file_length - check whether Data is well-formed (e.g., correct number of lines)
% get_file_length - measure length of file
% csv_format_replace - perform replacements in format string to handle CSV files
% parse_args - parse input arguments
% merge_options - merge options structure with default values
% check_options - test options structure based on input parameters
% construct_path - ensure that file exists and construct file path
% open_file - open file for reading and perform initial checks
% close_file - close file and check whether it has been completely read

defaultOpts = [];
defaultOpts.readLength = 400;
defaultOpts.BufSize = 2^12-1;
defaultOpts.isCSV = false;
defaultOpts.isRobust = false;
defaultOpts.hasColNames = true;
defaultOpts.isNumbers = false; % read as matrix of numbers
defaultOpts.isStrings = false; % replaces isFormat
defaultOpts.EmptyString = 'NaN';
defaultOpts.num = {};
defaultOpts.str = {};
defaultOpts.ignore = {};
defaultOpts.keep = {};
defaultOpts.delim = '\t';
defaultOpts.suppressOutput = true;
defaultOpts.commentLines = 0;
defaultOpts.linesToIgnoreBelowHeader = 0;
defaultOpts.maxLines = inf; % maximum number of lines of data to read from file
                            % required N > 0 by textscan docs, but 0 or -1 work 
defaultOpts.fileDir = [];
%defaultOpts.caseSensitiveColumns = true; % only enabled
%defaultOpts.caseSensitivePath = true; % only enabled
 
% QC inputs
assert(nargin>=1 && not(isempty(filename)), ...
    'ccbr:BadInput','DFinput requires at least a filename');
opts = parse_args(varargin,defaultOpts);
% check the parameters for acceptability
opts = check_options(opts,filename);
[fid, filelength] = open_file(filename,opts);
% QC is complete

% Read in a tab delimited text file with column names
[formats, headerIdx] = assign_formats(fid,opts);
[header, origHeader] = read_header(fid,opts);
header               = header(headerIdx);  % remove ignored fields
origHeader           = origHeader(headerIdx);

% read the file
if not(opts.isRobust)
    if isinf(opts.maxLines)
        maxLines = -1;
    else
        maxLines = opts.maxLines;
    end
    rawData = textscan(fid, formats, maxLines,'delimiter', opts.delim);
else
    rawData = lineread(fid, formats, numel(header), opts);
end
close_file(fid);

Data = cell2struct(rawData,header,2); % operates along 2nd dimension: columns
if not(opts.suppressOutput)
    opts
end
Err  = check_file_length(filelength,Data,opts);
if Err > 1
    Err
end
end                % end of main function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rawData = lineread(fid, formats, numFields, opts)
% LINEREAD
%      rawData = lineread(fid, formats, numFields, opts)
%      currently ignores "formats"
    if isinf(opts.maxLines)
        maxLines = -1;
    else
        maxLines = opts.maxLines;
    end
    robustDelim = sprintf(opts.delim); 
    linedata = textscan(fid, '%s', maxLines, 'delimiter', '\n', ...
        'whitespace', '');
    rawArray = repmat({''},numel(linedata{1}),numFields);
    for i = 1:numel(linedata{1})
        if not(isempty(linedata{1}{i}))
            oneLine = strsplit(robustDelim, linedata{1}{i}); % good solution
            % strsplit respects each and every delimiter (c.f., textscan)
            if not(isempty(oneLine))
               % truncate lines possessing more elements than file's columns
               oneLine = oneLine(1:min(numel(oneLine),numFields)); 
               rawArray(i,1:numel(oneLine)) = oneLine;
            end
        end
    end
    clear linedata
    for j = numFields:-1:1
        rawData{1,j}  = rawArray(:,j);
        rawArray(:,j) = [];   % is this line helpful?
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [formats, headerIdx] = assign_formats(fid,opts)
% ASSIGN_FORMATS  determines formats of columns of tab-delimited text file
%    and returns a format string
%     
%    [formats, headerIdx] = assign_formats(fid,opts)
%    
%    Format choices are based on priority given below:
%    1. opts = struct('str',{'A','B'},'num',{'Col1'},'ignore',{},'keep',{});
%    2. Search readLength lines
    
    frewind(fid);
    header = read_header(fid,opts);
    headerIdx = true(size(header));

    cellFmts = cell(numel(header),1);
    unknownFormats = cell(numel(header),1);
    if opts.isNumbers
        cellFmts(:) = {'%f'};
    elseif opts.isStrings
        cellFmts(:) = {'%s'};
    else
        cellFmts(ismember(header,opts.num))   = {'%f'};
        cellFmts(ismember(header,opts.str))   = {'%s'};
        unknownFormats(strcmp('%f',cellFmts)) = {'%*f'};
        unknownFormats(strcmp('%s',cellFmts)) = {'%*s'};
        unknownIdx = cellfun('isempty',cellFmts);
        % find the unknown formats and return the complete formats
        % run only if formats are not already known
        if any(unknownIdx)
            if opts.isRobust
                cellFmts(unknownIdx) = {'%s'}; % robust format finding unsupported
            else
                unknownFormats(unknownIdx) = {'%s'};
                [cellFmts{unknownIdx}] = discover_format(unknownFormats, ...
                    fid, opts, header(unknownIdx));
            end
        end
    end
    frewind(fid);
        
    % keeping columns has priority over removing columns
    % remove columns to be ignored: may be complicated by headerrepl()
    if isempty(opts.keep) || all(strcmp('',opts.keep))
        ignoreIdx = ismember(header,opts.ignore);
    else
        ignoreIdx = not(ismember(header,opts.keep));
    end

    if any(ignoreIdx)
        cellFmts(ignoreIdx & strcmp('%f',cellFmts)) = {'%*f'};
        cellFmts(ignoreIdx & strcmp('%s',cellFmts)) = {'%*s'};
        headerIdx(ignoreIdx) = false;   % ensure header matches kept columns
    end
    formats = [cellFmts{:}];
    if opts.isCSV
        formats = csv_format_replace(formats);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [varargout] = discover_format(unknownFormats,fid,opts,fields)
    % find formats and return a comma separated list
    % fields is likely "header"
    % assumes file is at correct start place (just below header row)

    unknownFormats = [unknownFormats{:}];
    if opts.isCSV
        unknownFormats = csv_format_replace(unknownFormats);
        sampleData = textscan(fid,unknownFormats,opts.readLength,...
            'delimiter',options.delim,'headerlines',0,'BufSize',opts.BufSize);
    else
        sampleData = textscan(fid,unknownFormats,opts.readLength,...
            'delimiter','\t','headerlines',0,'BufSize',opts.BufSize);
    end
    Data = convert_and_evaluate_formats(sampleData,fields);
    cellFmt = repmat({'%s'},1,numel(fields));
    for i = 1:numel(fields)
        switch class(Data.(fields{i}))
            case 'double'
                cellFmt{i} = '%f';
            case {'cell','char'}
                % cellFmt{i} = '%s';
            otherwise
                error('ccbr:UnsupportedFormat','datatype not supported')
        end
    end
    varargout = cellFmt; % Returns a comma separated list
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Data = convert_and_evaluate_formats(rawData,fields)
% CONVERT_AND_EVALUATE_FORMATS
%     Cycle through cells containing column vectors of cells or doubles
%     and convert each column vector to vector of type double or cellstring.
%
%     If all NaNs in a vector match the string lower(NaN) in the original
%     field or are empty, then the field is considered to be numeric.
%
%     If all elements in a vector are NaN, the string format is chosen
%     to be more conservative when reading the entire file.
%
%     Hy Carrinski
%     Created 28 June 2006

    Data = struct(fields{1},[]);
    for i = 1:numel(fields)
        asNum      = str2double(rawData{i});     % conversion
        nanIdxConv = isnan(asNum);               % converted
        nanIdxReal = strcmpi('nan',rawData{i});  % explicit
        % numeric all nans are either empty or written as nan
        if isequal(nanIdxConv, nanIdxReal) || ...
            all(strcmp('',rawData{i}(nanIdxConv)))
            Data.(fields{i})      = asNum;       % double array
        % Postpone conversion until DataFrame supports char array
        elseif false && iscellstr(rawData{i}) && ...
            isscalar(unique(cellfun(@numel,rawData{i})))
            Data.(Data.fields{i}) = char(rawData{i});
        else
            Data.(fields{i})      = rawData{i};  % remains cell array of strings
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [header, origHeader] = read_header(fid,opts)
    % Read header. Position fid location at beginning of data.
    frewind(fid);
    headerFmt = '%s';
    if opts.isCSV
        headerFmt = csv_format_replace(headerFmt);
    end
    % discard comment lines before line of headers
    for i = 1:(opts.commentLines - 1)  % WHY MINUS 1?
        header = fgetl(fid);
    end
    % read or generate header
    if opts.hasColNames
        header = strread(char(fgetl(fid)), headerFmt, 'delimiter',opts.delim);
    else
        header = make_header(fid,opts);
    end
    origHeader = header;

    % massage header so each element is a legitimate MATLAB field name
    header = clean_header(header);

    % for now, require unique column names    
    assert(isequal(numel(header), numel(unique(header))), 'ccbr:BadInput', ...
        'DFinput requires that each input column possess a unique column name')

    % position fid location at beginning of data
    for i = 1:(opts.linesToIgnoreBelowHeader)
        fgetl(fid);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [header, origHeader]  = make_header(fid,opts)
%   [header, origHeader]= make_header(fid,opts)
%       Generates a header of equal length column names for data without a header.
%       For names longer than 63 characters, retains a copy of original names

    frewind(fid);
    robustDelim = sprintf(opts.delim); 
    colsPerLine = zeros(opts.readLength,1);
    linedata    = textscan(fid, '%s', opts.readLength, 'delimiter', '\n', ...
                'whitespace', '','headerlines',opts.commentLines);
    for i = 1:numel(linedata{1})
        currLine = linedata{1}{i};
        if not(isempty(currLine))
            colsPerLine(i) = numel(strsplit(robustDelim, currLine));
        end
    end
    numCols  = max(colsPerLine);
    header   = generate_headers(numCols);
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function header = generate_headers(numCols)
%   header = generate_headers(numCols)
%   makes columns names for a given number of columns
    part1               = repmat('Column', numCols, 1);
    part2               = num2str(transpose((1:numCols)));
    part2(part2 == ' ') = '0'; % replace spaces with zeros
    header              = mat2cell([part1 part2],ones(numCols,1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function header = clean_header(header)
% CLEAN_HEADER
%    ensures that all fields of header are okay for matlab fieldnames
%    first performs simple replacement, then calls genvarname
%    could uniquify headers here as well
    hdrLength = cellfun(@numel,header);
    if any(hdrLength > 63 | hdrLength == 0)
        header = generate_headers(numel(header));
        warning('ccbr:BadInput',['Column headers empty or more than 63 ' ... 
            'characters, original names present at second output of DFinput']);
        return
    end
    header = regexprep(header,'/' ,'JPJ');
    header = regexprep(header,'#' ,'KPK');
    header = regexprep(header,':' ,'NPN');
    header = regexprep(header,'\.','QPQ');
    header = regexprep(header,')' ,'VPV');
    header = regexprep(header,'(' ,'XPX');
    header = regexprep(header,'\"','YPY');
    header = regexprep(header,'\ ','ZPZ');
    hdrLength = cellfun(@numel,header);
    if any(hdrLength>63)
        header = generate_headers(numel(header));
        warning('ccbr:BadInput',['Column headers modified to more than 63 ' ...
            'characters, please see second output of DFinput']);
        return
    else
        header = genvarname(header);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Err = check_file_length(filelength,Data,opts)
% CHECK_FILE_LENGTH
% Check if Data is well formed and contains the correct number of lines
    [isOkay, numRows] = DFverify(Data,true);
    deltaLines = opts.commentLines + opts.hasColNames + ...
        opts.linesToIgnoreBelowHeader;
    Err = (isOkay < 1) + 2*not(isequal(filelength,numRows + deltaLines)); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function filelength = get_file_length(fid,opts)
% GET_FILE_LENGTH
    frewind(fid);
    if isinf(opts.maxLines)
        maxLines = -1;
    else
        maxLines = opts.maxLines + opts.commentLines + ...
            opts.linesToIgnoreBelowHeader;
    end
    try
        frewind(fid);
        linesFound = textscan(fid, '%s', maxLines, 'delimiter', '\n','BufSize',opts.BufSize);
        filelength = numel(linesFound{1});
    catch
        error('ccbr:BufferSize','insufficient buffer size, try increasing buffer size');
    end
    isFinished = feof(fid);
    assert(isFinished == true,'ccbr:PoorlyFormattedFile','file length could not be determined');
    frewind(fid);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function formats = csv_format_replace(formats)
    % perform replacements in format string to handle CSV files
    formats = strrep(formats,'%s','%q');
    formats = strrep(formats,'%*s','%*q');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function opts = parse_args(args,defaultOpts)
% parse input arguments
% two potential cases
% 1. name-value pairs of strings (these take precedence)
% 2. structure containing options (as 2nd input)
% inspired by parse_pv_pairs within gridfit by John D'Errico 
    if isempty(args)
        opts = defaultOpts;
        return
    end
    if isstruct(args{1})
        opts = args{1};
        args(1) = [];
    else
        opts = [];
    end
    opts = merge_options(opts,defaultOpts);
    npv = numel(args);
    n = npv/2;
    assert(n==floor(n),'unpaired name/value found');
    flds = fieldnames(opts);
    for i = 1:n
        name = args{2*i-1};
        value = args{2*i};
        ind = find(strncmpi(name,flds,numel(name)));
        assert(isscalar(ind),'ccbr:BadInput', [name ' ambiguous or not supported']);
        currFld = flds{ind};
        opts.(currFld) = value;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function opts = merge_options(opts,defaultOpts)
% merge options structure with default values
    assert(isstruct(defaultOpts),'ccbr:BadInput','default options must be a structure');
    if isempty(opts)
        opts = defaultOpts;
    else
        assert(isstruct(opts),'ccbr:BadInput','options must be a structure or an empty array');
        flds = fieldnames(defaultOpts);
        mergeIdx = find(not(isfield(opts,flds(defaultOpts))));
        for i = 1:numel(mergeIdx)
            currFld = flds{mergeIdx(i)};
            opts.(currFld) = defaultOpts.(currFld);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function opts = check_options(opts,filename)
% check options
    if not(isempty(opts.fileDir)) && not(any(strcmp(opts.fileDir(end),{'/','\'})))
        opts.fileDir = [fileDir filesep];
    end
    if opts.isCSV
        % current coerce this. could enforce instead.
        opts.delim = ',';
    end

    % could ensure each of cell arrays of strings are unique and non-overlapping,
    % or warn about behavior
    % could handle reading files with redundant columns, and warn

    test1 = @(x) isscalar(x);
    test2 = @(x) isnumeric(x) && isequal(x,floor(x)) && x >= 0;
    test3 = @(x) islogical(x) || nnz(x) == nnz(x==1);
    test4 = @(x) ischar(x) || isempty(x);
    test5 = @(x) iscellstr(x);

    try
        assert(test1(opts.readLength) && test2(opts.readLength));
        assert(test1(opts.BufSize) && test2(opts.BufSize) && opts.BufSize < 1e6);
        assert(test1(opts.isRobust) && test3(opts.isRobust));
        assert(test1(opts.hasColNames) && test3(opts.hasColNames));
        assert(test1(opts.isNumbers) && test3(opts.isNumbers));
        assert(test1(opts.isStrings) && test3(opts.isStrings));
        assert(test1(opts.suppressOutput) && test3(opts.suppressOutput));
        assert(test4(opts.EmptyString));  % possibly scalar
        assert(test5(opts.num));
        assert(test5(opts.str));
        assert(test5(opts.keep));
        assert(test5(opts.ignore));
        assert(test4(opts.delim));
        assert(test1(opts.commentLines) && test2(opts.commentLines));
        assert(test1(opts.linesToIgnoreBelowHeader) && ...
            test2(opts.linesToIgnoreBelowHeader));
        assert(test1(opts.maxLines) && test2(opts.maxLines));
        assert(test4(opts.fileDir));
        %assert(test1(opts.caseSensitivePath) && test3(opts.caseSensitivePath));
        % could prepare an error log as a DF
    catch
        opts
        error('ccbr:BadOptions','Please correct non-default parameters');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function filepath = construct_path(filename,opts)
% ensure that file exists and construct path
% support wildcards in filename
    filepath = [opts.fileDir filename];
    if not(isempty(strfind(filepath,'*')))
        filestruct = dir(filepath);
            assert(isscalar(filestruct), 'ccbr:BadInput', ...
            ['path does not match a unique file: ' filepath]); 
        fileDir = fileparts(filepath);
        filepath = [fileDir, filesep, filestruct.name];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fid, filelength] = open_file(filename,opts)
% open file for reading and perform initial checks
    filepath = construct_path(filename,opts);
    fid = fopen(filepath,'rt');
    assert(fid>=0, 'ccbr:BadInput', ['File: ' filepath ' could not be opened']);
    filelength = get_file_length(fid,opts);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = close_file(fid)
% close file and check whether it has been completely read
    isFinished = feof(fid);
    fclose(fid);
    assert(isFinished == true, ...
        'ccbr:PoorlyFormattedFile', 'file could not be fully read');
end
