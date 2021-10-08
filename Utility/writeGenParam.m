function writeGenParam(testyear)
%WRITEGENPARAM Calculate generator parameters
%   Only supports 2019 generation parameter calculation now.
%   For other years, bad fitting handling is not finished.

%   Created by Bo Yuan, Cornell University
%   Last modified on Sept. 27, 2021


outfilename = fullfile('Data','genParamAll.csv');
matfilename = fullfile('Data','genParamAll.mat');

if ~isfile(outfilename) || ~isfile(matfilename) % File doesn't exist
%% Import hourly generation data of large generators in RGGI database
genFileDir = fullfile('Prep',string(testyear),'rtgen');
genFileName = string(testyear)+"*";
genDataStore = fileDatastore(fullfile(genFileDir,genFileName),...
    "ReadFcn",@importGenData,"UniformRead",true,"FileExtensions",'.csv');
genLarge = readall(genDataStore);
clear genDataStore;

%% Import the reference table from RGGI to NYISO NYCA database
genCombiner = importRefTable(fullfile('Data','thermalGenMatched_2019.xlsx'));

% Remove the generators with zero generation in 2019
genCombiner = genCombiner(genCombiner.NetEnergyGWh > 0,:);
genCombiner = genCombiner(genCombiner.GrossLoadMWh > 0,:);

% Exclude biogas (methane) and wood generators
genCombiner = genCombiner(genCombiner.FuelType ~= "Wood",:);
genCombiner = genCombiner(genCombiner.FuelType ~= "Refuse",:);

%% Group summary of nameplate capacity by unit type and fuel type
unitFuelTypeSummary = groupsummary(genCombiner,["UnitType","FuelType"],"sum",["NamePlateRatingMW","GrossLoadMWh"]);
total_cap = sum(unitFuelTypeSummary.sum_NamePlateRatingMW);
total_gen = sum(unitFuelTypeSummary.sum_GrossLoadMWh);
unitFuelTypeSummary.capPer = unitFuelTypeSummary.sum_NamePlateRatingMW/total_cap;
unitFuelTypeSummary.genPer = unitFuelTypeSummary.sum_GrossLoadMWh/total_gen;
unitFuelTypeSummary.Properties.VariableNames = ["unitType","fuelType","Count","totalCapacity","totalGeneration","capPercent","genPercent"];

% Group summary of capacity and generation by unit type
unitTypeSummary = groupsummary(unitFuelTypeSummary,"unitType","sum",["Count","totalCapacity","capPercent","totalGeneration","genPercent"]);
unitTypeSummary = removevars(unitTypeSummary,"GroupCount");
unitTypeSummary.Properties.VariableNames = ["unitType","Count","totalCapacity","capPercent","totalGeneration","genPercent"];

% Group summary of capacity and generation by fuel type
fuelTypeSummary = groupsummary(unitFuelTypeSummary,"fuelType","sum",["Count","totalCapacity","capPercent","totalGeneration","genPercent"]);
fuelTypeSummary = removevars(fuelTypeSummary,"GroupCount");
fuelTypeSummary.Properties.VariableNames = ["fuelType","Count","totalCapacity","capPercent","totalGeneration","genPercent"];

% Show pie chart of the capacity composition
f = figure;
t = tiledlayout(2,2,"TileSpacing","compact");
nexttile;
h = pie(unitTypeSummary.totalCapacity);
set(findobj(h,'type','text'),'fontsize',14)
title("Capacity - unit type","FontSize",14);
nexttile;
h = pie(unitTypeSummary.totalGeneration);
set(findobj(h,'type','text'),'fontsize',14);
title("Generation - unit type","FontSize",14);
legend(unitTypeSummary.unitType,"Location","eastoutside","FontSize",12);
nexttile;
h = pie(fuelTypeSummary.totalCapacity);
title("Capacity - fuel type","FontSize",14);
set(findobj(h,'type','text'),'fontsize',14)
nexttile;
h = pie(fuelTypeSummary.totalGeneration);
title("Generation - fuel type","FontSize",14);
set(findobj(h,'type','text'),'fontsize',14)
legend(fuelTypeSummary.fuelType,"Location","eastoutside","FontSize",12);
title(t,"Composition of RGGI tracked NYS fossil fuel generators in 2019","FontSize",16);
set(f,"Position",[50,50,1200,800]);

