function writePrice(year)
%WRITEFUELMIX write NYISO hourly real-time zonal price data in 2019

%   Created by Bo Yuan, Cornell University
%   Last modified on September 13, 2021

%% Input handling
if isempty(year)
    year = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','priceHourly_'+string(year)+'.csv');

if ~isfile(outfilename) % File doesn't exist
    %% Down load price data
    downloadData(year,'rtprice');
    
    %% Read price data
    priceFileDir = fullfile('Prep',string(year),'rtprice');
    priceFileName = string(year)+"*";
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
    
    priceHourly = sortrows(priceHourly,"TimeStamp","ascend");
    
    %% Write hourly price data
    outfilename = fullfile('Data','priceHourly_'+string(year)+'.csv');
    writetable(priceHourly,outfilename);
    
    fprintf("Finished writing price data in %s!\n",outfilename);
    
else
    
    fprintf("Price data already exists in %s!\n",outfilename); 
        
end

end

function realtimezone = importPrice(filename, dataLines)
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
realtimezone = readtable(filename, opts);

end