function writeFuelmix(testyear)
%WRITEFUELMIX write NYISO hourly fuel mix data in 2019

%   Created by Bo Yuan, Cornell University
%   Last modified on August 17, 2021

%% Input handling
if isempty(testyear)
    testyear = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','fuelmixHourly_'+string(testyear)+'.csv');
matfilename = fullfile('Data','fuelmixHourly_'+string(testyear)+'.mat');

if ~isfile(outfilename) || ~isfile(matfilename) % File doesn't exist
    %% Download fuel mix data
    downloadData(testyear,'fuelmix');
    
    %% Testing
    filename = "D:\EERL\NY-Simple-Net\Baseline-powergrid-model-for-NY\Prep\2016\fuelmix\20161106rtfuelmix.csv";
    fuelMix = importFuelmix(filename);
    fuelMix.DT(fuelMix.TimeZone == "EST") = hours(5);
    fuelMix.DT(fuelMix.TimeZone == "EDT") = hours(4);
    fuelMix.TConv = fuelMix.TimeStamp + fuelMix.DT;
    
    t = fuelMix.TimeStamp;
    t.TimeZone = 'America/New_York';
    t_utc = t;
    t_utc.TimeZone = 'Z';
    fuelMix.UTC = t_utc;
    

    %% Read fuel mix data
    fuelmixFileDir = fullfile('Prep',string(testyear),'fuelmix');
    fuelmixFileName = string(testyear)+"*";
    fuelmixDataStore = fileDatastore(fullfile(fuelmixFileDir,fuelmixFileName),...
        "ReadFcn",@importFuelmix,"UniformRead",true,"FileExtensions",'.csv');
    fuelmixAll = readall(fuelmixDataStore);
    clear fuelMixDataStore; 

    %% Format fuel mix data
    fuelCats = unique(fuelmixAll.FuelCategory);
    numFuel = length(fuelCats);
    fuelmixHourly = table();

    for n=1:numFuel
        T = fuelmixAll(fuelmixAll.FuelCategory == fuelCats(n), :);
        T = table2timetable(T(:,["TimeStampUTC","GenMW"]));
        T = retime(T,"hourly","mean");
        T = timetable2table(T);
        T.FuelCategory = repelem(fuelCats(n),height(T))';
        T = movevars(T,"FuelCategory","After","TimeStampUTC");
        fuelmixHourly = [fuelmixHourly; T];
    end
    
    % Convert timestamp UTC back to local time in New York
    fuelmixHourly = sortrows(fuelmixHourly,"TimeStampUTC","ascend");
    fuelmixHourly.TimeStampUTC.TimeZone = 'Z';
    fuelmixHourly.TimeStamp = fuelmixHourly.TimeStampUTC;
    fuelmixHourly.TimeStamp.TimeZone = 'America/New_York';
    fuelmixHourly.TimeZone(isdst(fuelmixHourly.TimeStamp)) = "EDT";
    fuelmixHourly.TimeZone(~isdst(fuelmixHourly.TimeStamp)) = "EST";
    fuelmixHourly.TimeZone = categorical(fuelmixHourly.TimeZone);

    %% Write hourly fuel mix data
    writetable(fuelmixHourly,outfilename);    
    save(matfilename,"fuelmixHourly");
    fprintf("Finished writing fuel mix data in %s and %s!\n",outfilename,matfilename);
    
else
    fprintf("Fuel mix data already exists in %s and %s!\n",outfilename,matfilename);  
    
end

end

function fuelMix = importFuelmix(filename, dataLines)
%IMPORTFUELMIX Import NYISO real-time fuel mix data

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

% Turn datetime reading warning to an error and use try-catch below
warning('error', 'MATLAB:readtable:AllNaTVariable');

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 4);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "TimeZone", "FuelCategory", "GenMW"];
opts.VariableTypes = ["datetime", "categorical", "categorical", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["TimeZone", "FuelCategory"], "EmptyFieldRule", "auto");

% Import the data
try
    opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");
    fuelMix = readtable(filename, opts);
catch
    opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm");
    fuelMix = readtable(filename, opts);
end

% Add UTC time
fuelMix.DT(fuelMix.TimeZone == "EST") = hours(5);
fuelMix.DT(fuelMix.TimeZone == "EDT") = hours(4);
fuelMix.TimeStampUTC = fuelMix.TimeStamp + fuelMix.DT;

end