%% Combine the RGGI database with the NYCA database

genLargeJoint = outerjoin(genLarge,genCombiner,"Keys",["FacilityID","UnitID"],"Type","Right",...
    "LeftVariables",["TimeStamp","FacilityName","FacilityID","UnitID","GrossLoadMW","HeatInputMMBtu"],...
    "RightVariables",["NYISOName","PTID","Zone","UnitType","FuelType","Combined"]);

%% Calculate hourly generation of each thermal generator (PTID)

hourlyGenLarge = groupsummary(genLargeJoint,["TimeStamp","NYISOName","PTID"],"sum",["GrossLoadMW","HeatInputMMBtu"]);
hourlyGenLarge.Properties.VariableNames(end-1:end) = ["hourlyGen","hourlyHeatInput"];
hourlyGenLarge = removevars(hourlyGenLarge,"GroupCount");

% Save hourly generation data
outfilename2 = fullfile('Data','thermalGenHourly_'+string(testyear)+'.csv');
matfilename2 = fullfile('Data','thermalGenHourly_'+string(testyear)+'.mat');
writetable(hourlyGenLarge,outfilename2);
save(matfilename2,'hourlyGenLarge');
fprintf("Finished writing thermal generation data in %s and %s\n",outfilename2,matfilename2);

%% Generator parameter calculation

PTIDs = unique(hourlyGenLarge.PTID);
numGenMatched = length(PTIDs);

% Define arrays to record NYISO generators" parameter
% We define a generator by its PTID. 129 generators.
% Different generator could have same NYISO name.
% One PTID could correspond to multiple units in the RGGI database.
maxPower = zeros(numGenMatched,1);
minPower = zeros(numGenMatched,1);
maxRampUp = zeros(numGenMatched,1);
maxRampDown = zeros(numGenMatched,1);
HeatRateLM = zeros(numGenMatched,2);
HeatRateQM = zeros(numGenMatched,3);
HeatRateLM_R2 = zeros(numGenMatched,1);
HeatRateQM_R2 = zeros(numGenMatched,1);
hourlyGenFilteredTables = cell(numGenMatched,1);

% Parameter settings
% Calcualte max output and min output (lowest 5%)
lowPercent = 5;
highPercent = 100;

for i=1:numGenMatched
    % Subset generation table by PTID
    hourlyGenPT = hourlyGenLarge(hourlyGenLarge.PTID == PTIDs(i),:);
    
    % Calculate ramp rate
    rampRate = hourlyGenPT.hourlyGen(2:end)-hourlyGenPT.hourlyGen(1:end-1);
    hourlyGenPT.RampRate = [rampRate;0];
    
    % Exclude hours with zero generation,also exclude ramp down to zero
    hourlyGenNZ = hourlyGenPT(hourlyGenPT.hourlyGen > 0,:);
    if isempty(hourlyGenNZ)
        fprintf("Generator %s has no generation!\n",PTIDs(i));
        
        continue;
    end
    [genOutIdx,genPer10,genMax,~] = isoutlier(hourlyGenNZ.hourlyGen,"percentiles",[lowPercent,highPercent]);
    [heatOutIdx,~,~,~] = isoutlier(hourlyGenNZ.hourlyHeatInput,"percentiles",[lowPercent,highPercent]);
    genHeatOutIdx = genOutIdx|heatOutIdx;
    hourlyGenNZFiltered = hourlyGenNZ(~genHeatOutIdx,:);
    
    try
        % Fit linear model of heat rate
        genHeatLM = fitlm(hourlyGenNZFiltered,"hourlyHeatInput~1+hourlyGen");
        HeatRateLM_R2(i) = genHeatLM.Rsquared.Adjusted;
        HeatRateLM(i,:) = genHeatLM.Coefficients.Estimate.';
        hourlyGenNZFiltered.HeatRateLMFit = genHeatLM.Fitted;
        
        % Fit quadratic model of heat rate
        genHeatQM = fitlm(hourlyGenNZFiltered,"hourlyHeatInput~1+hourlyGen+hourlyGen^2");
        HeatRateQM_R2(i) = genHeatQM.Rsquared.Adjusted;
        HeatRateQM(i,:) = genHeatQM.Coefficients.Estimate.';
        hourlyGenNZFiltered.HeatRateQMFit = genHeatQM.Fitted;
        
        % Store the results
        maxPower(i) = genMax;
        minPower(i) = genPer10;
        maxRampUp(i) = max(hourlyGenNZFiltered.RampRate);
        maxRampDown(i) = min(hourlyGenNZFiltered.RampRate);
        hourlyGenFilteredTables{i} = hourlyGenNZFiltered;
    catch ME
        fprintf("Error in heat rate regression: %s!\n",PTIDs(i));
        rethrow(ME);
    end
