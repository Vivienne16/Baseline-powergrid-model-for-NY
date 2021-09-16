function [mpcreduced,interFlow,flowLimit,fuelMix,zonalPrice] = updateOpCond(year,month,day,hour)
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
year = 2019; month = 1; day = 1; hour = 12;
timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");

% Read operation condition for NYS
[fuelMix,interFlow,flowLimit,nuclearCf,hydroCf,zonalPrice] = readOpCond(timeStamp);

% Read renewable generation capacity allocation table
renewableGen = importRenewableGen(fullfile('Data','RenewableGen.csv'));
businfo = importBusInfo(fullfile('Data','npcc.csv'));

% Read updated mpc case
mpc = loadcase(fullfile('Result','mpcupdated.mat'));

% Allocate load and generation data
loadData = allocateLoadHourly(year,month,day,hour);
genData = allocateGenHourly(year,month,day,hour);

define_constants;

%% allocate hydro and nuclear generators in NY
hydroNuclearGen = []; % Matrix to store hydro and nuclear gen matrix

% Renewable generation in NYISO's fuel mix data
nuclearGen = fuelMix.GenMW(fuelMix.FuelCategory == 'Nuclear');
hydroGen = fuelMix.GenMW(fuelMix.FuelCategory == 'Hydro');
windGen = fuelMix.GenMW(fuelMix.FuelCategory == 'Wind');
otherGen = fuelMix.GenMW(fuelMix.FuelCategory == 'Other Renewables');

% rmnCap = 2435; % Niagara hydropower capacity
% stlCap = 856; % St. Lawrence hydropower capacity
% FitzPatrickCap = 854.5;
% NineMilePoint1Cap = 629;
% NineMilePoint2Cap = 1299;
% IndianPoint2Cap = 1025.9;
% IndianPoint3Cap = 1039.9;
% GinnaCap = 581.7;

% Total capacity and capacify factor of renewables
nuclearCapSum = sum(renewableGen.PgNuclearCap);
% rNuclearGen =  nuclearGen/nuclearCapSum;
hydroCapSum = sum(renewableGen.PgHydroCap)-rmnCap-stlCap; % only small hydros
% rHydro =  hydroGen/hydroCapSum;
windCapSum = sum(renewableGen.PgWindCap);
otherCapSum = sum(renewableGen.otherRenewable);

count = 0;

% % STL monthly capacity factor: constant output in a month
% STL = [91.33 94.83 101.12 95.47 99.21 109.84 107.61 109.99 109.76 100.53 104.91 104.56];
% STL = STL/100;

NuclearGen = 0; % Total nuclear generation
HydroGen = 0; % Total hydro generation

