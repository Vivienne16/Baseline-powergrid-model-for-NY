function writeInterflow(testyear)
%WRITEINTERFLOW write NYISO hourly interface flow data in the testyear

%   Created by Bo Yuan, Cornell University
%   Last modified on Feb 7, 2022

%% Input handling
if isempty(testyear)
    testyear = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','interflowHourly_'+string(testyear)+'.csv');
matfilename = fullfile('Data','interflowHourly_'+string(testyear)+'.mat');

if ~isfile(outfilename) || ~isfile(matfilename)% File doesn't exist
    %% Download interface flow data
    downloadData(testyear,'interflow');
    
    %% Read interface flow data
    interflowFileDir = fullfile('Prep',string(testyear),'interflow');
    interflowFileName = string(testyear)+"*";
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
    writetable(interflowHourly,outfilename);    
    save(matfilename,'interflowHourly');
    fprintf("Finished writing interface flow data in %s and %s!\n",outfilename,matfilename);
  
else
    
    fprintf("Interface flow data already exists in %s and %s!\n",outfilename,matfilename);
    
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
try
    opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");
    interfaceFlow = readtable(filename, opts);
catch
    opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm");
    interfaceFlow = readtable(filename, opts);
end

end