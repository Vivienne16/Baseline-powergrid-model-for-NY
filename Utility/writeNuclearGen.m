function writeNuclearGen(testyear)
%WRITENUCLEARGEN Download and process daily nuclear capacity factor data from NRC

%   Created by Bo Yuan, Cornell University
%   Last modified on September 13, 2021

%% Input handling

if isempty(testyear)
    testyear = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','nuclearGenDaily_'+string(testyear)+'.csv');
matfilename = fullfile('Data','nuclearGenDaily_'+string(testyear)+'.mat');

if ~isfile(outfilename) || ~isfile(matfilename) % File doesn't exist
    %% Downlaod data from NRC
    nuclearDir = fullfile('Prep',string(testyear),'nuclear');
    createDir(nuclearDir);
    apiroot = "https://www.nrc.gov/reading-rm/doc-collections/event-status/reactor-status/%d/";
    api = sprintf(apiroot,testyear);
    suffix = "PowerStatus.txt";
    
    filename = sprintf('%d%s',testyear,suffix);
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
    if testyear >= 2020
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
    nuclearGenDaily = nuclearDaily(nuclearDaily.Unit == unitNames(1), ["TimeStamp","Power"]);
    nuclearGenDaily.Gen = nuclearGenDaily.Power*unitCaps(1);
    nuclearGenDaily.Properties.VariableNames(end-1) = erase(string(unitNames(1))," ")+"CF";
    nuclearGenDaily.Properties.VariableNames(end) = erase(string(unitNames(1))," ")+"Gen";
    
    for n=2:numUnit
        T = nuclearDaily(nuclearDaily.Unit == unitNames(n), ["TimeStamp","Power"]);
        nuclearGenDaily = outerjoin(nuclearGenDaily,T,"Keys","TimeStamp","MergeKeys",true);
        nuclearGenDaily.Gen = nuclearGenDaily.Power*unitCaps(n);
        nuclearGenDaily.Properties.VariableNames(end-1) = erase(string(unitNames(n))," ")+"CF";
        nuclearGenDaily.Properties.VariableNames(end) = erase(string(unitNames(n))," ")+"Gen";
    end
    
    nuclearGenDaily.TimeStamp.Format = "MM/dd/yyyy";
    
    %% Save the data
    writetable(nuclearGenDaily,outfilename);
    save(matfilename,'nuclearGenDaily');
    fprintf("Finished writing nuclear generation data in %s and %s!\n",outfilename,matfilename);
    
else
    
    fprintf("Nuclear generation data already exists in %s and %s!\n",outfilename,matfilename);
    
end

end