for i = 1:height(renewableGen)
    %   Add nuclear generators
    if renewableGen.PgNuclearCap(i) ~= 0       
        count = count+1;
        if renewableGen.bus_id(i) == 50
            % Bus 50: zone C, FitzPatrick and Nine Mile Point 1 and 2
            renewableGen.PgNuclear(i) = nuclearCf.FitzPatrick/100*FitzPatrickCap...
                +nuclearCf.NineMilePoint1/100*NineMilePoint1Cap...
                +nuclearCf.NineMilePoint2/100*NineMilePoint2Cap;
        elseif renewableGen.bus_id(i) == 74
            % Bus 74: zone H, Indian Point 2 and 3
            renewableGen.PgNuclear(i) = nuclearCf.IndianPoint2/100*IndianPoint2Cap...
                +nuclearCf.IndianPoint3/100*IndianPoint3Cap;
        else
            % Bus 53: zone B, Gina
            renewableGen.PgNuclear(i) = nuclearCf.Ginna/100*GinnaCap;
        end
        % Calculate total nuclear generation
        NuclearGen = NuclearGen + renewableGen.PgNuclear(i);        
        % Add a new row in the mpc.gen matrix
        newrow = zeros(1,21);
        newrow(GEN_BUS) = renewableGen.bus_id(i);
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
        hydroNuclearGen = [hydroNuclearGen;newrow];
        
        % Add a new row to the mpc.gencost matrix
        % Nuclear gen cost varying in $1-3/MWh
        % hynucost(count,COST) = 1+2*rand(1);        
    end   
    %   Add hydro generators
    if renewableGen.PgHydroCap(i) ~= 0       
        count = count +1;
        if renewableGen.bus_id(i) == 55
            % Bus 55: zone A, Niagara contributes to the most variation
            renewableGen.PgHydro(i) = hydroGen - hydroCf.stlCF*stlCap-0.2*hydroGen;
        elseif renewableGen.bus_id(i) == 48
            % Bus 48: zone C, St. Lawrence works constantly at the monthly capacity factor
            renewableGen.PgHydro(i) = hydroCf.stlCF*renewableGen.PgHydroCap(i);
        else
            % Other hydro across NYS contributes 20% of the total hydro
            renewableGen.PgHydro(i) = 0.2*hydroGen/hydroCapSum*renewableGen.PgHydroCap(i);
        end 
        HydroGen = HydroGen + renewableGen.PgHydro(i);
        % Add a new row for hydro in the mpc.gen matrix
        newrow = zeros(1,21);
        newrow(GEN_BUS) = renewableGen.bus_id(i);
        newrow(PG) = renewableGen.PgHydro(i);
        newrow(QMAX) = 9999;
        newrow(QMIN) = -9999;
        newrow(VG) = 1;
        newrow(MBASE) = 100;
        newrow(GEN_STATUS) = 1;
        newrow(PMAX) = renewableGen.PgHydroCap(i);
        newrow(PMIN) = 0;       
        newrow(RAMP_AGC) = 0.09*newrow(9);
        newrow(RAMP_10) = 0.9*newrow(9);
        newrow(RAMP_30) = newrow(9);
        hydroNuclearGen = [hydroNuclearGen;newrow];
        
        % Add a new row to the mpc.gencost matrix
        % Hydro gen cost varying in $20-30/MWh?
        %%%% Duplicated gencost matrix definition?
        % hynucost(count,COST) = 20+10*rand(1);        
    end
end

fprintf("Finished allocating hydro and nuclear generators!\n");

%% allocate thermal generators in NY
demand = [loadData.busIdx loadData.PD];
totalloadny = sum(loadData.PD); % Total hourly load in NYISO
totalgen = sum(fuelMix.mean_GenMW); % Total hourly generation in NYISO
% Needed thermal generation from NYISO fuel mix data
thermalneed = totalgen-sum(hydroNuclearGen(:,PG))-windGen-otherGen;
% gendata.BusName = str2num(char(gendata.BusName));
% Replace missing generation data with zero?
genData{:,12:13}(isnan(genData{:,12:13})) = 0;
% gendata = fillmissing(gendata,'constant',0,'DataVariables',{'hourlyGen','hourlyHeatInput'});

% Thermal generator that matched in the RGGI database?
thegen = zeros(height(genData),21);
thegen(:,GEN_BUS) = genData.BusName;
thegen(:,PG) = genData.hourlyGen;
totalthermal = sum(thegen(:,PG)); % Total thermal generation from RGGI

% Allocate extra thermal generation in zone J and K
thermaldiff = thermalneed-totalthermal; % Mismatch between NYISO and RGGI thermal generation
JK = [79 80,81,82];
JKidx = find(ismember(thegen(:,1),JK)==1);
% Weight distribution of the extra thermal generation in generators with
% non-zero generation in zone J and K
thegen(JKidx,PG) = thegen(JKidx,PG)+(thegen(JKidx,PG)~=0).*thermaldiff.*thegen(JKidx,PG)./sum(thegen(JKidx,PG));

thegen(:,QMAX) = 9999;
thegen(:,QMIN) = -9999;
thegen(:,VG) = 1.0;
thegen(:,MBASE) = 100;
thegen(:,GEN_STATUS) = 1;
thegen(:,PMAX) = genData.maxPower;
thegen(:,PMIN) = genData.minPower;
thegen(:,RAMP_AGC) = genData.maxRampAgc;
thegen(:,RAMP_10) = genData.maxRamp10;
thegen(:,RAMP_30) = genData.maxRamp30;
updatedgen = [thegen;hydroNuclearGen];
totalgenny = sum(updatedgen(:,PG));
ThermalGen = sum(thegen(:,PG)); % Final thermal generation

% Generators in external region
exgen = [];
for i = 1:length(mpc.gen)
    if mpc.gen(i,GEN_BUS)<37 || mpc.gen(i,GEN_BUS)>82
        exgen = [exgen;mpc.gen(i,:)];
    end
