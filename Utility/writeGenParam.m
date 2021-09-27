function writeGenParam(year)
%WRITEGENPARAM Calculate generator parameters

%% Input handling

% Exclude biogas (methane) and wood generators or not
rmBio = true;
% Exclude generators with total generation less than 1 GW or not
rmLt1GWh = false;

%% Import the data

% Import hourly generation data of large generators in RGGI database
genFileDir = fullfile('Prep',string(year),'rtgen');
genFileName = string(year)+"*";
genDataStore = fileDatastore(fullfile(genFileDir,genFileName),...
    "ReadFcn",@importGenerationData,"UniformRead",true,"FileExtensions",'.csv');
genLarge = readall(genDataStore);
clear genDataStore;

% Import the reference table from RGGI to NYISO NYCA database
genCombiner = importRefTable(fullfile('Data','RGGI_2_NYCA_2019.xlsx'));

% Remove the generators with zero generation in 2019
genCombiner = genCombiner(genCombiner.NetEnergyGWh > 0, :);
genCombiner = genCombiner(genCombiner.GrossLoadMWh > 0, :);

% Exclude generators with total generation less than 1
if rmLt1GWh == true
    genCombiner = genCombiner(genCombiner.NetEnergyGWh >= 1, :);
end

% Exclude biogas (methane) and wood generators
if rmBio == true
    genCombiner = genCombiner(genCombiner.FuelType ~= "Wood", :);
    genCombiner = genCombiner(genCombiner.FuelType ~= "Refuse", :);
end

% Create arrays of key features
NYISONames = unique(genCombiner.NYISOName);
PTIDs = unique(genCombiner.PTID);
unitTypes = unique(genCombiner.UnitType);
fuelTypes = unique(genCombiner.FuelType);
Zones = unique(genCombiner.Zone);
numGenMatched = length(PTIDs);

%% Combine the RGGI database with the NYCA database

genLargeJoint = innerjoin(genLarge,genCombiner,"Keys",["FacilityName","FacilityID","UnitID"], ...
    "LeftVariables", ["TimeStamp","FacilityName","FacilityID","UnitID","GrossLoadMW","HeatInputMMBtu"], ...
    "RightVariables", ["NYISOName","PTID","Zone","UnitType","FuelType","Combined"]);

%% Calculate hourly generation of each thermal generator (PTID)

hourlyGenLarge = groupsummary(genLargeJoint, ["TimeStamp","NYISOName","PTID"],"sum",["GrossLoadMW","HeatInputMMBtu"]);
hourlyGenLarge.Properties.VariableNames(end-1:end) = ["hourlyGen","hourlyHeatInput"];
hourlyGenLarge = removevars(hourlyGenLarge, "GroupCount");

% Save hourly generation data
save(fullfile('Data','hourlyGenLarge.mat'),"hourlyGenLarge","-mat");

%% Generator parameter calculation

% Define arrays to record NYISO generators" parameter
% We define a generator by its PTID. 144 generators.
% Different generator could have same NYISO name.
% One PTID could correspond to multiple units in the RGGI database.
maxPower = zeros(numGenMatched, 1);
minPower = zeros(numGenMatched, 1);
maxHeat = zeros(numGenMatched, 1);
minHeat = zeros(numGenMatched, 1);
maxRampUp = zeros(numGenMatched, 1);
maxRampDown = zeros(numGenMatched, 1);
HeatRateLM = zeros(numGenMatched, 2);
HeatRateQM = zeros(numGenMatched, 3);
HeatRateLM_R2 = zeros(numGenMatched, 1);
HeatRateQM_R2 = zeros(numGenMatched, 1);
hourlyGenFilteredTables = cell(numGenMatched, 1);

% Parameter settings
% Calcualte max output and min output (lowest 5%)
lowPercent = 5;
highPercent = 100;

