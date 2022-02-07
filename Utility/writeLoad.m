function writeLoad(testyear)
%WRITEFUELMIX write NYISO hourly real-time zonal load data

%   Created by Bo Yuan, Cornell University
%   Last modified on September 13, 2021

%% Input handling
if isempty(testyear)
    testyear = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','loadHourly_'+string(testyear)+'.csv');
matfilename = fullfile('Data','loadHourly_'+string(testyear)+'.mat');

if ~isfile(outfilename) || ~isfile(matfilename)% File doesn't exist
    %% Down load price data
    downloadData(testyear,'rtload');
    
    %% Read load data
    loadFileDir = fullfile('Prep',string(testyear),'rtload');
    loadFileName = string(testyear)+"*";
    loadDataStore = fileDatastore(fullfile(loadFileDir,loadFileName),...
        "ReadFcn",@importLoad,"UniformRead",true,"FileExtensions",'.csv');
    loadAll = readall(loadDataStore);
    clear loadDataStore;
    
    %% Format price data
    zoneCats = unique(loadAll.ZoneName);
    numZone = length(zoneCats);
    loadHourly = table();
    
    for n=1:numZone
        T = loadAll(loadAll.ZoneName == zoneCats(n), :);
        T = table2timetable(T(:,["TimeStamp","Load"]));
        T = retime(T,"hourly","mean");
        T = timetable2table(T);
        T.ZoneName = repelem(zoneCats(n),height(T))';
        T = movevars(T,"ZoneName","After","TimeStamp");
        loadHourly = [loadHourly; T];
    end
    
    loadHourly = sortrows(loadHourly,"TimeStamp","ascend");
    
    % Add zone ID
    loadHourly.ZoneID(loadHourly.ZoneName == 'CAPITL') = "F";
    loadHourly.ZoneID(loadHourly.ZoneName == 'CENTRL') = "C";
    loadHourly.ZoneID(loadHourly.ZoneName == 'DUNWOD') = "I";
    loadHourly.ZoneID(loadHourly.ZoneName == 'GENESE') = "B";
    loadHourly.ZoneID(loadHourly.ZoneName == 'HUD VL') = "G";
    loadHourly.ZoneID(loadHourly.ZoneName == 'LONGIL') = "K";
    loadHourly.ZoneID(loadHourly.ZoneName == 'MHK VL') = "E";
    loadHourly.ZoneID(loadHourly.ZoneName == 'MILLWD') = "H";
    loadHourly.ZoneID(loadHourly.ZoneName == 'N.Y.C.') = "J";
    loadHourly.ZoneID(loadHourly.ZoneName == 'NORTH') = "D";
    loadHourly.ZoneID(loadHourly.ZoneName == 'WEST') = "A";
    loadHourly.ZoneID = categorical(loadHourly.ZoneID);
    
    %% Write hourly price data
    writetable(loadHourly,outfilename);  
    save(matfilename,"loadHourly");
    fprintf("Finished writing price data in %s and %s!\n",outfilename,matfilename);
    
else
    
    fprintf("Load data already exists in %s and %s!\n",outfilename,matfilename); 
        
end

end

function loadData = importLoad(filename, dataLines)
%IMPORTLOAD Import NYISO real-time load data

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 5);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "TimeZone", "ZoneName", "PTID", "Load"];
opts.VariableTypes = ["datetime", "categorical", "categorical", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["TimeZone", "ZoneName"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");

% Import the data
try
    opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");
    loadData = readtable(filename, opts);
catch
    opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm");
    loadData = readtable(filename, opts);
end

end