end

fprintf("Finished allocating thermal generators!\n");

%% calculate external flow below
exLoadTotal = sum(mpc.bus(1:36,PD))+sum(mpc.bus(83:end,PD));
exGenTotal = sum(exgen(:,PG));

PJM2NY = interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - PJ - NY')+...
    interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - PJM_HTP')+...
    interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - PJM_NEPTUNE')+...
    interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - PJM_VFT');
HQ2NY = interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - HQ - NY')+...
    interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - HQ_CEDARS');
NE2NY = interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - NE - NY')+...
    interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - NPX_1385')+...
    interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - NPX_CSC');
IESO2NY = interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - OH - NY');
Neptune = interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - PJM_NEPTUNE');
HTP = interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - PJM_HTP');
NPX1385 = interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - NPX_1385');
CSC = interFlow.mean_FlowMWH(string(interFlow.InterfaceName) == 'SCH - NPX_CSC');
 
% Region
Zonalinfo = table2array(businfo(:,[2,12]));
% Total load in original NPCC-140 case in NY
NYload = sum(mpc.bus(37:82,PD));

%% update load in NY
mpc.bus(37:82,PD) = loadData.PD;
mpc.bus(37:82,QD) = loadData.QD; 

%% Add wind and other renewables as negative load
% Wind
for i = 1:height(renewableGen)
    if renewableGen.windCap(i) ~= 0
        windratio = windGen/windCapSum; % Wind capacity factor in NY
        mpc.bus(renewableGen.bus_id(i),PD) = mpc.bus(renewableGen.bus_id(i),PD) - windratio*renewableGen.windCap(i);
    end
end

% Other renewables
for i = 1:height(renewableGen)
    if renewableGen.otherRenewable(i) ~= 0
        ORratio = otherGen/otherCapSum;
        mpc.bus(renewableGen.bus_id(i),PD) = mpc.bus(renewableGen.bus_id(i),PD) - ORratio*renewableGen.otherRenewable(i);
    end
end

% Ratio of updated load over original NPCC-140 load in NY
NYLoadRatio = sum(mpc.bus(37:82,PD))/NYload;
%%%% Should the load ratio be calculated before adding renewables as
%%%% negative load?

fprintf("Finished allocating wind and other renewables in NY!\n");

%% scale up load and generation for external area
%%%% Rewrite this part to functions

idxNE = Zonalinfo(Zonalinfo(:,2) == 1,1);
isNEGen = ismember(mpc.gen(:,GEN_BUS),idxNE);
% Total load and generation in NE in the original NPCC-140 case
NELoad = sum(mpc.bus(idxNE,PD));
NEgen = sum(mpc.gen(isNEGen,PG));
% Scale up NE load with the same ratio in NY
NELoadRatio = NYLoadRatio;
mpc.bus(idxNE,PD) = mpc.bus(idxNE,PD)*NELoadRatio;
% Scale up NE generator with scaled load and interface flow data 
NEGenRatio = (NELoad*NELoadRatio+NE2NY)/NEgen;
mpc.gen(isNEGen,PG) = mpc.gen(isNEGen,PG)*NEGenRatio;

idxIESO = Zonalinfo(Zonalinfo(:,2) == 4,1);
isIESOGen = ismember(mpc.gen(:,GEN_BUS),idxIESO);
% Total load and geneartion in IESO in the original NPCC-140 case
IESOload = sum(mpc.bus(idxIESO,PD));
IESOgen = sum(mpc.gen(isIESOGen,PG));
% Scale up IESO load with the same ratio in NY
IESOLoadRatio = NYLoadRatio;
mpc.bus(idxIESO,PD) = mpc.bus(idxIESO,PD)*IESOLoadRatio;
% Scale up IESO generator with scaled laod and interface flow data
IESOGenRatio = (IESOload*IESOLoadRatio+IESO2NY)/IESOgen;
mpc.gen(isIESOGen,PG) = mpc.gen(isIESOGen,2) * IESOGenRatio;