for i=1:numGenMatched
    % Subset generation table by PTID
    hourlyGenPT = hourlyGenLarge(hourlyGenLarge.PTID == PTIDs(i), :);
    
    % Calculate ramp rate
    rampRate = hourlyGenPT.hourlyGen(2:end) - hourlyGenPT.hourlyGen(1:end-1);
    hourlyGenPT.RampRate = [rampRate; 0];
    
    % Exclude hours with zero generation, also exclude ramp down to zero
    hourlyGenNZ = hourlyGenPT(hourlyGenPT.hourlyGen > 0, :);
    [genOutIdx,genPer10,genMax,~] = isoutlier(hourlyGenNZ.hourlyGen,"percentiles", [lowPercent, highPercent]);
    [heatOutIdx,heatPer10,heatMax,~] = isoutlier(hourlyGenNZ.hourlyHeatInput,"percentiles", [lowPercent, highPercent]);
    genHeatOutIdx = genOutIdx|heatOutIdx;
    hourlyGenNZFiltered = hourlyGenNZ(~genHeatOutIdx, :);
    
    try
        % Fit linear model of heat rate
        genHeatLM = fitlm(hourlyGenNZFiltered, "hourlyHeatInput ~ 1 + hourlyGen");
        HeatRateLM_R2(i) = genHeatLM.Rsquared.Adjusted;
        HeatRateLM(i, :) = genHeatLM.Coefficients.Estimate.';
        hourlyGenNZFiltered.HeatRateLMFit = genHeatLM.Fitted;
        
        % Fit quadratic model of heat rate
        genHeatQM = fitlm(hourlyGenNZFiltered, "hourlyHeatInput ~ 1 + hourlyGen + hourlyGen^2");
        HeatRateQM_R2(i) = genHeatQM.Rsquared.Adjusted;
        HeatRateQM(i, :) = genHeatQM.Coefficients.Estimate.';
        hourlyGenNZFiltered.HeatRateQMFit = genHeatQM.Fitted;
        
        % Store the results
        maxPower(i) = genMax;
        minPower(i) = genPer10;
        maxRampUp(i) = max(hourlyGenNZFiltered.RampRate);
        maxRampDown(i) = min(hourlyGenNZFiltered.RampRate);
        hourlyGenFilteredTables{i} = hourlyGenNZFiltered;
    catch
        fprintf("Error in heat rate regression: %s",PTIDs(i));
    end
end

%% Combine generator parameters into one summary table

maxRamp60 = (maxRampUp + abs(maxRampDown))/2;
maxRamp30 = maxRamp60/2;
maxRamp10 = maxRamp30/3;
maxRampAgc = maxRamp10/10;
paramSummary = table(PTIDs, maxPower, minPower, maxRampAgc, maxRamp10, maxRamp30, maxRamp60);
paramSummary.HeatRateLM_1 = HeatRateLM(:, 2);
paramSummary.HeatRateLM_0 = HeatRateLM(:, 1);
paramSummary.HeatRateLM_R2 = HeatRateLM_R2;
paramSummary.HeatRateQM_2 = HeatRateQM(:, 3);
paramSummary.HeatRateQM_1 = HeatRateQM(:, 2);
paramSummary.HeatRateQM_0 = HeatRateQM(:, 1);
paramSummary.HeatRateQM_R2 = HeatRateQM_R2;
paramSummary.Properties.VariableNames(1) = "PTID";

% Remove duplicated generator names in the generator combiner (multiple RGGI generators with the same PTID)
genComNoDup = genCombiner(genCombiner.Combined == "0",["NYISOName","PTID","Zone","UnitType","FuelType", ...
    "NamePlateRatingMW","NetEnergyGWh","Latitude","Longitude"]);
genComDup = genCombiner(genCombiner.Combined == "1",["NYISOName","PTID","Zone","UnitType","FuelType", ...
    "NamePlateRatingMW","NetEnergyGWh","Latitude","Longitude"]);
genComDupRed = unique(genComDup, "rows");
genComRed = [genComNoDup; genComDupRed];

% Add generator information to the generator summary table
paramSummaryJoint = outerjoin(genComRed, paramSummary,"Type","right","Keys","PTID", ...
    "LeftVariables",["NYISOName","Zone","UnitType","FuelType","Latitude","Longitude"]);
paramSummaryJoint = movevars(paramSummaryJoint,"PTID","After","NYISOName");

%% Heat rate bad fitting handling

useLM = false;
% Select R2 below 0.8 bad fit results
R2Limit = 0.8;

