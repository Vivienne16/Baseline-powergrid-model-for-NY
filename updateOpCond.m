function [mpcreduced,interFlow,flowLimit,fuelMix,zonalPrice] = updateOpCond(timeStamp)
%UPDATEOPERATIONCONDITION
%
%   This file should be run after the ModifyMPC.m file. The operation
%   condition of the chosen hour will be updated to the mpc 
%   Modify year month day hour for another operation condition.
%   The updated and reduced mpc struct will be saved to the Result folder.
% 
%   Inputs:
%       year, month, day, hour - testing time.
%   Outputs:
%       mpcreduced - reduced MATPOWER case file.

%   Created by Vivienne Liu, Cornell University
%   Last modified on August 17, 2021

%% Read operation condition

year = 2019; month = 12; day = 8; hour = 7;
timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");

% Read operation condition for NYS
[fuelMix,interFlow,flowLimit,nuclearCf,hydroCf,zonalPrice] = readOpCond(timeStamp);

% Allocate load and generation
loadData = allocateLoad(timeStamp);
genData = allocateGen(timeStamp);

% Read renewable generation capacity allocation table
renewableGen = importRenewableGen(fullfile("Data","RenewableGen.csv"));
busInfo = importBusInfo(fullfile("Data","npcc.csv"));

% Read updated mpc case
mpc = loadcase(fullfile("Result","mpcupdated.mat"));

% Define constants for MATPOWER
define_constants;

fprintf("Finished reading operation conditions!\n");

%% allocate hydro and nuclear generators in NY

mpcGenHydroNuclear = []; % Matrix to store hydro and nuclear gen matrix

% Renewable generation in NYISO"s fuel mix data
nuclearGen = fuelMix.GenMW(fuelMix.FuelCategory == "Nuclear");
hydroGen = fuelMix.GenMW(fuelMix.FuelCategory == "Hydro");

rmnCap = 2460; % Niagara hydropower capacity
stlCap = 856; % St. Lawrence hydropower capacity

% Total capacity and capacify factor of renewables
nuclearCapTot = sum(renewableGen.PgNuclearCap);
hydroCapTot = sum(renewableGen.PgHydroCap);
hydroCapSmall = hydroCapTot-rmnCap-stlCap; % only small hydros

count = 0; % Count number of hydro and nuclear generators

for i = 1:height(renewableGen)
    % Add nuclear generators
    if renewableGen.PgNuclearCap(i) ~= 0       
        count = count+1;
        if renewableGen.BusID(i) == 50
            % Bus 50: zone C, FitzPatrick and Nine Mile Point 1 and 2
            renewableGen.PgNuclear(i) = nuclearCf.FitzPatrickGen...
                +nuclearCf.NineMilePoint1Gen+nuclearCf.NineMilePoint2Gen;
        elseif renewableGen.BusID(i) == 74
            % Bus 74: zone H, Indian Point 2 and 3
            renewableGen.PgNuclear(i) = nuclearCf.IndianPoint2Gen...
                +nuclearCf.IndianPoint3Gen;
        else
            % Bus 53: zone B, Gina
            renewableGen.PgNuclear(i) = nuclearCf.GinnaGen;
        end     
        
        % Add a new row in the mpc.gen matrix
        newrow = zeros(1,21);
        newrow(GEN_BUS) = renewableGen.BusID(i);
        newrow(PG) = renewableGen.PgNuclear(i);
        newrow(QMAX) = 9999;
        newrow(QMIN) = -9999;
        newrow(VG) = 1;
        newrow(MBASE) = 100;
        newrow(GEN_STATUS) = 1;
        newrow(PMAX) = renewableGen.PgNuclearCap(i);
        newrow(RAMP_AGC) = 0.01*newrow(PMAX);
        newrow(RAMP_10) = 0.1*newrow(PMAX);
        newrow(RAMP_30) = 0.3*newrow(PMAX);
        mpcGenHydroNuclear = [mpcGenHydroNuclear;newrow];       
    end   
    % Add hydro generators
    if renewableGen.PgHydroCap(i) ~= 0       
        count = count +1;
        if renewableGen.BusID(i) == 55
            % Bus 55: zone A, Niagara contributes to the most variation
            renewableGen.PgHydro(i) = 0.8*hydroGen - hydroCf.stlCF*stlCap;
        elseif renewableGen.BusID(i) == 48
            % Bus 48: zone C, St. Lawrence works constantly at the monthly capacity factor
            renewableGen.PgHydro(i) = hydroCf.stlCF*stlCap;
        else
            % Other hydro across NYS contributes 20% of the total hydro
            renewableGen.PgHydro(i) = 0.2*hydroGen*(renewableGen.PgHydroCap(i)/hydroCapSmall);
        end 
        
        % Add a new row for hydro in the mpc.gen matrix
        newrow = zeros(1,21);
        newrow(GEN_BUS) = renewableGen.BusID(i);
        newrow(PG) = renewableGen.PgHydro(i);
        newrow(QMAX) = 9999;
        newrow(QMIN) = -9999;
        newrow(VG) = 1;
        newrow(MBASE) = 100;
        newrow(GEN_STATUS) = 1;
        newrow(PMAX) = renewableGen.PgHydroCap(i);
        newrow(PMIN) = 0;       
        newrow(RAMP_AGC) = 0.09*newrow(PMAX);
        newrow(RAMP_10) = 0.9*newrow(PMAX);
        newrow(RAMP_30) = newrow(PMAX);
        mpcGenHydroNuclear = [mpcGenHydroNuclear;newrow];        
    end