end

%% Combine generator parameters into one summary table

maxRamp60 = (maxRampUp+abs(maxRampDown))/2;
maxRamp30 = maxRamp60/2;
maxRamp10 = maxRamp30/3;
maxRampAgc = maxRamp10/10;
paramSummary = table(PTIDs,maxPower,minPower,maxRampAgc,maxRamp10,maxRamp30,maxRamp60);
paramSummary.HeatRateLM_1 = HeatRateLM(:,2);
paramSummary.HeatRateLM_0 = HeatRateLM(:,1);
paramSummary.HeatRateLM_R2 = HeatRateLM_R2;
paramSummary.HeatRateQM_2 = HeatRateQM(:,3);
paramSummary.HeatRateQM_1 = HeatRateQM(:,2);
paramSummary.HeatRateQM_0 = HeatRateQM(:,1);
paramSummary.HeatRateQM_R2 = HeatRateQM_R2;
paramSummary.Properties.VariableNames(1) = "PTID";

% Remove generator with zero max output
paramSummary(paramSummary.maxPower == 0, :) = [];

% Remove duplicated generator names in the generator combiner (multiple RGGI generators with the same PTID)
genComNoDup = genCombiner(genCombiner.Combined == "0",["NYISOName","PTID","Zone","UnitType","FuelType",...
    "NamePlateRatingMW","NetEnergyGWh","Latitude","Longitude"]);
genComDup = genCombiner(genCombiner.Combined == "1",["NYISOName","PTID","Zone","UnitType","FuelType",...
    "NamePlateRatingMW","NetEnergyGWh","Latitude","Longitude"]);
genComDupRed = unique(genComDup,"rows");
genComRed = [genComNoDup; genComDupRed];

% Add generator information to the generator summary table
paramSummaryJoint = outerjoin(genComRed,paramSummary,"Type","right","Keys","PTID",...
    "LeftVariables",["NYISOName","Zone","UnitType","FuelType","Latitude","Longitude"]);
paramSummaryJoint = movevars(paramSummaryJoint,"PTID","After","NYISOName");

%% Heat rate bad fitting handling

% Select R2 below 0.8 bad fit results
R2Limit = 0.8;

%% Linear model bad fits

badLMIdx = paramSummaryJoint.HeatRateLM_R2 < R2Limit;
badLMNum = nnz(badLMIdx); % 22
badLMTable = paramSummaryJoint(badLMIdx,:);
goodLMTable = paramSummaryJoint(~badLMIdx,:);
badLMData = hourlyGenFilteredTables(badLMIdx);

% Plot bad fit LM data
f = figure;
colNum = 5;
rowNum = ceil(badLMNum/colNum);
t = tiledlayout(rowNum,colNum,"TileSpacing","compact");
for n=1:badLMNum
    nexttile;
    badFitPTID = badLMTable(n,:).PTID;
    badFitLMR2 = badLMTable(n,:).HeatRateLM_R2;
    badFitQMR2 = badLMTable(n,:).HeatRateQM_R2;
    badFitLMCoef = table2array(badLMTable(n,["HeatRateLM_0","HeatRateLM_1"]));
    badFitQMCoef = table2array(badLMTable(n,["HeatRateQM_0","HeatRateQM_1","HeatRateQM_2"]));
    badFitDataTable = badLMData{n};
    % Plot data and fit
    scatter(badFitDataTable.hourlyGen,badFitDataTable.hourlyHeatInput,".");
    hold on;
    x = min(badFitDataTable.hourlyGen):max(badFitDataTable.hourlyGen);
    plot(x,badFitLMCoef(1)+badFitLMCoef(2).*x,"r-");
    plot(x,badFitQMCoef(1)+badFitQMCoef(2).*x+badFitQMCoef(3).*x.^2,"k-");
    hold off; box on;
    txt = sprintf("%s: LM %.3f,QM %.3f",badFitPTID,badFitLMR2,badFitQMR2);
    if badFitLMR2 > badFitQMR2
        color = "red";
    else
        color = "black";
    end
    title(txt,"Color",color);
