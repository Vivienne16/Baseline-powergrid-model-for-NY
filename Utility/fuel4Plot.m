function [fuelSim,fuelReal,fuelError,fuelName] = fuel4Plot(result,fuelMix,interFlow,addrenew)
%FUEL4PLOT Construct matrices for plotting fuel mix

define_constants;

busIdNE = [21;29;35];
busIdIESO = [100;102;103];
busIdPJM = [124;125;132;134;138];

resultGen = result.gen;

% Real fuel mix data
thermalGen = fuelMix.GenMW(fuelMix.FuelCategory == "Dual Fuel")...
    +fuelMix.GenMW(fuelMix.FuelCategory == "Natural Gas")...
    +fuelMix.GenMW(fuelMix.FuelCategory == "Other Fossil Fuels");
nuclearGen = fuelMix.GenMW(fuelMix.FuelCategory == "Nuclear");
hydroGen = fuelMix.GenMW(fuelMix.FuelCategory == "Hydro");
importGen = sum(interFlow.FlowMWH(contains(string(interFlow.InterfaceName),"SCH")));
HQGen = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - HQ_IMPORT_EXPORT");
importGen = importGen - HQGen;

fuelReal = [
    thermalGen;
    nuclearGen;
    hydroGen;
    importGen];

% Simulated fuel mix data
thermalType = [
    "Combined Cycle";
    "Combustion Turbine";
    "Internal Combustion";
    "Jet Engine";
    "Steam Turbine"];
isThermal = ismember(result.genfuel,thermalType);
isNuclear = (result.genfuel == "Nuclear");
isHydro = (result.genfuel == "Hydro");
isImport = (result.genfuel == "Import");
isExtBus = ismember(result.bus(:,BUS_I),[busIdNE;busIdIESO;busIdPJM]);
demandExt = sum(result.bus(isExtBus,PD));


fuelSim = [
    sum(resultGen(isThermal,PG));
    sum(resultGen(isNuclear,PG));
    sum(resultGen(isHydro,PG));
    sum(resultGen(isImport,PG))-demandExt
    ];

% Fuel type name
fuelName = ["Thermal";"Nuclear";"Hydro";"Import"];

if addrenew
    isSolar = (result.genfuel == "Solar");
    isWind = (result.genfuel == "Wind"); 
    fuelReal = [fuelReal; 0; 0];
    fuelSim = [fuelSim;
        sum(resultGen(isSolar,PG));
        sum(resultGen(isWind,PG))];
    fuelName = [fuelName; "Solar"; "Wind"];
end

% Fuel mix error
fuelError = (fuelSim-fuelReal)./fuelReal;

end