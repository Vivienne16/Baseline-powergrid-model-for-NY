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
        T = table2timetable(T(:,["TimeStamp","GenMW"]));
        % Downsample to hourly
        T = retime(T,"hourly","mean");
        % Fill missing data with linear interpolation
        T = fillmissing(T,'linear','DataVariables',@isnumeric);
        % Format the table
        T = timetable2table(T);
        T.FuelCategory = repelem(fuelCats(n),height(T))';
        T = movevars(T,"FuelCategory","After","TimeStamp");
        fuelmixHourly = [fuelmixHourly; T];
    end
    
    fuelmixHourly = sortrows(fuelmixHourly,"TimeStamp","ascend");

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

end