function writeInterflow(year)
%WRITEINTERFLOW write NYISO hourly interface flow data in 2019

%   Created by Bo Yuan, Cornell University
%   Last modified on Septemper 9, 2021

%% Input handling
if isempty(year)
    year = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','interflowHourly_'+string(year)+'.csv');

if ~isfile(outfilename) % File doesn't exist
    %% Download interface flow data
    downloadData(year,'interflow');
    
    %% Read interface flow data
    interflowFileDir = fullfile('Prep',string(year),'interflow');
    interflowFileName = string(year)+"*";
    interflowDataStore = fileDatastore(fullfile(interflowFileDir,interflowFileName),...
        "ReadFcn",@importInterflow,"UniformRead",true,"FileExtensions",'.csv');
    interflowAll = readall(interflowDataStore);
    clear interflowDataStore;
    
    %% Format interface flow data
    interCats = unique(interflowAll.InterfaceName);
    numInter = length(interCats);
    interflowHourly = table();
    
    for n=1:numInter
        T = interflowAll(interflowAll.InterfaceName == interCats(n), :);
        T = table2timetable(T(:,["TimeStamp","FlowMWH","PositiveLimitMWH","NegativeLimitMWH"]));
        T = retime(T,"hourly","mean");
        T = timetable2table(T);
        T.InterfaceName = repelem(interCats(n),height(T))';
        T = movevars(T,"InterfaceName","After","TimeStamp");
        interflowHourly = [interflowHourly; T];
    end
    
    interflowHourly = sortrows(interflowHourly,"TimeStamp","ascend");
    
    %% Write hourly interface flow data
    outfilename = fullfile('Data','interflowHourly_'+string(year)+'.csv');
    writetable(interflowHourly,outfilename);    
    fprintf("Finished writing interface flow data in %s!\n",outfilename);
  
else
    
    fprintf("Interface flow data already exists in %s!\n",outfilename);
    
end

end

function interfaceFlow = importInterflow(filename, dataLines)
%IMPORTINTERFLOW Import NYISO real-time interface flow data

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 6);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "InterfaceName", "PointID", "FlowMWH", "PositiveLimitMWH", "NegativeLimitMWH"];
opts.VariableTypes = ["datetime", "categorical", "categorical", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["InterfaceName", "PointID"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm");

% Import the data
interfaceFlow = readtable(filename, opts);

end