end

% Error in nuclear and hydro generation allocation
nuclearError = nuclearGen - sum(renewableGen.PgNuclear);
hydroError = hydroGen - sum(renewableGen.PgHydro);
fprintf("Error in nuclear generation allocation: %f MW.\n",nuclearError);
fprintf("Error in hydro generation allocation: %f MW.\n",hydroError);

fprintf("Finished allocating hydro and nuclear generators!\n");

%% allocate thermal generators in NY

% Needed thermal generation from NYISO fuel mix data
thermalGen = fuelMix.GenMW(fuelMix.FuelCategory == "Dual Fuel")...
    +fuelMix.GenMW(fuelMix.FuelCategory == "Natural Gas")...
    +fuelMix.GenMW(fuelMix.FuelCategory == "Other Fossil Fuels");

% Replace missing generation data with zero
genData = fillmissing(genData,"constant",0,"DataVariables",["hourlyGen","hourlyHeatInput"]);

% Thermal generator that matched in the RGGI database?
mpcGenThermal = zeros(height(genData),21);
mpcGenThermal(:,GEN_BUS) = genData.BusName;
mpcGenThermal(:,PG) = genData.hourlyGen;

% Allocate extra thermal generation in zone J and K
thermalGenLarge = sum(mpcGenThermal(:,PG)); % Total thermal generation from RGGI
thermalGenSmall = thermalGen-thermalGenLarge; % Mismatch between NYISO and RGGI thermal generation
busIDJK = busInfo.idx(busInfo.zone == "J" | busInfo.zone == "K");
JKidx = ismember(mpcGenThermal(:,GEN_BUS),busIDJK);
% Weight distribution of the extra thermal generation in generators with
% non-zero generation in zone J and K
mpcGenThermal(JKidx,PG) = mpcGenThermal(JKidx,PG)+...
    (mpcGenThermal(JKidx,PG)~=0).*thermalGenSmall.*(mpcGenThermal(JKidx,PG)./sum(mpcGenThermal(JKidx,PG)));

mpcGenThermal(:,QMAX) = 9999;
mpcGenThermal(:,QMIN) = -9999;
mpcGenThermal(:,VG) = 1.0;
mpcGenThermal(:,MBASE) = 100;
mpcGenThermal(:,GEN_STATUS) = 1;
mpcGenThermal(:,PMAX) = genData.maxPower;
mpcGenThermal(:,PMIN) = genData.minPower;
mpcGenThermal(:,RAMP_AGC) = genData.maxRampAgc;
mpcGenThermal(:,RAMP_10) = genData.maxRamp10;
mpcGenThermal(:,RAMP_30) = genData.maxRamp30;

fprintf("Finished allocating thermal generators!\n");

%% calculate external flow below

flowPJM2NY = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - PJ - NY")+...
    interFlow.FlowMWH(interFlow.InterfaceName == "SCH - PJM_HTP")+...
    interFlow.FlowMWH(interFlow.InterfaceName == "SCH - PJM_NEPTUNE")+...
    interFlow.FlowMWH(interFlow.InterfaceName == "SCH - PJM_VFT");