if useLM == true   
    % Linear model
    badLMIdx = paramSummaryJoint.HeatRateLM_R2 < R2Limit;
    badLMNum = nnz(badLMIdx);
    badLMTable = paramSummaryJoint(badLMIdx, :);
    goodLMTable = paramSummaryJoint(~badLMIdx, :);
    badLMData = hourlyGenFilteredTables(badLMIdx);
    
    % Plot bad fit LM data
    f = figure;
    colNum = 7;
    rowNum = int16(badLMNum/colNum);
    t = tiledlayout(rowNum, colNum, "TileSpacing","compact");
    for n=1:badLMNum
        nexttile;
        badFitPTID = badLMTable(n, :).PTID;
        badFitName = badLMTable(n, :).NYISOName;
        badFitLMR2 = badLMTable(n, :).HeatRateLM_R2;
        badFitQMR2 = badLMTable(n, :).HeatRateQM_R2;
        badFitLMCoef = table2array(badLMTable(n, ["HeatRateLM_0","HeatRateLM_1"]));
        badFitQMCoef = table2array(badLMTable(n, ["HeatRateQM_0","HeatRateQM_1","HeatRateQM_2"]));
        badFitDataTable = badLMData{n};
        % Plot data and fit
        scatter(badFitDataTable.hourlyGen, badFitDataTable.hourlyHeatInput, ".");
        hold on;
        x = min(badFitDataTable.hourlyGen): max(badFitDataTable.hourlyGen);
        plot(x, badFitLMCoef(1) + badFitLMCoef(2).*x, "r-");
        plot(x, badFitQMCoef(1) + badFitQMCoef(2).*x + badFitQMCoef(3).*x.^2, "k-");
        hold off; box on;
        txt = sprintf("%s: LM %.3f, QM %.3f", badFitPTID, badFitLMR2, badFitQMR2);
        if badFitLMR2 > badFitQMR2
            color = "red";
        else
            color = "black";
        end
        title(txt, "Color", color);
    end
    xlabel(t, "Generation (MW)");
    ylabel(t, "Heat Input (MMBtu/h)");
    title(t, "Genertors with bad LM heat curve fitness");
    set(f, "Position", [50, 50, 1600, 900]);
end

% Quadratic model bad fits
% Quadratic model
badQMIdx = paramSummaryJoint.HeatRateQM_R2 < R2Limit;
badQMNum = nnz(badQMIdx);
badQMTable = paramSummaryJoint(badQMIdx, :);
goodQMTable = paramSummaryJoint(~badQMIdx, :);
badQMData = hourlyGenFilteredTables(badQMIdx);

% Plot bad fit QM data
f = figure;
colNum = 5;
rowNum = int16(badQMNum/colNum);
t = tiledlayout(rowNum, colNum, "TileSpacing","compact");
for n=1:badQMNum
    % Read bad fit data
    badFitPTID = badQMTable(n, :).PTID;
    badFitName = badQMTable(n, :).NYISOName;
    badFitLMR2 = badQMTable(n, :).HeatRateLM_R2;
    badFitQMR2 = badQMTable(n, :).HeatRateQM_R2;
    badFitLMCoef = table2array(badQMTable(n, ["HeatRateLM_0","HeatRateLM_1"]));
    badFitQMCoef = table2array(badQMTable(n, ["HeatRateQM_0","HeatRateQM_1","HeatRateQM_2"]));
    badFitDataTable = badQMData{n};
    
    % Plot data and fit
    nexttile;
    scatter(badFitDataTable.hourlyGen, badFitDataTable.hourlyHeatInput, ".");
    hold on;
    x = min(badFitDataTable.hourlyGen): max(badFitDataTable.hourlyGen);
    plot(x, badFitLMCoef(1) + badFitLMCoef(2).*x, "r-");
    plot(x, badFitQMCoef(1) + badFitQMCoef(2).*x + badFitQMCoef(3).*x.^2, "k-");
    hold off; box on;
    xlim([x(1)*0.95, x(end)*1.05]);
    txt = sprintf("%s: LM %.3f, QM %.3f", badFitPTID, badFitLMR2, badFitQMR2);
    if badFitLMR2 > badFitQMR2
        color = "red";
    else
        color = "black";
    end
    title(txt, "Color", color);
end
xlabel(t, "Generation (MW)");
ylabel(t, "Heat Input (MMBtu/h)");
title(t, "Genertors with bad QM heat curve fitness");
set(f, "Position", [50, 50, 1600, 900]);

