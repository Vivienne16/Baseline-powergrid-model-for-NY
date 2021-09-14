function RenewableGen = importRenewableGen(filename, dataLines)
%IMPORTFILE Import renewable generation allocation data
%   Inputs:
%       filename - csv file that contains renewable generation data
%       dataLines - number of data lines to import
%   Outputs:
%       RenewableGen - renweable generation data

%   Created by Bo Yuan, Cornell University
%   Last modified on August 17, 2021

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 14, "Encoding", "UTF-8");

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["BusID", "Voltage", "Zone", "PgOriginal", "PgThermalCap",...
    "PgThermal", "PgNuclearCap", "PgNuclear", "PgHydroCap", "PgHydro", "PgWindCap",...
    "OtherRenewable", "P0", "Load"];
opts.VariableTypes = ["double", "double", "categorical", "double", "double",...
    "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Zone", "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["PgThermal", "PgNuclear"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["PgThermal", "PgNuclear"], "ThousandsSeparator", ",");

% Import the data
RenewableGen = readtable(filename, opts);
RenewableGen = fillmissing(RenewableGen,'constant',0,'DataVariables',@isnumeric);
end