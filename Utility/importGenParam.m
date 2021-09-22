function genParam = importGenParam(filename, dataLines)
%IMPORTGENPARAM Import generator parameters (thermal generator in NYISO)
%   
%   Inputs:
%       filename - name of generator parameter csv file
%       dataLines - lines of data to read
%   Outputs:
%       genParam - table of generator parameters in NY    

%   Created by Bo Yuan, Cornell University
%   Last modified on July 29, 2021

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 15);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["NYISOName", "PTID", "Zone", "UnitType", "FuelType", "Latitude", "Longitude", "maxPower",...
    "minPower", "maxRampAgc", "maxRamp10", "maxRamp30", "maxRamp60", "HeatRateLM_1", "HeatRateLM_0", "HeatRateLM_R2",...
    "HeatRateQM_2", "HeatRateQM_1", "HeatRateQM_0", "HeatRateQM_R2","useQM"];
opts.VariableTypes = ["categorical", "categorical", "categorical", "categorical", "categorical","double","double","double",...
    "double", "double", "double", "double", "double", "double", "double", "double",...
    "double","double","double","double","categorical"];
opts.SelectedVariableNames = ["NYISOName", "PTID", "Zone", "UnitType", "FuelType", "maxPower",...
    "minPower", "maxRampAgc", "maxRamp10", "maxRamp30", "HeatRateLM_1", "HeatRateLM_0",...
    "HeatRateQM_2", "HeatRateQM_1", "HeatRateQM_0","useQM"];


% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["NYISOName", "UnitType", "FuelType", "Zone"], "EmptyFieldRule", "auto");

% Import the data
genParam = readtable(filename, opts);

end