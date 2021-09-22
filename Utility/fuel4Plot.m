function [fuelSim,fuelReal,fuelError,fuelName] = fuel4Plot(resultPF,resultGen,fuelMix,interFlow)
%FUEL4PLOT Construct matrices for plotting fuel mix

define_constants;

busIdNE = [21;29;35];
busIdIESO = [100;102;103];
busIdPJM = [124;125;132;134;138];
busIdHQ = 48;

% Real fuel mix data
thermalGen = fuelMix.GenMW(fuelMix.FuelCategory == "Dual Fuel")...
    +fuelMix.GenMW(fuelMix.FuelCategory == "Natural Gas")...
    +fuelMix.GenMW(fuelMix.FuelCategory == "Other Fossil Fuels");
nuclearGen = fuelMix.GenMW(fuelMix.FuelCategory == "Nuclear");
hydroGen = fuelMix.GenMW(fuelMix.FuelCategory == "Hydro");
importGen = sum(interFlow.FlowMWH(contains(string(interFlow.InterfaceName),"SCH")));

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
isThermal = ismember(resultPF.gentype,thermalType);
isNuclear = (resultPF.gentype == "Nuclear");
isHydro = (resultPF.gentype == "Hydro");
isImport = (resultPF.gentype == "Import");
isExtBus = ismember(resultPF.bus(:,BUS_I),[busIdNE;busIdIESO;busIdPJM;busIdHQ]);
demandExt = sum(resultPF.bus(isExtBus,PD));

fuelSim = [
    sum(resultGen(isThermal,PG));
    sum(resultGen(isNuclear,PG));
    sum(resultGen(isHydro,PG));
    sum(resultGen(isImport,PG))-demandExt];

% Fuel mix error
fuelError = (fuelSim-fuelReal)./fuelReal;

% Fuel type name
fuelName = ["Thermal";"Nuclear";"Hydro";"Import"];

end