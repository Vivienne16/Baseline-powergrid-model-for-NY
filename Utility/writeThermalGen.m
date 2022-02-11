function writeThermalGen(testyear)
%WRITETHERMALGEN write NYISO hourly thermal generation data

%   Created by Bo Yuan, Cornell University
%   Last modified on Feb 7, 2022

%% Input handling
if isempty(testyear)
    testyear = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','thermalGenHourly_'+string(testyear)+'.csv');
matfilename = fullfile('Data','thermalGenHourly_'+string(testyear)+'.mat');

if ~isfile(outfilename) || ~isfile(matfilename)% File doesn't exist
    %% Download hourly generation data
    downloadData(testyear,'rtgen');
    
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
    
    %% Combine the RGGI database with the NYCA database
    genLargeJoint = outerjoin(genLarge,genCombiner,"Keys",["FacilityID","UnitID"],"Type","Right",...
        "LeftVariables",["TimeStamp","FacilityName","FacilityID","UnitID","GrossLoadMW","HeatInputMMBtu"],...
        "RightVariables",["NYISOName","PTID","Zone","UnitType","FuelType","Combined"]);

    %% Calculate hourly generation of each thermal generator (PTID)
    hourlyGenLarge = groupsummary(genLargeJoint,["TimeStamp","NYISOName","PTID"],"sum",["GrossLoadMW","HeatInputMMBtu"]);
    hourlyGenLarge.Properties.VariableNames(end-1:end) = ["hourlyGen","hourlyHeatInput"];
    hourlyGenLarge = removevars(hourlyGenLarge,"GroupCount");

    % Save hourly generation data
    writetable(hourlyGenLarge,outfilename);
    save(matfilename,'hourlyGenLarge');
    fprintf("Finished writing thermal generation data in %s and %s\n",outfilename,matfilename);

else
    
    fprintf("Hourly generation data already exists in %s and %s!\n",outfilename,matfilename);
     
end
end