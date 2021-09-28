function refTable = importRefTable(workbookFile, sheetName, dataLines)
%IMPORTREFTABLE Import RGGI to NYCA reference table

%% Input handling

% If no sheet is specified, read first sheet
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% If row start and end points are not specified, define defaults
if nargin <= 2
    dataLines = [2, 184];
end

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 21);

% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = "A" + dataLines(1, 1) + ":U" + dataLines(1, 2);

% Specify column names and types
opts.VariableNames = ["NYISOName", "PTID", "Zone", "FacilityName", "FacilityID", ...
    "UnitID", "UnitType", "FuelType", "OperatingTime", "GrossLoadMWh", "HeatInputMMBtu", ...
    "Latitude", "Longitude", "MaxHourlyHIRateMMBtuhr", "NamePlateRatingMW", "NetEnergyGWh", ...
    "CRISSummerMW", "CRISWinterMW", "CapabilitySummerMW", "CapabilityWinterMW", "Combined"];
opts.VariableTypes = ["categorical", "categorical", "categorical", "categorical",...
    "categorical", "categorical", "categorical", "categorical", "double", "double",...
    "double", "double", "double", "double", "double", "double", "double", "double",...
    "double", "double", "categorical"];
opts.SelectedVariableNames = ["NYISOName", "PTID", "Zone", "FacilityName", ...
    "FacilityID", "UnitID", "UnitType", "FuelType", "OperatingTime", "GrossLoadMWh",...
    "HeatInputMMBtu", "Latitude", "Longitude", "MaxHourlyHIRateMMBtuhr", ...
    "NamePlateRatingMW", "NetEnergyGWh", "Combined"];

% Specify variable properties
opts = setvaropts(opts, ["NYISOName", "PTID", "Zone", "FacilityName", "FacilityID", "UnitID", "UnitType", "FuelType", "Combined"], "EmptyFieldRule", "auto");

% Import the data
refTable = readtable(workbookFile, opts, "UseExcel", false);

for idx = 2:size(dataLines, 1)
    opts.DataRange = "A" + dataLines(idx, 1) + ":U" + dataLines(idx, 2);
    tb = readtable(workbookFile, opts, "UseExcel", false);
    refTable = [refTable; tb]; %#ok<AGROW>
end

end