end
xlabel(t,"Generation (MW)");
ylabel(t,"Heat Input (MMBtu/h)");
title(t,"Genertors with bad LM heat curve fitness");
set(f,"Position",[50,50,1200,800]);


%% Quadratic model bad fits

badQMIdx = paramSummaryJoint.HeatRateQM_R2 < R2Limit;
badQMNum = nnz(badQMIdx); % 20
badQMTable = paramSummaryJoint(badQMIdx,:);
% goodQMTable = paramSummaryJoint(~badQMIdx,:);
badQMData = hourlyGenFilteredTables(badQMIdx);

% Plot bad fit QM data
f = figure;
colNum = 5;
rowNum = ceil(badQMNum/colNum);
t = tiledlayout(rowNum,colNum,"TileSpacing","compact");
for n=1:badQMNum
    % Read bad fit data
    badFitPTID = badQMTable(n,:).PTID;
    badFitLMR2 = badQMTable(n,:).HeatRateLM_R2;
    badFitQMR2 = badQMTable(n,:).HeatRateQM_R2;
    badFitLMCoef = table2array(badQMTable(n,["HeatRateLM_0","HeatRateLM_1"]));
    badFitQMCoef = table2array(badQMTable(n,["HeatRateQM_0","HeatRateQM_1","HeatRateQM_2"]));
    badFitDataTable = badQMData{n};
    
    % Plot data and fit
    nexttile;
    scatter(badFitDataTable.hourlyGen,badFitDataTable.hourlyHeatInput,".");
    hold on;
    x = min(badFitDataTable.hourlyGen): max(badFitDataTable.hourlyGen);
    plot(x,badFitLMCoef(1) + badFitLMCoef(2).*x,"r-");
    plot(x,badFitQMCoef(1) + badFitQMCoef(2).*x + badFitQMCoef(3).*x.^2,"k-");
    hold off; box on;
    xlim([x(1)*0.95,x(end)*1.05]);
    txt = sprintf("%s: LM %.3f,QM %.3f",badFitPTID,badFitLMR2,badFitQMR2);
    if badFitLMR2 > badFitQMR2
        color = "red";
    else
        color = "black";
    end
    title(txt,"Color",color);
end
xlabel(t,"Generation (MW)");
ylabel(t,"Heat Input (MMBtu/h)");
title(t,"Genertors with bad QM heat curve fitness");
set(f,"Position",[50,50,1200,800]);

%% Subset the bad fit generators into 3 categories

badLMPTIDs = badLMTable.PTID;
badLMPTIDGp = cell(3,1);
badLMTableGp = cell(3,1);
badLMDataGp = cell(3,1);

% Group 1: Different heat input with the same generation
badLMPTIDGp{1} = categorical([1659,23802,24151]);
testTable = badLMTable(ismember(badLMPTIDs,badLMPTIDGp{1}),:);
badLMTableGp{1} = testTable;
badLMDataGp{1} = badLMData(ismember(badLMPTIDs,badLMPTIDGp{1}),:);

% Group 2: Large CC generators,thick lines.
badLMPTIDGp{2} = categorical([23820,323582]);
testTable = badLMTable(ismember(badLMPTIDs,badLMPTIDGp{2}),:);
badLMTableGp{2} = testTable;
badLMDataGp{2} = badLMData(ismember(badLMPTIDs,badLMPTIDGp{2}),:);

% Group 3: Point wise,on-off small combustion turbines
testTable = badLMTable(~ismember(badLMPTIDs,union(badLMPTIDGp{1},badLMPTIDGp{2})),:);
badLMTableGp{3} = testTable;
badLMDataGp{3} = badLMData(~ismember(badLMPTIDs,union(badLMPTIDGp{1},badLMPTIDGp{2})),:);

%% Modify parameter table due to bad fitting

% Group 1: keep what we have now.
fixedBadLMTableGp = cell(3,1);
badLMInfo = badLMTableGp{1};
badLMInfo.useQM = ones(height(badLMInfo),1);
fixedBadLMTableGp{1} = badLMInfo;

