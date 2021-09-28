function genData = importGenData(filename,dataLines)
%IMPORTGENDATA Import RGGI thermal generation data

%% Input handling

% If dataLines is not specified,define defaults
if nargin < 2
    dataLines = [2,Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables",24);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Var1","FacilityName","FacilityID","UnitID","Date",...
    "Hour","OperatingTime","GrossLoadMW","Var9","Var10","Var11","Var12","Var13",...
    "Var14","Var15","Var16","Var17","Var18","Var19","Var20","Var21",...
    "HeatInputMMBtu","Var23","Var24"];
opts.SelectedVariableNames = ["FacilityName","FacilityID","UnitID",...
    "Date","Hour","OperatingTime","GrossLoadMW","HeatInputMMBtu"];
opts.VariableTypes = ["string","categorical","categorical","string","datetime",...
    "double","double","double","string","string","string","string","string",...
    "string","string","string","string","string","string","string",...
    "string","double","string","string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts,"Date","InputFormat","MM-dd-yyyy");
opts = setvaropts(opts,["FacilityName","FacilityID","UnitID"],"EmptyFieldRule","auto");
opts = setvaropts(opts,["GrossLoadMW","HeatInputMMBtu"],"TrimNonNumeric",true);
opts = setvaropts(opts,["GrossLoadMW","HeatInputMMBtu"],"ThousandsSeparator",",");

% Import the data
genData = readtable(filename,opts);

% Replacing GrossLoad NaN with 0
genData.GrossLoadMW(ismissing(genData.GrossLoadMW)) = 0;
genData.HeatInputMMBtu(ismissing(genData.HeatInputMMBtu)) = 0;

% Format timestamps
genData.TimeStamp = datetime(year(genData.Date),month(genData.Date),...
    day(genData.Date),genData.Hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
genData = removevars(genData,["Date","Hour"]);
genData = movevars(genData,"TimeStamp","Before","FacilityName");

% Remove leading zeros in Unit ID
genData.UnitID = strip(genData.UnitID,'left','0');
genData.UnitID = categorical(genData.UnitID);


end