flowHQ2NY = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - HQ - NY")+...
    interFlow.FlowMWH(interFlow.InterfaceName == "SCH - HQ_CEDARS");
flowNE2NY = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - NE - NY")+...
    interFlow.FlowMWH(interFlow.InterfaceName == "SCH - NPX_1385")+...
    interFlow.FlowMWH(interFlow.InterfaceName == "SCH - NPX_CSC");
flowIESO2NY = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - OH - NY");
flowNeptune = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - PJM_NEPTUNE");
flowHTP = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - PJM_HTP");
flowNPX1385 = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - NPX_1385");
flowCSC = interFlow.FlowMWH(interFlow.InterfaceName == "SCH - NPX_CSC");

fprintf("Finished calculating interface flow!\n");

%% update load in NY

NYloadOld = sum(mpc.bus(37:82,PD)); % Total load in old NPCC-140 case in NY
NYLoadTot = sum(loadData.PD); % Total hourly load in NYISO
NYLoadRatio = NYLoadTot/NYloadOld;

mpc.bus(37:82,PD) = loadData.PD;
mpc.bus(37:82,QD) = loadData.QD; 

fprintf("Finished updating load in NY!\n");

%% Add wind and other renewables as negative load

windGen = fuelMix.GenMW(fuelMix.FuelCategory == "Wind");
otherGen = fuelMix.GenMW(fuelMix.FuelCategory == "Other Renewables");
windCapTot = sum(renewableGen.PgWindCap);
otherCapTot = sum(renewableGen.PgOtherCap);
windCfTot = windGen/windCapTot;
otherCfTot = otherGen/otherCapTot;

for i = 1:height(renewableGen)
    if renewableGen.PgWindCap(i) ~= 0
        mpc.bus(renewableGen.BusID(i),PD) = mpc.bus(renewableGen.BusID(i),PD)...
            - windCfTot*renewableGen.PgWindCap(i);
    end
    if renewableGen.PgOtherCap(i) ~= 0
        mpc.bus(renewableGen.BusID(i),PD) = mpc.bus(renewableGen.BusID(i),PD)...
            - otherCfTot*renewableGen.PgOtherCap(i);
    end
end

fprintf("Finished allocating wind and other renewables in NY!\n");

%% scale up load and generation for external area

busIDNE = busInfo.idx(busInfo.area == 1);
isNEGen = ismember(mpc.gen(:,GEN_BUS),busIDNE);
% Total load and generation in NE in the original NPCC-140 case
NELoadOld = sum(mpc.bus(busIDNE,PD));
NEGenOld = sum(mpc.gen(isNEGen,PG));
% Scale up NE load with the same ratio in NY
NELoadRatio = NYLoadRatio;
mpc.bus(busIDNE,PD) = mpc.bus(busIDNE,PD)*NELoadRatio;
% Scale up NE generator with scaled load and interface flow data 
NEGenRatio = (NELoadOld*NELoadRatio+flowNE2NY)/NEGenOld;
mpc.gen(isNEGen,PG) = mpc.gen(isNEGen,PG)*NEGenRatio;

busIDIESO = busInfo.idx(busInfo.area == 4);
isIESOGen = ismember(mpc.gen(:,GEN_BUS),busIDIESO);
% Total load and geneartion in IESO in the original NPCC-140 case
IESOLoadOld = sum(mpc.bus(busIDIESO,PD));
IESOGenOld = sum(mpc.gen(isIESOGen,PG));
% Scale up IESO load with the same ratio in NY
IESOLoadRatio = NYLoadRatio;
mpc.bus(busIDIESO,PD) = mpc.bus(busIDIESO,PD)*IESOLoadRatio;
% Scale up IESO generator with scaled laod and interface flow data
IESOGenRatio = (IESOLoadOld*IESOLoadRatio+flowIESO2NY)/IESOGenOld;
mpc.gen(isIESOGen,PG) = mpc.gen(isIESOGen,2) * IESOGenRatio;