% Group 2: remove abnormal heat rate data
%   Ravenswood CC 04: remove data from 8/8/2019 17:00 - 11/08/2019 9:00 (constant heat rate).
%   Astoria East Energy CC2: remove data from 06/29/2019 19:00 - 08/23/2019 1:00 (abnormally high heat input)
badLMInfo = badLMTableGp{2};
startTimeStamp = datetime(['08/08/2019 17:00:00';'06/29/2019 19:00:00'],"Format","MM/dd/uuuu HH:mm:ss");
endTimeStamp = datetime(['11/08/2019 09:00:01';'08/23/2019 01:00:00'],"Format","MM/dd/uuuu HH:mm:ss");

f = figure;
t = tiledlayout(1,2,"TileSpacing","compact");

for j=1:2
    genName = badLMInfo.NYISOName(j);
    PTID = badLMInfo.PTID(j);
    testTable = badLMDataGp{2}{j};
    testTable = testTable(~(testTable.TimeStamp >= startTimeStamp(j) & testTable.TimeStamp <= endTimeStamp(j)),:);
    
    % Fit linear model of heat rate
    genHeatLM = fitlm(testTable,"hourlyHeatInput~1+hourlyGen");
    badLMInfo.HeatRateLM_R2(j) = genHeatLM.Rsquared.Adjusted;
    badLMInfo.HeatRateLM_1(j) = genHeatLM.Coefficients.Estimate(2);
    badLMInfo.HeatRateLM_0(j) = genHeatLM.Coefficients.Estimate(1);
    testTable.HeatRateLMFit = genHeatLM.Fitted;
    
    % Fit quadratic model of heat rate
    genHeatQM = fitlm(testTable,"hourlyHeatInput ~ 1 + hourlyGen + hourlyGen^2");
    badLMInfo.HeatRateQM_R2(j) = genHeatQM.Rsquared.Adjusted;
    badLMInfo.HeatRateQM_2(j) = genHeatQM.Coefficients.Estimate(3);
    badLMInfo.HeatRateQM_1(j) = genHeatQM.Coefficients.Estimate(2);
    badLMInfo.HeatRateQM_0(j) = genHeatQM.Coefficients.Estimate(1);
    testTable.HeatRateQMFit = genHeatQM.Fitted;
    
    % Plot new fitting results
    nexttile;
    scatter(testTable.hourlyGen,testTable.hourlyHeatInput);
    hold on;
    scatter(testTable.hourlyGen,testTable.HeatRateLMFit);
    scatter(testTable.hourlyGen,testTable.HeatRateQMFit); 
    box on; hold off;
    legend(["Data","Linear","Quadratic"],"Location","best");
    title(string(PTID)+": "+string(genName));
end

xlabel(t,"Generation (MW)");
ylabel(t,"Heat input (MMBtu)");
title(t,"New regression results");
set(f,"Position",[100,100,1000,400]);

% Store it back to cell array
badLMInfo.useQM = ones(height(badLMInfo),1);
fixedBadLMTableGp{2} = badLMInfo;

% Group 3: replace it with standard linear heat rate curve
%   Set min power as zero
%   Set max hourly ramp rate as max power (instant ramp to maximum)
badLMInfo = badLMTableGp{3};
badLMInfo.minPower = zeros(height(badLMInfo),1);
badLMInfo.maxRampAgc = badLMInfo.maxPower./60;
badLMInfo.maxRamp10 = badLMInfo.maxPower./6;
badLMInfo.maxRamp30 = badLMInfo.maxPower./2;
badLMInfo.maxRamp60 = badLMInfo.maxPower;
% Heat rate data from EIA 2019
for n=1:height(badLMInfo)
    unitType = badLMInfo.UnitType(n);
    fuelType = badLMInfo.FuelType(n);
    badLMInfo.HeatRateLM_1(n) = standardHeatRate(unitType,fuelType);
end
badLMInfo.HeatRateLM_0 = zeros(height(badLMInfo),1);
badLMInfo.HeatRateLM_R2 = zeros(height(badLMInfo),1);
badLMInfo.HeatRateQM_2 = zeros(height(badLMInfo),1);
badLMInfo.HeatRateQM_1 = zeros(height(badLMInfo),1);
badLMInfo.HeatRateQM_0 = zeros(height(badLMInfo),1);
badLMInfo.HeatRateQM_R2 = zeros(height(badLMInfo),1);
% Store it back to cell array
badLMInfo.useQM = zeros(height(badLMInfo),1);
fixedBadLMTableGp{3} = badLMInfo;