%% Subset the bad fit generators into 3 categories
badQMPTIDs = badQMTable.PTID;
badQMPTIDGp = cell(3, 1);
badQMTableGp = cell(3, 1);
badQMDataGp = cell(3, 1);
% Group 1: Different heat input with the same generation
badQMPTIDGp{1} = categorical([1659, 23802, 24151]);
testTable = badQMTable(ismember(badQMPTIDs, badQMPTIDGp{1}), :);
badQMTableGp{1} = testTable;
badQMDataGp{1} = badQMData(ismember(badQMPTIDs, badQMPTIDGp{1}), :);
% Group 2: Large CC generators, thick lines.
badQMPTIDGp{2} = categorical([23820, 323582]);
testTable = badQMTable(ismember(badQMPTIDs, badQMPTIDGp{2}), :);
badQMTableGp{2} = testTable;
badQMDataGp{2} = badQMData(ismember(badQMPTIDs, badQMPTIDGp{2}), :);
% Group 3: Point wise, on-off small combustion turbines
testTable = badQMTable(~ismember(badQMPTIDs, union(badQMPTIDGp{1},badQMPTIDGp{2})), :);
badQMTableGp{3} = testTable;
badQMDataGp{3} = badQMData(~ismember(badQMPTIDs, union(badQMPTIDGp{1},badQMPTIDGp{2})), :);

%% Modify parameter table due to bad fitting

% Group 1: keep what we have now.
fixedBadQMTableGp = cell(3, 1);
badQMInfo = badQMTableGp{1};
badQMInfo.useQM = ones(height(badQMInfo), 1);
fixedBadQMTableGp{1} = badQMInfo;

% Group 2: remove abnormal heat rate data
%   Ravenswood CC 04: remove data from 8/8/2019 17:00 - 11/08/2019 9:00 (constant heat rate).
%   Astoria East Energy CC2: remove data from 06/29/2019 19:00 - 08/23/2019 1:00 (abnormally high heat input)
badQMInfo = badQMTableGp{2};
startTimeStamp = datetime(['08/08/2019 17:00:00';'06/29/2019 19:00:00'],"Format","MM/dd/uuuu HH:mm:ss");
endTimeStamp = datetime(['11/08/2019 09:00:01';'08/23/2019 01:00:00'],"Format","MM/dd/uuuu HH:mm:ss");

f = figure;
t = tiledlayout(1,2,"TileSpacing","compact");
for j=1:2
    genName = badQMInfo.NYISOName(j);
    PTID = badQMInfo.PTID(j);
    testTable = badQMDataGp{i}{j};
    testTable = testTable(~(testTable.TimeStamp >= startTimeStamp(j) & testTable.TimeStamp <= endTimeStamp(j)),:);
    
    % Fit quadratic model of heat rate
    genHeatQM = fitlm(testTable, "hourlyHeatInput ~ 1 + hourlyGen + hourlyGen^2");
    badQMInfo.HeatRateQM_R2(j) = genHeatQM.Rsquared.Adjusted;
    badQMInfo.HeatRateQM_2(j) = genHeatQM.Coefficients.Estimate(3);
    badQMInfo.HeatRateQM_1(j) = genHeatQM.Coefficients.Estimate(2);
    badQMInfo.HeatRateQM_0(j) = genHeatQM.Coefficients.Estimate(1);
    testTable.HeatRateQMFit = genHeatQM.Fitted;
    
    % Plot new fitting results
    nexttile;
    scatter(testTable.hourlyGen, testTable.hourlyHeatInput);
    hold on;
    scatter(testTable.hourlyGen, testTable.HeatRateQMFit);
    box on; hold off;
    title(string(PTID)+": "+string(genName));
end
xlabel(t, "Generation (MW)");
ylabel(t, "Heat input (MMBtu)");
title(t, "New regression results");
set(f, "Position", [100, 100, 1000, 400]);

% Store it back to cell array
badQMInfo.useQM = ones(height(badQMInfo), 1);
fixedBadQMTableGp{2} = badQMInfo;

