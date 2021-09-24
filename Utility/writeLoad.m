function writeLoad(year)
%WRITEFUELMIX write NYISO hourly real-time zonal load data

%   Created by Bo Yuan, Cornell University
%   Last modified on September 13, 2021

%% Input handling
if isempty(year)
    year = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','loadHourly_'+string(year)+'.csv');

if ~isfile(outfilename) % File doesn't exist
    %% Down load price data
    downloadData(year,'rtload');
    
    %% Read price data
    loadFileDir = fullfile('Prep',string(year),'rtload');
    loadFileName = string(year)+"*";
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
    
    %% Write hourly price data
    writetable(loadHourly,outfilename);  
    fprintf("Finished writing price data in %s!\n",outfilename);
    
else
    
    fprintf("Load data already exists in %s!\n",outfilename); 
        
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
loadData = readtable(filename, opts);

end