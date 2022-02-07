function writePrice(testyear)
%WRITEFUELMIX write NYISO hourly real-time zonal price data

%   Created by Bo Yuan, Cornell University
%   Last modified on September 13, 2021

%% Input handling
if isempty(testyear)
    testyear = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','priceHourly_'+string(testyear)+'.csv');
matfilename = fullfile('Data','priceHourly_'+string(testyear)+'.mat');

if ~isfile(outfilename) || ~isfile(matfilename) % File doesn't exist
    %% Down load price data
    downloadData(testyear,'rtprice');
    
    %% Read price data
    priceFileDir = fullfile('Prep',string(testyear),'rtprice');
    priceFileName = string(testyear)+"*";
    priceDataStore = fileDatastore(fullfile(priceFileDir,priceFileName),...
        "ReadFcn",@importPrice,"UniformRead",true,"FileExtensions",'.csv');
    priceAll = readall(priceDataStore);
    clear priceDataStore;
    
    %% Format price data
    zoneCats = unique(priceAll.ZoneName);
    numZone = length(zoneCats);
    priceHourly = table();
    
    for n=1:numZone
        T = priceAll(priceAll.ZoneName == zoneCats(n), :);
        T = table2timetable(T(:,["TimeStamp","LBMP","MarginalCostLosses","MarginalCostCongestion"]));
        T = retime(T,"hourly","mean");
        T = timetable2table(T);
        T.ZoneName = repelem(zoneCats(n),height(T))';
        T = movevars(T,"ZoneName","After","TimeStamp");
        priceHourly = [priceHourly; T];
    end
    
    % Convert timestamp UTC back to local time in New York
    priceHourly = sortrows(priceHourly,"TimeStamp","ascend");
%     priceHourly.TimeStampUTC.TimeZone = 'Z';
%     priceHourly.TimeStamp = priceHourly.TimeStampUTC;
%     priceHourly.TimeStamp.TimeZone = 'America/New_York';
%     priceHourly.TimeZone(isdst(priceHourly.TimeStamp)) = "EDT";
%     priceHourly.TimeZone(~isdst(priceHourly.TimeStamp)) = "EST";
%     priceHourly.TimeZone = categorical(priceHourly.TimeZone);
    
    %% Write hourly price data
    writetable(priceHourly,outfilename);
    save(matfilename,'priceHourly');
    fprintf("Finished writing price data in %s and %s!\n",outfilename,matfilename);
    
else
    
    fprintf("Price data already exists in %s and %s!\n",outfilename,matfilename); 
        
end

end

function priceData = importPrice(filename, dataLines)
%IMPORTPRICE Import NYISO real-time zonal price data

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 6);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "ZoneName", "PTID", "LBMP", "MarginalCostLosses", "MarginalCostCongestion"];
opts.VariableTypes = ["datetime", "categorical", "categorical", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["ZoneName", "PTID"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");

% Import the data
try
    opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");
    priceData = readtable(filename, opts);
catch
    opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm");
    priceData = readtable(filename, opts);
end

end