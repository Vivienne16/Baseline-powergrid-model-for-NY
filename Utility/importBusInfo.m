function busInfo = importBusInfo(filename, dataLines)
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 15);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["idx", "name", "Vn", "vmax", "vmin", "v0", "a0", ...
    "xcoord", "ycoord", "area", "zone", "sumGenP0", "sumGenQ0", "sumLoadP0", "sumLoadQ0"];
opts.VariableTypes = ["double", "string", "double", "double", "double", "double", ...
    "double", "double", "double", "double", "categorical", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "name", "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["name", "zone"], "EmptyFieldRule", "auto");

% Import the data
busInfo = readtable(filename, opts);
end