busIDPJM = busInfo.idx(busInfo.area == 5 | busInfo.area == 6);
isPJMGen = ismember(mpc.gen(:,GEN_BUS),busIDPJM);
% Total load and generation in PJM in the original NPCC-140 case
PJMLoadOld = sum(mpc.bus(busIDPJM,PD));
PJMGenOld = sum(mpc.gen(isPJMGen,PG));
% Scale up PJM load with the same load in NY
PJMLoadRatio = NYLoadRatio;
mpc.bus(busIDPJM,PD) = mpc.bus(busIDPJM,PD)*PJMLoadRatio;
% Scale up PJM generation with scaled load and interface flow data
PJMGenRatio = (PJMLoadOld*PJMLoadRatio+flowPJM2NY)/PJMGenOld;
mpc.gen(isPJMGen,PG) = mpc.gen(isPJMGen,PG) * PJMGenRatio;

mpcGenExt = mpc.gen(isNEGen|isIESOGen|isPJMGen, :);
% Set negative minimum generation to zero
mpcGenExt(mpcGenExt(:,PMIN)<0,PMIN) = 0;
% Set maximum generation with 9999
mpcGenExt(:,PMAX) = mpcGenExt(:,PG)*1.5;
mpcGenExt(:,RAMP_10) = mpcGenExt(:,PMAX)/20;
mpcGenExt(:,RAMP_30) = mpcGenExt(:,RAMP_10)*3;
mpcGenExt(:,RAMP_AGC) = mpcGenExt(:,RAMP_10)/10;
mpcGenExt(:,PMIN) = 0;

% Add generator for HQ
HQGen = zeros(1,21);
HQGen(GEN_BUS) = 48;
HQGen(PG) = flowHQ2NY;
HQGen(QMAX) = 9999;
HQGen(QMIN) = -9999;
HQGen(VG) = 1;
HQGen(MBASE) = 100;
HQGen(GEN_STATUS) = 1;
% Positive and negative interface flow limit from HQ to NY
HQGen(PMAX) = flowLimit.PositiveLimitMWH(flowLimit.InterfaceName == "SCH - HQ - NY")+...
    flowLimit.PositiveLimitMWH(flowLimit.InterfaceName == "SCH - HQ_CEDARS");
HQGen(PMIN) = flowLimit.NegativeLimitMWH(flowLimit.InterfaceName == "SCH - HQ - NY")+...
    flowLimit.NegativeLimitMWH(flowLimit.InterfaceName == "SCH - HQ_CEDARS");

mpc.gen = [mpcGenThermal;mpcGenHydroNuclear;mpcGenExt;HQGen];

fprintf("Finished updating external load and generation!\n");

%% Equivelent Reduction
% Define external buses
%%%% Change this to data reading instead of hard coded 
Exbus = [1:20,22:28,30:34,36,83:99,101,104:123,126:131,133,135:137,139:140];
% Perform network reduction algorithm
pf_flag = 1; % Solve dc power flow
[mpcreduced,~,~] = MPReduction(mpc,Exbus,pf_flag);

fprintf("Finished calculating network reduction!\n");

%% add HVDC lines 
%	fbus	tbus	status	Pf	Pt	Qf	Qt	Vf	Vt	Pmin	Pmax	QminF	QmaxF	QminT	QmaxT	loss0	loss1
mpcreduced.dcline = [
	21 80	1	flowNPX1385+flowCSC	0	0	0	1.01	1	-530	530	-100    100	-100	100	0	0;
	124 79	1	flowNeptune     0	0	0	1.01	1	-660	660	-100	100	-100	100	0	0;
    125 81	1	flowHTP         0	0	0	1.01	1	-660	660	-100	100	-100	100	0	0;
];
mpcreduced = toggle_dcline(mpcreduced, "on");

fprintf("Finished adding DC lines!\n");

