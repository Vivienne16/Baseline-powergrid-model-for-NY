function msg = writeFuelmix(year)
%WRITEFUELMIX write NYISO hourly fuel mix data in 2019

%   Created by Bo Yuan, Cornell University
%   Last modified on August 17, 2021

% Input handling
if nargin < 1 && isempty(year)
    year = 2019; % Default data in year 2019
end

try
    % Read fuel mix data
    fuelmixFileDir = fullfile('..\Prep','fuelmix');
    fuelmixFileName = string(year)+"*";
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
        T = retime(T,"hourly","mean");
        T = timetable2table(T);
        T.FuelCategory = repelem(fuelCats(n),height(T))';
        T = movevars(T,"FuelCategory","After","TimeStamp");
        fuelmixHourly = [fuelmixHourly; T];
    end
    
    fuelmixHourly = sortrows(fuelmixHourly,"TimeStamp","ascend");
    
    % Write hourly fuel mix data
    outfilename = fullfile('..\Data','fuelmixHourly.csv');
    writetable(fuelmixHourly,outfilename);
    msg = "Success!";
catch ME
    msg = ME.message;
end
end

function fuelMix = importFuelmix(filename, dataLines)
%IMPORTFUELMIX Import NYISO real-time fuel mix data

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 4);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "Var2", "FuelCategory", "GenMW"];
opts.SelectedVariableNames = ["TimeStamp", "FuelCategory", "GenMW"];
opts.VariableTypes = ["datetime", "string", "categorical", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Var2", "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var2", "FuelCategory"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");

% Import the data
fuelMix = readtable(filename, opts);

end