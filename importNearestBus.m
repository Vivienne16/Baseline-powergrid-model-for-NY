function genAllocation = importNearestBus(filename, dataLines)
%Import generator allocation
%
%  Example:
%  nearestnypvbustogen = importNearestBus("D:\EERL\NY-Simple-Net\NY-Simple-Net-main\Data\nearest_bus_0601.csv", [2, Inf]);


% Author: Bo Yuan
% Last modified: July 28, 2021

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
    "string","string","categorical", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties

% Import the data
genAllocation = readtable(filename, opts);

end