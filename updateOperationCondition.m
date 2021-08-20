function mpcreduced = updateOperationCondition(year,month,day,hour)
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

%% Input parameters
year = 2019;
month = 1;
day = 1;
hour = 1;

% TimeStamp = datetime(year,month,date,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");

Fuelmix = readtable('Data/Fuelmix.csv');
InterFlow = readtable('Data/InterFlow.csv');
RenewableGen = importRenewableGen('Data/RenewableGen.csv');
nuclearTable = readtable('Data/NuclearFactor.csv');
Businfo = readtable('Data/npcc.xlsx','Sheet','Bus');
NYRTMprice = readtable('Data/NYRTMprice.csv');
mpc = loadcase('Result/mpcupdated.mat');

define_constants;

loaddata = allocateLoadHourly(year,month,day,hour,'RTM','weighted');
gendata = allocateGenHourly(year,month,day,hour);

fuelsum = Fuelmix(Fuelmix.hour ==hour&Fuelmix.day==day&Fuelmix.month==month,:);
if isempty(fuelsum)
    disp('Data missing for Fuel mix')
end
interflow = InterFlow(InterFlow.hour == hour&InterFlow.day==day&InterFlow.month==month,:);
flowlimit = interflow(:,{'InterfaceName','mean_PositiveLimitMWH','mean_NegativeLimitMWH'});
interflow = interflow(:,{'InterfaceName','mean_FlowMWH'});
if isempty(flowlimit)
    disp('Data missing for interface flow')
end

%% allocate hydro and nuclear generators in NY
% RenewableGen = table2array(RenewableGen(:,[1,4:end]));
% RenewableGen(isnan(RenewableGen))=0;
hyNuGen = []; % Matrix to store hydro and nuclear gen matrix
hyNugencost = []; % Matrix to store hydro and nuclear gencost matrix

% Renewable generation in NYISO's fuel mix data
NuGen = fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Nuclear');
HyGen = fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Hydro');
windGen = fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Wind');
ORGen = fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Other Renewables');

% Total capacity and capacify factor of renewables
CapNuclear = sum(RenewableGen.PgNuclearCap);
rNugen =  NuGen/CapNuclear;
CapHydro = sum(RenewableGen.PgWaterCap)-2460-856;
rHydro =  HyGen/CapHydro;
windCap = sum(RenewableGen.windCap);
ORCap = sum(RenewableGen.otherRenewable);

count = 0;

% Daily nuclear capacity factor 
nufactor = nuclearTable(nuclearTable.day==day&nuclearTable.month==month,:);
% STL monthly capacity factor: constant output in a month
%%%% Change the hard coded capacity factor to file data reading, also
%%%% include data source api downloading script in the Prep dir
%%%% How could capacity factor be larger than 100%?
STL = [91.33 94.83 101.12 95.47 99.21 109.84 107.61 109.99 109.76 100.53 104.91 104.56];
STL = STL/100;

NuclearGen = 0; % Total nuclear generation
HydroGen = 0; % Total hydro generation

for i = 1:height(RenewableGen)
    %   Add nuclear generators
    %%%% Change the hard coded nuclear capacity to data loading
    %%%% These are actually summer and winter capability numbers
    if RenewableGen.PgNuclearCap(i) ~= 0
        
        count = count+1;
        if RenewableGen.bus_id(i)==50
            % Bus 50: zone C, FitzPatrick and Nine Mile Point 1 and 2
            RenewableGen.PgNuclear(i) = nufactor.FitzPatrick/100*854.5+...
                nufactor.NineMilePoint1/100*629+nufactor.NineMilePoint2/100*1299;
%             NuclearGen = NuclearGen + RenewableGen.PgNuclear(i);
        elseif RenewableGen.bus_id(i)== 74
            % Bus 74: zone H, Indian Point 2 and 3
            RenewableGen.PgNuclear(i) = nufactor.IndianPoint2/100*1025.9+...
                nufactor.IndianPoint3/100*1039.9;
%             NuclearGen = NuclearGen + RenewableGen.PgNuclear(i);
        else
            % Bus 53: zone B, Gina
            RenewableGen.PgNuclear(i) = nufactor.Ginna/100*581.7;
%             NuclearGen = NuclearGen + RenewableGen.PgNuclear(i);
        end
        % Calculate total nuclear generation
        NuclearGen = NuclearGen + RenewableGen.PgNuclear(i);
        
        % Add a new row in the mpc.gen matrix
        newrow = zeros(1,21);
        newrow(GEN_BUS) = RenewableGen.bus_id(i);
        newrow(PG) = RenewableGen.PgNuclear(i);
        newrow(QMAX) = 9999;
        newrow(QMIN) = -9999;
        newrow(VG) = 1;
        newrow(MBASE) = 100;
        newrow(GEN_STATUS) = 1;
        newrow(PMAX) = RenewableGen.PgNuclearCap(i);
        newrow(RAMP_AGC) = 0.01*newrow(PMAX);
        newrow(RAMP_10) = 0.1*newrow(PMAX);
        newrow(RAMP_30) = 0.3*newrow(PMAX);
        hyNuGen = [hyNuGen;newrow];
        
        % Add a new row to the mpc.gencost matrix
        % Nuclear gen cost varying in $1-3/MWh
        hynucost(count,COST) = 1+2*rand(1);        
    end
    
    %   Add hydro generators
    if RenewableGen.PgWaterCap(i) ~= 0
        
        count = count +1;
        if RenewableGen.bus_id(i)==55
            % Bus 55: zone A, Niagara
            % Niagara contributes to the most variation
            RenewableGen.PgWater(i) = HyGen - STL(month)*856-0.2*HyGen;
        elseif RenewableGen.bus_id(i)==48
            % Bus 48: zone C, St. Lawrence
            % St. Lawrence works constantly at the monthly capacity factor
            RenewableGen.PgWater(i) = STL(month)*RenewableGen.PgWaterCap(i);
        else
            % Other hydro across NYS contributes
            RenewableGen.PgWater(i) = 0.2*HyGen/CapHydro*RenewableGen.PgWaterCap(i);
        end
        
        % Add a new row in the mpc.gen matrix
        newrow = zeros(1,21);
        newrow(GEN_BUS) = RenewableGen.bus_id(i);
        newrow(PG) = RenewableGen.PgWater(i);
        newrow(QMAX) = 9999;
        newrow(QMIN) = -9999;
        newrow(VG) = 1;
        newrow(MBASE) = 100;
        newrow(GEN_STATUS) = 1;
        newrow(PMAX) = RenewableGen.PgWaterCap(i);
        newrow(PMIN) = 0;       
        newrow(RAMP_AGC) = 0.09*newrow(9);
        newrow(RAMP_10) = 0.9*newrow(9);
        newrow(RAMP_30) = newrow(9);
        hyNuGen = [hyNuGen;newrow];
        
        % Add a new row to the mpc.gencost matrix
        % Hydro gen cost varying in $20-30/MWh?
        %%%% Duplicated gencost matrix definition?
        hynucost(count,COST) = 20+10*rand(1);        
    end
end

fprintf("Finished allocating hydro and nuclear generators!\n");

%% allocate thermal generators in NY
demand = [loaddata.busIdx loaddata.PD];
totalloadny = sum(loaddata.PD); % Total hourly load in NYISO
totalgen = sum(fuelsum.mean_GenMW); % Total hourly generation in NYISO
% Needed thermal generation from NYISO fuel mix data
thermalneed = totalgen-sum(hyNuGen(:,PG))-windGen-ORGen;
% gendata.BusName = str2num(char(gendata.BusName));
% Replace missing generation data with zero?
gendata{:,12:13}(isnan(gendata{:,12:13})) = 0;
% gendata = fillmissing(gendata,'constant',0,'DataVariables',{'hourlyGen','hourlyHeatInput'});

% Thermal generator that matched in the RGGI database?
thegen = zeros(height(gendata),21);
thegen(:,GEN_BUS) = gendata.BusName;
thegen(:,PG) = gendata.hourlyGen;
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
thegen(:,PMAX) = gendata.maxPower;
thegen(:,PMIN) = gendata.minPower;
thegen(:,RAMP_AGC) = gendata.maxRampAgc;
thegen(:,RAMP_10) = gendata.maxRamp10;
thegen(:,RAMP_30) = gendata.maxRamp30;
updatedgen = [thegen;hyNuGen];
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

PJM2NY = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - PJ - NY')+...
    interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - PJM_HTP')+...
    interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - PJM_NEPTUNE')+...
    interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - PJM_VFT');
HQ2NY = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - HQ - NY')+...
    interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - HQ_CEDARS');
NE2NY = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - NE - NY')+...
    interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - NPX_1385')+...
    interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - NPX_CSC');
IESO2NY = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - OH - NY');
Neptune = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - PJM_NEPTUNE');
HTP = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - PJM_HTP');
NPX1385 = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - NPX_1385');
CSC = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SCH - NPX_CSC');
 
% Region
Zonalinfo = table2array(Businfo(:,[2,12]));
% Total load in original NPCC-140 case in NY
NYload = sum(mpc.bus(37:82,PD));

%% update load in NY
mpc.bus(37:82,PD) = loaddata.PD;
mpc.bus(37:82,QD) = loaddata.QD; 

%% Add wind and other renewables as negative load
% Wind
for i = 1:height(RenewableGen)
    if RenewableGen.windCap(i) ~= 0
        windratio = windGen/windCap; % Wind capacity factor in NY
        mpc.bus(RenewableGen.bus_id(i),PD) = mpc.bus(RenewableGen.bus_id(i),PD) - windratio*RenewableGen.windCap(i);
    end
end

% Other renewables
for i = 1:height(RenewableGen)
    if RenewableGen.otherRenewable(i) ~= 0
        ORratio = ORGen/ORCap;
        mpc.bus(RenewableGen.bus_id(i),PD) = mpc.bus(RenewableGen.bus_id(i),PD) - ORratio*RenewableGen.otherRenewable(i);
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
% Total load and generation in the original NPCC-140 case in NE
NELoad = sum(mpc.bus(idxNE,PD));
NEgen = sum(mpc.gen(isNEGen,PG));
% Scale up NE load with the same ratio in NY
NELoadRatio = NYLoadRatio;
mpc.bus(idxNE,PD) = mpc.bus(idxNE,PD)*NELoadRatio;
% Scale up NE generator with scaled load and interface flow data 
NEGenRatio = (NELoad*NELoadRatio+NE2NY)/NEgen;
mpc.gen(isNEGen,PG) = mpc.gen(isNEGen,PG)*NEGenRatio;

idxIESO = Zonalinfo(Zonalinfo(:,2) == 4,1);
IESOload = sum(mpc.bus(idxIESO,3));
IESOgen = sum(mpc.gen(find(ismember(mpc.gen(:,1),idxIESO)==1),2));
IESOscaleload = NYLoadRatio;
IESOscalegen = (IESOload*IESOscaleload+IESO2NY)/IESOgen;
mpc.bus(idxIESO,3) = mpc.bus(idxIESO,3)*IESOscaleload;
mpc.gen(find(ismember(mpc.gen(:,1),idxIESO)==1),2) = mpc.gen(find(ismember(mpc.gen(:,1),idxIESO)==1),2) * IESOscalegen;

idxPJM1 = Zonalinfo(Zonalinfo(:,2) == 5,1);
idxPJM2 = Zonalinfo(Zonalinfo(:,2) == 6,1);
idxPJM = [idxPJM1;idxPJM2];
PJMload = sum(mpc.bus(idxPJM,3));
PJMgen = sum(mpc.gen(find(ismember(mpc.gen(:,1),idxPJM)==1),2));
PJMscaleload = NYLoadRatio;
PJMscalegen = (PJMload*PJMscaleload+PJM2NY)/PJMgen;
mpc.bus(idxPJM,3) = mpc.bus(idxPJM,3)*PJMscaleload;
mpc.gen(find(ismember(mpc.gen(:,1),idxPJM)==1),2) = mpc.gen(find(ismember(mpc.gen(:,1),idxPJM)==1),2) * PJMscalegen;


% Update generators in external area
for i = 1:length(mpc.gen)
    if mpc.gen(i,GEN_BUS)<37 || mpc.gen(GEN_BUS,1)>82
        updatedgen = [updatedgen;mpc.gen(i,:)];
    end
end
mpc.gen = updatedgen;

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
HQgen(PMAX) = flowlimit.mean_PositiveLimitMWH(string(flowlimit.InterfaceName) == 'SCH - HQ - NY')+...
    flowlimit.mean_PositiveLimitMWH(string(flowlimit.InterfaceName) == 'SCH - HQ_CEDARS');
HQgen(PMIN) = flowlimit.mean_NegativeLimitMWH(string(flowlimit.InterfaceName) == 'SCH - HQ - NY')+...
    flowlimit.mean_NegativeLimitMWH(string(flowlimit.InterfaceName) == 'SCH - HQ_CEDARS');

mpc.gen = [mpc.gen; HQgen];

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
	1	-32;	%% 1 : A - B
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
A_B = flowlimit(string(flowlimit.InterfaceName) == 'DYSINGER EAST',:);
B_C = flowlimit(string(flowlimit.InterfaceName) == 'WEST CENTRAL',:);
C_E = flowlimit(string(flowlimit.InterfaceName) == 'TOTAL EAST',:);
D_E = flowlimit(string(flowlimit.InterfaceName) == 'MOSES SOUTH',:);
E_F = flowlimit(string(flowlimit.InterfaceName) == 'CENTRAL EAST - VC',:);
G_H = flowlimit(string(flowlimit.InterfaceName) == 'UPNY CONED',:);
I_J = flowlimit(string(flowlimit.InterfaceName) == 'SPR/DUN-SOUTH',:);
mpcreduced.if.lims = [
	1	A_B.mean_NegativeLimitMWH	A_B.mean_PositiveLimitMWH;	%% 1 : A - B
    2	B_C.mean_NegativeLimitMWH	B_C.mean_PositiveLimitMWH;	%% 2 : B - C
    3   C_E.mean_NegativeLimitMWH    C_E.mean_PositiveLimitMWH;  %% 3 : C - E
    4   D_E.mean_NegativeLimitMWH   D_E.mean_PositiveLimitMWH;   %% 4 : D - E
    5   E_F.mean_NegativeLimitMWH E_F.mean_PositiveLimitMWH;       %% 5 : E - F
    6   -1600  5650-E_F.mean_PositiveLimitMWH ;   %% 6 : E - G
    7   -5400   5400;   %% 7 : F - G
    8   G_H.mean_NegativeLimitMWH   G_H.mean_PositiveLimitMWH;   %% 8 : G - H
    9   -8450   8450;   %% 9 : H - I
    10  -4350    4350;   %% 10 : I - K
    11  -515    1290;   %% 10 : I - K
];

fprintf("Finished setting interface flow limits!\n");

%% add gencost
% cost curve for NY
NYgenthermalcost = zeros(227,6);
NYgenthermalcost(:,MODEL) = 2; % Polynomial cost function
NYgenthermalcost(:,NCOST) = 2; % Linear cost curve
NYgenthermalcost(:,COST:COST+1) = table2array(gendata(:,{'cost_0','cost_1'}));

% cost curve for hydro and nuclear NY

hynucost = zeros(12,6);
hynucost(:,MODEL) = 2;
hynucost(:,NCOST) = 2;
count = 0;
for i = 1:height(RenewableGen)
    if RenewableGen(i,COST) ~= 0
        count = count+1;
        hynucost(count,COST) = 1+2*rand(1);
    end
    if RenewableGen(i,7) ~= 0
        count = count +1;
        hynucost(count,COST) = 10*rand(1);
    end
end

% cost curve for external 
NYzp = NYRTMprice(NYRTMprice.month == month & NYRTMprice.day == day & NYRTMprice.hour == hour,:);
PJMpr = NYzp.mean_LBMPMWHr(string(NYzp.Name) == 'PJM');
NEpr = NYzp.mean_LBMPMWHr(string(NYzp.Name) == 'NPX');
IESOpr = NYzp.mean_LBMPMWHr(string(NYzp.Name) == 'O H');
HQpr = NYzp.mean_LBMPMWHr(string(NYzp.Name) == 'H Q');
PJMprice = PJMpr;
NEprice = NEpr;
IESOprice = IESOpr;
HQprice = HQpr;
exgencostthermal = zeros(28,6);
exgencostthermal(:,1) = 2;
exgencostthermal(:,4) = 2;
offset = 12+227;
for i = 1:length(mpcreduced.gen(offset+1:offset+28,1))
    if mpcreduced.gen(offset+i,1) <=35
        exgencostthermal(i,5) = NEprice;
        
    elseif mpcreduced.gen(offset+i,1) >=83 && mpcreduced.gen(offset+i,1)<= 113
        exgencostthermal(i,5) = IESOprice;
    elseif mpcreduced.gen(offset+i,1)>113
        exgencostthermal(i,5) = PJMprice;
    else
         exgencostthermal(i,5) = HQprice;
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