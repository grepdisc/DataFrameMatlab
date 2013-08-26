## DataFrameMatlab overview

### Objective

MATLAB functions to process delimited text files. Using structures similar to
R's Data Frames, MATLAB can manipulate tabular heterogeneous data for
statistical analaysis.

### Contents

In this context, a data frame is a structure of arrays where each array is
column-oriented, one dimensional and has the same number of elements as every
other column.

#### Essential File I/O
   * DFread    - load a tab delimited text file into a data frame
   * DFwrite   - write a tab delimited text file from a data frame
   * DFkeeprow - make subset of a data frame given row indices

#### Essential data manipulation
   * DFindex   - generate an index for a data frame for any number of fields
   * DFcat     - concatenate rows from structure of array onto a data frame
   * DFjoin    - perform a join between two files (or structures of arrays)
   * DFkeepcol - keep only listed fields from a data frame
   * DFfrommat - make a data frame from a matrix and an array of strings
   * DFsort    - sort a data frame based on any number of fields
   * DFtomat   - make a matrix and an array of strings from a data frame
   * DFunmerge - unmerge rows from a structure
   * DFverify  - test that all arrays in data frame are of equal size

#### Essential utilities (dependencies)
   * cell2delim    - concatenate a cell array of strings into a delimited char array
   * conv2str      - converts any (non-structure) input to a single string,
   * makevert      - make any dimensional matrix or comma separated list into a column vector
   * strsplit      - split a string into a cell array based on a single character delimiter
   * uniquenotmiss - find the unique values of a (cell) array (ignore NaN and '')

#### Useful functions
   * DFfilter      - filter rows from a data frame
   * DFgetgood     - perform quality control on a data frame or a file path to a tab-text file
   * DFisnum       - determine whether all fields in a data frame have type logical or numeric
   * DFpivot       - pivot a data frame based on values of a field
   * DFrenamecol   - rename fields from a data frame
   * DFrmcol       - remove listed fields from a data frame
   * DFvalues      - structure with fields of unique values from input data frame
   * DFview        - display char matrix representing contents of data frame

#### Other utilities
   * rowcol2well   - convert arrays of rows and columns to array of wells
   * well2rowcol   - convert cell array of wells to cell array of Rows and vector of Cols
   * getfirst      - return first element of an array or null
   * getlast       - return last element of an array or null
   * isint         - true for arrays containing only integer values, regardless of type
   * notindex      - return list of indices not contained in a list of indices
   * num2colidx    - return column vector of numbers between one and a given number
   * well2id       - convert cell array of wells to numerical id's in column-major order

#### Optional functions  
   * DFtostruct    - convert between a data frame and an array of structures

