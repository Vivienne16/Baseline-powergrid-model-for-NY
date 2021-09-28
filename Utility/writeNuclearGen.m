function writeNuclearGen(year)
%WRITENUCLEARGEN Download and process daily nuclear capacity factor data from NRC

%   Created by Bo Yuan, Cornell University
%   Last modified on September 13, 2021

%% Input handling

if isempty(year)
    year = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','nuclearGenDaily_'+string(year)+'.csv');

if ~isfile(outfilename) % File doesn't exist
    %% Downlaod data from NRC
    nuclearDir = fullfile('Prep',string(year),'nuclear');
    createDir(nuclearDir);
    apiroot = "https://www.nrc.gov/reading-rm/doc-collections/event-status/reactor-status/%d/";
    api = sprintf(apiroot,year);
    suffix = "PowerStatus.txt";
    
    filename = sprintf('%d%s',year,suffix);
    url = api+filename;
    downloadname = websave(fullfile(nuclearDir,filename),url);
    
    %% Read the delimited text data
    opts = delimitedTextImportOptions("NumVariables",3);
    % Specify range and delimiter
    opts.DataLines = [2, Inf];
    opts.Delimiter = "|";
    % Specify column names and types
    opts.VariableNames = ["TimeStamp", "Unit", "Power"];
    opts.VariableTypes = ["datetime", "string", "double"];
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    % Specify variable properties
    opts = setvaropts(opts, "Unit", "WhitespaceRule", "preserve");
    opts = setvaropts(opts, "Unit", "EmptyFieldRule", "auto");
    % Different datetime format before and after year 2020
    if year >= 2020
        opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy hh:mm:ss aa");
    else
        opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy");
    end
    % Import the data
    nuclearAll = readtable(downloadname, opts);
    % Clear temporary variables
    clear opts;
    
    %% Process the data
    unitNames = ["FitzPatrick";"Ginna";"Indian Point 2";"Indian Point 3";"Nine Mile Point 1";"Nine Mile Point 2"];
    unitCaps = [854.5;581.7;1025.9;1039.9;629;1299];
    nuclearDaily = nuclearAll(ismember(nuclearAll.Unit,unitNames),:);
    nuclearDaily.Power = nuclearDaily.Power/100;
    
    numUnit = length(unitNames);
    nuclearTable = nuclearDaily(nuclearDaily.Unit == unitNames(1), ["TimeStamp","Power"]);
    nuclearTable.Gen = nuclearTable.Power*unitCaps(1);
    nuclearTable.Properties.VariableNames(end-1) = erase(string(unitNames(1))," ")+"CF";
    nuclearTable.Properties.VariableNames(end) = erase(string(unitNames(1))," ")+"Gen";
    
    for n=2:numUnit
        T = nuclearDaily(nuclearDaily.Unit == unitNames(n), ["TimeStamp","Power"]);
        nuclearTable = outerjoin(nuclearTable,T,"Keys","TimeStamp","MergeKeys",true);
        nuclearTable.Gen = nuclearTable.Power*unitCaps(n);
        nuclearTable.Properties.VariableNames(end-1) = erase(string(unitNames(n))," ")+"CF";
        nuclearTable.Properties.VariableNames(end) = erase(string(unitNames(n))," ")+"Gen";
    end
    
    nuclearTable.TimeStamp.Format = "MM/dd/yyyy";
    
    %% Save the data
    writetable(nuclearTable,outfilename);
    fprintf("Finished writing nuclear generation data in %s!\n",outfilename);
    
else
    
    fprintf("Nuclear generation data already exists in %s!\n",outfilename);
    
end

end