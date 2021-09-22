function msg = writePrice(year)
%WRITEFUELMIX write NYISO hourly real-time zonal price data in 2019

%   Created by Bo Yuan, Cornell University
%   Last modified on September 13, 2021

% Input handling
if nargin < 1 && isempty(year)
    year = 2019; % Default data in year 2019
end

try
    % Read fuel mix data
    priceFileDir = fullfile('..\Prep','rtprice');
    priceFileName = string(year)+"*";
    priceDataStore = fileDatastore(fullfile(priceFileDir,priceFileName),...
        "ReadFcn",@importPrice,"UniformRead",true,"FileExtensions",'.csv');
    priceAll = readall(priceDataStore);
    clear priceDataStore;
    
    %% Format fuel mix data
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
    
    % Write hourly fuel mix data
    outfilename = fullfile('..\Data','priceHourly.csv');
    writetable(priceHourly,outfilename);
    msg = "Success!";
catch ME
    msg = ME.message;
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