idxPJM = Zonalinfo(Zonalinfo(:,2) == 5 | Zonalinfo(:,2) == 6,1);
isPJMGen = ismember(mpc.gen(:,GEN_BUS),idxPJM);
% Total load and generation in PJM in the original NPCC-140 case
PJMload = sum(mpc.bus(idxPJM,PD));
PJMgen = sum(mpc.gen(isPJMGen,PG));
% Scale up PJM load with the same load in NY
PJMLoadRatio = NYLoadRatio;
mpc.bus(idxPJM,PD) = mpc.bus(idxPJM,PD)*PJMLoadRatio;
% Scale up PJM generation with scaled load and interface flow data
PJMGenRatio = (PJMload*PJMLoadRatio+PJM2NY)/PJMgen;
mpc.gen(isPJMGen,PG) = mpc.gen(isPJMGen,PG) * PJMGenRatio;

externalGen = mpc.gen(isNEGen|isIESOGen|isPJMGen, :);
updatedgen = [updatedgen; externalGen];

fprintf("Finished updating external load and generation!\n");

%% Add generator for HQ
HQgen = zeros(1,21);
HQgen(GEN_BUS) = 48;
HQgen(PG) = HQ2NY;
HQgen(QMAX) = 9999;
HQgen(QMIN) = -9999;
HQgen(VG) = 1;
HQgen(MBASE) = 100;
HQgen(GEN_STATUS) = 1;
% Positive and negative interface flow limit from HQ to NY
HQgen(PMAX) = flowLimit.mean_PositiveLimitMWH(string(flowLimit.InterfaceName) == 'SCH - HQ - NY')+...
    flowLimit.mean_PositiveLimitMWH(string(flowLimit.InterfaceName) == 'SCH - HQ_CEDARS');
HQgen(PMIN) = flowLimit.mean_NegativeLimitMWH(string(flowLimit.InterfaceName) == 'SCH - HQ - NY')+...
    flowLimit.mean_NegativeLimitMWH(string(flowLimit.InterfaceName) == 'SCH - HQ_CEDARS');

updatedgen = [updatedgen; HQgen];
mpc.gen = updatedgen;

%% external modification for generators
exidx = mpc.gen(:,PMAX)==9999;
% Set negative minimum generation to zero
mpc.gen(mpc.gen(:,PMIN)<0,PMIN) = 0;
% Set maximum generation with 9999
mpc.gen(exidx,PMAX) = mpc.gen(exidx,PG)*1.5;
mpc.gen(exidx,RAMP_10) = mpc.gen(exidx,PMAX)/20;
mpc.gen(exidx,RAMP_30) = mpc.gen(exidx,RAMP_10)*3;
mpc.gen(exidx,RAMP_AGC) = mpc.gen(exidx,RAMP_10)/10;
mpc.gen(:,PMIN) = 0;

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
	21 80	1	NPX1385+CSC	0	0	0	1.01	1	-530	530	-100    100	-100	100	0	0;
	124 79	1	Neptune     0	0	0	1.01	1	-660	660	-100	100	-100	100	0	0;
    125 81	1	HTP         0	0	0	1.01	1	-660	660	-100	100	-100	100	0	0;
];
mpcreduced = toggle_dcline(mpcreduced, 'on');

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
A_B = flowLimit(flowLimit.InterfaceName == 'DYSINGER EAST',:);
B_C = flowLimit(flowLimit.InterfaceName == 'WEST CENTRAL',:);
C_E = flowLimit(flowLimit.InterfaceName == 'TOTAL EAST',:);
D_E = flowLimit(flowLimit.InterfaceName == 'MOSES SOUTH',:);
E_F = flowLimit(flowLimit.InterfaceName == 'CENTRAL EAST - VC',:);
G_H = flowLimit(flowLimit.InterfaceName == 'UPNY CONED',:);
I_J = flowLimit(flowLimit.InterfaceName == 'SPR/DUN-SOUTH',:);
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
PJMprice = zonalPrice.LBMP(zonalPrice.ZoneName == 'PJM');
NEprice = zonalPrice.LBMP(zonalPrice.ZoneName == 'NPX');
IESOprice = zonalPrice.LBMP(zonalPrice.ZoneName == 'O H');
HQprice = zonalPrice.LBMP(zonalPrice.ZoneName == 'H Q');

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
savecase('Result/mpcreduced.mat',mpcreduced);

fprintf("Update operation condition complete!\n");

end