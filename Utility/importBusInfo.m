function busInfo = importBusInfo(filename, dataLines)
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 14);
% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";
% Specify column names and types
opts.VariableNames = ["Var1", "idx", "u", "name", "Vn", "vmax", "vmin", "v0", "a0", "xcoord", "ycoord", "area", "zone", "Var14"];
opts.SelectedVariableNames = ["idx", "u", "name", "Vn", "vmax", "vmin", "v0", "a0", "xcoord", "ycoord", "area", "zone"];
opts.VariableTypes = ["string", "double", "double", "string", "double", "double", "double", "double", "double", "double", "double", "double", "categorical", "string"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, ["Var1", "name", "Var14"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "name", "zone", "Var14"], "EmptyFieldRule", "auto");
% Import the data
busInfo = readtable(filename, opts);
end