%% Final version of the matched generator parameter table
goodLMTable.useQM = ones(height(goodLMTable),1);
paramMatchedFinal = [goodLMTable; fixedBadLMTableGp{1}; fixedBadLMTableGp{2}; fixedBadLMTableGp{3}];

%% Unmatched generator parameters

% Import unmatched generator data
paramUnmatched = importNotMatched(fullfile('Data','thermalGenNotMatched_2019.csv'));

% Generator data cleaning
% Exclude generators with total generation less than 0 GWh
paramUnmatched = paramUnmatched(paramUnmatched.NetEnergyGWh > 0,:);
paramUnmatched = removevars(paramUnmatched,"NetEnergyGWh");
% Exclude generators fueling on wood and refuse (renewable energy)
paramUnmatched = paramUnmatched(paramUnmatched.FuelType ~= "Wood" & paramUnmatched.FuelType ~= "Refuse",:);
% Exclude methane (Bio gas)
paramUnmatched = paramUnmatched(paramUnmatched.FuelType ~= "Methane",:);
paramUnmatched = movevars(paramUnmatched,"PTID","after","NYISOName");

% Calculate generator parameters
numNMGen = size(paramUnmatched,1);
paramUnmatched.maxPower = paramUnmatched.NamePlateRatingMW;
paramUnmatched = removevars(paramUnmatched,"NamePlateRatingMW");
paramUnmatched.minPower = zeros(numNMGen,1);
paramUnmatched.maxRampAgc = paramUnmatched.maxPower./60;
paramUnmatched.maxRamp10 = paramUnmatched.maxPower./6;
paramUnmatched.maxRamp30 = paramUnmatched.maxPower./2;
paramUnmatched.maxRamp60 = paramUnmatched.maxPower;
% paramUnmatched.HeatRateLM_1 = zeros(numNMGen,1);
for n = 1:numNMGen
    unitType = paramUnmatched.UnitType(n);
    fuelType = paramUnmatched.FuelType(n);
    paramUnmatched.HeatRateLM_1(n) = standardHeatRate(unitType,fuelType);
end
paramUnmatched.HeatRateLM_0 = zeros(numNMGen,1);
paramUnmatched.HeatRateLM_R2 = zeros(numNMGen,1);
paramUnmatched.HeatRateQM_2 = zeros(numNMGen,1);
paramUnmatched.HeatRateQM_1 = zeros(numNMGen,1);
paramUnmatched.HeatRateQM_0 = zeros(numNMGen,1);
paramUnmatched.HeatRateQM_R2 = zeros(numNMGen,1);
paramUnmatched.useQM = zeros(numNMGen,1);

%% Combine matched and unmatched generator information

genParamAll = [paramMatchedFinal; paramUnmatched];
genParamAll.useQM = logical(genParamAll.useQM);

%% Write parameter table of the matched generators

writetable(genParamAll,outfilename);
save(matfilename,'genParamAll');
fprintf("Finished writing thermal generator parameter data in %s and %s!\n",outfilename,matfilename);

else
    
    fprintf("Thermal generator parameter data already exists in %s and %s!\n",outfilename,matfilename);
    
end

end


function thermalGenNotMatched = importNotMatched(filename,dataLines)
%IMPORTFILE Import data from a text file

% If dataLines is not specified,define defaults
if nargin < 2
    dataLines = [2,Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables",21,"Encoding","UTF-8");
% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";
% Specify column names and types
opts.VariableNames = ["Var1","Var2","NYISOName","Zone","PTID","Var6","Var7",...
    "Var8","Var9","NamePlateRatingMW","Var11","Var12","Var13","Var14","Var15",...
    "UnitType","FuelType","FuelTypesecondary","NetEnergyGWh","Latitude","Longitude"];
opts.SelectedVariableNames = ["NYISOName","Zone","PTID","NamePlateRatingMW",...
    "UnitType","FuelType","NetEnergyGWh","Latitude","Longitude"];
opts.VariableTypes = ["string","string","categorical","categorical","categorical","string",...
    "string","string","string","double","string","string","string","string","string",...
    "categorical","categorical","categorical","double","double","double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Import the data
thermalGenNotMatched = readtable(filename,opts);

end