%% add interface flow limit
mpcreduced.if.map = [
	1   -32;	%% 1 : A - B
	1	34;
    1   37;
    1   47;
	2	-28;	%% 2 : B - C
	2	-29;
	2	33;
	2	50;
	3	-16;	%% 3 : C - E
	3	-20;
	3	-21;
	3	56;
    3   -62;
	4	-24;    %% 4 : D - E
	4	-18;
    4   -23;
    5   -14;    %% 5 : E - F
    5   -12;
    5   -3;
    5   -6;    	
    6   8;      %% 6 : E - G
    7   4;      %% 7 : F - G
    8   65;     %% 8 : G - H
    8   -66
    9   67;     %% 9 : H - I
    10  73;     %% 10 : I - J
    10  74; 
    11  71;     %% 11 : I - K
    11  72
];
A_B = flowLimit(flowLimit.InterfaceName == "DYSINGER EAST",:);
B_C = flowLimit(flowLimit.InterfaceName == "WEST CENTRAL",:);
C_E = flowLimit(flowLimit.InterfaceName == "TOTAL EAST",:);
D_E = flowLimit(flowLimit.InterfaceName == "MOSES SOUTH",:);
E_F = flowLimit(flowLimit.InterfaceName == "CENTRAL EAST - VC",:);
G_H = flowLimit(flowLimit.InterfaceName == "UPNY CONED",:);
I_J = flowLimit(flowLimit.InterfaceName == "SPR/DUN-SOUTH",:);
mpcreduced.if.lims = [
	1	A_B.NegativeLimitMWH	A_B.PositiveLimitMWH;	%% 1 : A - B
    2	B_C.NegativeLimitMWH	B_C.PositiveLimitMWH;	%% 2 : B - C
    3   C_E.NegativeLimitMWH    C_E.PositiveLimitMWH;  %% 3 : C - E
    4   D_E.NegativeLimitMWH   D_E.PositiveLimitMWH;   %% 4 : D - E
    5   E_F.NegativeLimitMWH E_F.PositiveLimitMWH;       %% 5 : E - F
    6   -1600  5650-E_F.PositiveLimitMWH ;   %% 6 : E - G
    7   -5400   5400;   %% 7 : F - G
    8   G_H.NegativeLimitMWH   G_H.PositiveLimitMWH;   %% 8 : G - H
    9   -8450   8450;   %% 9 : H - I
    10  -4350    4350;   %% 10 : I - K
    11  -515    1290;   %% 10 : I - K
];

fprintf("Finished setting interface flow limits!\n");

%% add gencost

% cost curve for thermal generators in NY
NYgenthermalcost = zeros(227,6);
NYgenthermalcost(:,MODEL) = 2; % Polynomial cost function
NYgenthermalcost(:,NCOST) = 2; % Linear cost curve
NYgenthermalcost(:, COST) = genData.cost_1;
NYgenthermalcost(:, COST+1) = genData.cost_0;

% cost curve for hydro and nuclear generators in NY
hynucost = zeros(12,6);
hynucost(:,MODEL) = 2;
hynucost(:,NCOST) = 2;
count = 0;
for i = 1:height(renewableGen)
    if renewableGen.PgNuclearCap(i) ~= 0
        count = count+1;
        % Randomly assign cost for $1-3/MWh
        hynucost(count,COST) = 1+2*rand(1);
    end
    if renewableGen.PgHydroCap(i) ~= 0
        count = count +1;
        % Randomly assign cost for $0-10/MWh
        hynucost(count,COST) = 10*rand(1);
    end
end

% Cost curve for external generators
PJMprice = zonalPrice.LBMP(zonalPrice.ZoneName == "PJM");
NEprice = zonalPrice.LBMP(zonalPrice.ZoneName == "NPX");
IESOprice = zonalPrice.LBMP(zonalPrice.ZoneName == "O H");
HQprice = zonalPrice.LBMP(zonalPrice.ZoneName == "H Q");

exgencostthermal = zeros(28,6);
exgencostthermal(:,MODEL) = 2;
exgencostthermal(:,NCOST) = 2;
offset = 12+227; % 227 thermal generators and 12 hydro and nuclear generators

%%%% Use external price as constant cost?
for i = 1:length(mpcreduced.gen(offset+1:offset+28,1))
    if mpcreduced.gen(offset+i,GEN_BUS) <=35
        exgencostthermal(i,COST) = NEprice;       
    elseif mpcreduced.gen(offset+i,GEN_BUS) >=83 && mpcreduced.gen(offset+i,GEN_BUS)<= 113
        exgencostthermal(i,COST) = IESOprice;
    elseif mpcreduced.gen(offset+i,GEN_BUS)>113
        exgencostthermal(i,COST) = PJMprice;
    else
        exgencostthermal(i,COST) = HQprice;
    end
end

% add gencost to mpc
gencost = [NYgenthermalcost;hynucost;exgencostthermal];
mpcreduced.gencost = gencost;

fprintf("Finished adding generation cost matrix!\n");

%% Save updated operation condtion

savecase('mpcreduced.mat',mpcreduced);

fprintf("Update operation condition complete!\n");

end