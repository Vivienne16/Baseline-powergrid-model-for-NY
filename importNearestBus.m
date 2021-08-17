function genAllocation = importNearestBus(filename, dataLines)
%IMPORTNEARESTBUS Import generators' nearest bus table
%   
%   Inputs:
%       filename - file name of the nearest bus csv file
%       dataLines - lines of data to read
%   Outputs:
%       genAllocation - generator allocation table

%   Created by Bo Yuan, Cornell University
%   Last modified on July 28, 2021

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 14);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["fid", "NYISOName","PTID","Zone","UnitType","FuelType",...
    "Latitude","Longitude","BusName","BusDist"];
opts.SelectedVariableNames = ["NYISOName", "PTID", "BusName", "BusDist"];
opts.VariableTypes = ["string", "categorical", "categorical", "string","string","string",...
    "string","string","double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties

% Import the data
genAllocation = readtable(filename, opts);

end