% Group 3: replace it with standard linear heat rate curve
%   Set min power as zero
%   Set max hourly ramp rate as max power (instant ramp to maximum)
badQMInfo = badQMTableGp{3};
badQMInfo.minPower = zeros(height(badQMInfo), 1);
badQMInfo.maxRampAgc = badQMInfo.maxPower./60;
badQMInfo.maxRamp10 = badQMInfo.maxPower./6;
badQMInfo.maxRamp30 = badQMInfo.maxPower./2;
badQMInfo.maxRamp60 = badQMInfo.maxPower;
% Heat rate data from EIA 2019
for n=1:height(badQMInfo)
    unitType = badQMInfo.UnitType(n);
    fuelType = badQMInfo.FuelType(n);
    badQMInfo.HeatRateLM_1(n) = standardHeatRate(unitType, fuelType);
end
badQMInfo.HeatRateLM_0 = zeros(height(badQMInfo), 1);
badQMInfo.HeatRateLM_R2 = zeros(height(badQMInfo), 1);
badQMInfo.HeatRateQM_2 = zeros(height(badQMInfo), 1);
badQMInfo.HeatRateQM_1 = zeros(height(badQMInfo), 1);
badQMInfo.HeatRateQM_0 = zeros(height(badQMInfo), 1);
badQMInfo.HeatRateQM_R2 = zeros(height(badQMInfo), 1);
% Store it back to cell array
badQMInfo.useQM = zeros(height(badQMInfo), 1);
fixedBadQMTableGp{3} = badQMInfo;

%% Final version of the matched generator parameter table
goodQMTable.useQM = ones(height(goodQMTable), 1);
paramMatchedFinal = [goodQMTable; fixedBadQMTableGp{1}; fixedBadQMTableGp{2}; fixedBadQMTableGp{3}];

%% Unmatched generator parameters

% Import unmatched generator data
genNotMatched = importNotMatched(dataDir + "2019_NYCA_Not_Matched.xlsx");

% Generator data cleaning
% Exclude generators with total generation less than 0 GWh
genNMFiltered = genNotMatched(genNotMatched.NetEnergyGWh > 0, :);
% Exclude generators fueling on wood and refuse (renewable energy)
genNMFiltered = genNMFiltered(genNMFiltered.FuelType ~= "Wood" & genNMFiltered.FuelType ~= "Refuse", :);
% Exclude methane (Bio gas)
genNMFiltered = genNMFiltered(genNMFiltered.FuelType ~= "Methane", :);

% Calculate generator parameters
paramUnmatched = removevars(genNMFiltered, ["NetEnergyGWh","CRISSummerMW","CRISWinterMW","CapabilitySummerMW","CapabilityWinterMW"]);
paramUnmatched = movevars(paramUnmatched,"PTID","After","NYISOName");
numNMGen = size(paramUnmatched, 1);

paramUnmatched.maxPower = paramUnmatched.NamePlateRatingMW;
paramUnmatched = removevars(paramUnmatched, "NamePlateRatingMW");
paramUnmatched.minPower = zeros(numNMGen, 1);
paramUnmatched.maxRampAgc = paramUnmatched.maxPower./60;
paramUnmatched.maxRamp10 = paramUnmatched.maxPower./6;
paramUnmatched.maxRamp30 = paramUnmatched.maxPower./2;
paramUnmatched.maxRamp60 = paramUnmatched.maxPower;
% paramUnmatched.HeatRateLM_1 = zeros(numNMGen, 1);
for n = 1:numNMGen
    unitType = paramUnmatched.UnitType(n);
    fuelType = paramUnmatched.FuelType(n);
    paramUnmatched.HeatRateLM_1(n) = standardHeatRate(unitType, fuelType);
end
paramUnmatched.HeatRateLM_0 = zeros(numNMGen, 1);
paramUnmatched.HeatRateLM_R2 = zeros(numNMGen, 1);
paramUnmatched.HeatRateQM_2 = zeros(numNMGen, 1);
paramUnmatched.HeatRateQM_1 = zeros(numNMGen, 1);
paramUnmatched.HeatRateQM_0 = zeros(numNMGen, 1);
paramUnmatched.HeatRateQM_R2 = zeros(numNMGen, 1);
paramUnmatched.useQM = zeros(numNMGen, 1);

%% Combine matched and unmatched generator information
paramAll = [paramMatchedFinal; paramUnmatched];
paramAll.useQM = logical(paramAll.useQM);

%% Write parameter table of the matched generators
save(dataDir + "genParamAll_low5.mat","paramAll","-mat");
writetable(paramAll, dataDir + "genParamAll_low5.csv");


end

