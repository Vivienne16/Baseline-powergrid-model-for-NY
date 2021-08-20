function npccTable = importNpccTable(workbookFile, sheetName, dataLines)
%IMPORTNPCC Import NPCC 140 bus, branch, generator and load data
%   Inputs:
%       workbookFile - Excel filename for the NPCC-140 network data
%       sheetName - Excel sheet name for specific data type
%       dataLines - Number of data lines to read, optional
%   Outputs:
%       npccTable - A table of specified NPCC data

%   Created by Bo Yuan, Cornell University
%   Last modified on August 20, 2021

if sheetName == "Bus"    
    % If row start and end points are not specified, define defaults
    if nargin <= 2
        dataLines = [2, 141];
    end    
    % Setup the Import Options and import the data
    opts = spreadsheetImportOptions("NumVariables", 13);   
    % Specify sheet and range
    opts.Sheet = sheetName;
    opts.DataRange = "B" + dataLines(1, 1) + ":N" + dataLines(1, 2);    
    % Specify column names and types
    opts.VariableNames = ["idx", "u", "name", "Vn", "vmax", "vmin", "v0", "a0", "xcoord", "ycoord", "area", "zone", "owner"];
    opts.VariableTypes = ["categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "double", "double", "categorical", "categorical", "categorical"];   
    % Specify variable properties
    opts = setvaropts(opts, ["idx", "u", "name", "area", "zone", "owner"], "EmptyFieldRule", "auto");   
    % Import the data
    npccTable = readtable(workbookFile, opts, "UseExcel", false);
    for idx = 2:size(dataLines, 1)
        opts.DataRange = "B" + dataLines(idx, 1) + ":N" + dataLines(idx, 2);
        tb = readtable(workbookFile, opts, "UseExcel", false);
        npccTable = [npccTable; tb]; %#ok<AGROW>
    end
 
elseif sheetName == "Line"
    % If row start and end points are not specified, define defaults
    if nargin <= 2
        dataLines = [2, 234];
    end 
    % Setup the Import Options and import the data
    opts = spreadsheetImportOptions("NumVariables", 20);  
    % Specify sheet and range
    opts.Sheet = sheetName;
    opts.DataRange = "B" + dataLines(1, 1) + ":U" + dataLines(1, 2);   
    % Specify column names and types
    opts.VariableNames = ["idx", "u", "name", "bus1", "bus2", "Sn", "fn", "Vn1", "Vn2", "r", "x", "b", "g", "b1", "g1", "b2", "g2", "trans", "tap", "phi"];
    opts.VariableTypes = ["categorical", "categorical", "string", "categorical", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];   
    % Specify variable properties
    opts = setvaropts(opts, "name", "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["idx", "u", "name", "bus1", "bus2"], "EmptyFieldRule", "auto");   
    % Import the data
    npccTable = readtable(workbookFile, opts, "UseExcel", false);   
    for idx = 2:size(dataLines, 1)
        opts.DataRange = "B" + dataLines(idx, 1) + ":U" + dataLines(idx, 2);
        tb = readtable(workbookFile, opts, "UseExcel", false);
        npccTable = [npccTable; tb]; %#ok<AGROW>
    end
    
elseif sheetName == "PV"
    % If row start and end points are not specified, define defaults
    if nargin <= 2
        dataLines = [2, 48];
    end   
    % Setup the Import Options and import the data
    opts = spreadsheetImportOptions("NumVariables", 18); 
    % Specify sheet and range
    opts.Sheet = sheetName;
    opts.DataRange = "B" + dataLines(1, 1) + ":S" + dataLines(1, 2);    
    % Specify column names and types
    opts.VariableNames = ["idx", "u", "name", "Sn", "Vn", "bus", "busr", "p0", "q0", "pmax", "pmin", "qmax", "qmin", "v0", "vmax", "vmin", "ra", "xs"];
    opts.SelectedVariableNames = ["idx", "u", "name", "Sn", "Vn", "bus", "p0", "q0", "pmax", "pmin", "qmax", "qmin", "v0", "vmax", "vmin", "ra", "xs"];
    opts.VariableTypes = ["categorical", "categorical", "categorical", "double", "double", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"]; 
    % Specify variable properties
    opts = setvaropts(opts, ["idx", "u", "name", "bus"], "EmptyFieldRule", "auto");
    % Import the data
    npccTable = readtable(workbookFile, opts, "UseExcel", false);   
    for idx = 2:size(dataLines, 1)
        opts.DataRange = "B" + dataLines(idx, 1) + ":S" + dataLines(idx, 2);
        tb = readtable(workbookFile, opts, "UseExcel", false);
        npccTable = [npccTable; tb]; %#ok<AGROW>
    end
    
elseif sheetName == "PQ"    
    % If row start and end points are not specified, define defaults
    if nargin <= 2
        dataLines = [2, 93];
    end  
    % Setup the Import Options and import the data
    opts = spreadsheetImportOptions("NumVariables", 10); 
    % Specify sheet and range
    opts.Sheet = sheetName;
    opts.DataRange = "B" + dataLines(1, 1) + ":K" + dataLines(1, 2);
    % Specify column names and types
    opts.VariableNames = ["idx", "u", "name", "bus", "Vn", "p0", "q0", "vmax", "vmin", "owner"];
    opts.VariableTypes = ["categorical", "categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "categorical"];    
    % Specify variable properties
    opts = setvaropts(opts, ["idx", "u", "name", "bus", "owner"], "EmptyFieldRule", "auto");
    % Import the data
    npccTable = readtable(workbookFile, opts, "UseExcel", false);
    for idx = 2:size(dataLines, 1)
        opts.DataRange = "B" + dataLines(idx, 1) + ":K" + dataLines(idx, 2);
        tb = readtable(workbookFile, opts, "UseExcel", false);
        npccTable = [npccTable; tb]; %#ok<AGROW>
    end
   
elseif sheetName == "Slack"  
    % If row start and end points are not specified, define defaults
    if nargin <= 2
        dataLines = [2, 2];
    end   
    % Setup the Import Options and import the data
    opts = spreadsheetImportOptions("NumVariables", 20);   
    % Specify sheet and range
    opts.Sheet = sheetName;
    opts.DataRange = "A" + dataLines(1, 1) + ":T" + dataLines(1, 2);   
    % Specify column names and types
    opts.VariableNames = ["Var1", "idx", "u", "name", "Sn", "Vn", "bus", "Var8", "p0", "q0", "pmax", "pmin", "qmax", "qmin", "v0", "vmax", "vmin", "ra", "xs", "a0"];
    opts.SelectedVariableNames = ["idx", "u", "name", "Sn", "Vn", "bus", "p0", "q0", "pmax", "pmin", "qmax", "qmin", "v0", "vmax", "vmin", "ra", "xs", "a0"];
    opts.VariableTypes = ["char", "categorical", "categorical", "categorical", "double", "double", "categorical", "char", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"]; 
    % Specify variable properties
    opts = setvaropts(opts, ["Var1", "Var8"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["Var1", "idx", "u", "Var8"], "EmptyFieldRule", "auto");    
    % Import the data
    npccTable = readtable(workbookFile, opts, "UseExcel", false);   
    for idx = 2:size(dataLines, 1)
        opts.DataRange = "A" + dataLines(idx, 1) + ":T" + dataLines(idx, 2);
        tb = readtable(workbookFile, opts, "UseExcel", false);
        npccTable = [npccTable; tb]; %#ok<AGROW>
    end
    
else
    error("Error: Undefined work sheet name!");
end

end