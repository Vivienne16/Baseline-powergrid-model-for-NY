%Created on July 20, 2021
%Author: Vivienne Liu
%This file should be run after the ModifyMPC.m file. The operation
%condition of the chosen hour will be updated to the mpc 
%Modify year month day hour for another operation condition.
%The updated and reduced mpc struct will be saved to the Result folder.

year = 2019;
month = 1;
day = 10;
hour = 16;

Fuelmix = readtable('Data/Fuelmix.csv');
InterFlow = readtable('Data/InterFlow.csv');
RenewableGen = readtable('Data/RenewableGen.xlsx');
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
RenewableGen = table2array(RenewableGen(:,[1,4:end]));
RenewableGen(isnan(RenewableGen))=0;
hyNuGen = [];
hyNugencost = [];

% assigning Pg to hydro and nuclear gen
NuGen = fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Nuclear');
HyGen = fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Hydro');
windGen = fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Wind');
ORGen = fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Other Renewables');

CapNuclear = sum(RenewableGen(:,5));
rNugen =  NuGen/CapNuclear;
CapHydro = sum(RenewableGen(:,7))-2460-856;
rHydro =  HyGen/CapHydro;
windCap = sum(RenewableGen(:,9));
ORCap = sum(RenewableGen(:,10));

count = 0;

nufactor = nuclearTable(nuclearTable.day==day&nuclearTable.month==month,:);
STL = [91.33 94.83 101.12 95.47 99.21 109.84 107.61 109.99 109.76 100.53 104.91 104.56];
STL = STL/100;
NuclearGen = 0;
HydroGen = 0;
for i = 1:length(RenewableGen)
    if RenewableGen(i,5) ~= 0
        count = count+1;
        if RenewableGen(i,1)==50
            RenewableGen(i,6) = nufactor.FitzPatrick/100*854.5+...
                nufactor.NineMilePoint1/100*629+nufactor.NineMilePoint2/100*1299;
            NuclearGen = NuclearGen + RenewableGen(i,6);
        elseif RenewableGen(i,1)== 74
            RenewableGen(i,6) = nufactor.IndianPoint2/100*1025.9+...
                nufactor.IndianPoint3/100*1039.9;
            NuclearGen = NuclearGen + RenewableGen(i,6);
        else
            RenewableGen(i,6) = nufactor.Ginna/100*581.7;
            NuclearGen = NuclearGen + RenewableGen(i,6);
        end
        newrow = zeros(1,21);
        newrow(GEN_BUS) = RenewableGen(i,1);
        newrow(PG) = RenewableGen(i,6);

        newrow(QMAX) = 9999;
        newrow(QMIN) = -9999;
        newrow(VG) = 1;
        newrow(MBASE) = 100;
        newrow(GEN_STATUS) = 1;
        newrow(PMAX) = RenewableGen(i,5);
        newrow(RAMP_AGC) = 0.01*newrow(9);
        newrow(RAMP_10) = 0.1*newrow(9);
        newrow(RAMP_30) = 0.3*newrow(9);
        hynucost(count,COST) = 1+2*rand(1);
        hyNuGen = [hyNuGen;newrow];
    end
    if RenewableGen(i,7) ~= 0
        count = count +1;
        if RenewableGen(i,1)==55
            RenewableGen(i,8) = HyGen - STL(month)*856-0.2*HyGen;
        elseif RenewableGen(i,1)==48
            RenewableGen(i,8) = STL(month)*RenewableGen(i,7);
        else
            RenewableGen(i,8) = 0.2*HyGen/CapHydro*RenewableGen(i,7);
        end
        newrow = zeros(1,21);
        newrow(1) = RenewableGen(i,1);
        newrow(2) = RenewableGen(i,8);
        newrow(4) = 9999;
        newrow(5) = -9999;
        newrow(6) = 1;
        newrow(7) = 100;
        newrow(8) = 1;
        newrow(9) = RenewableGen(i,7);
        newrow(10) = 0;
        hynucost(count,5) = 20+10*rand(1);
        newrow(17) = 0.09*newrow(9);
        newrow(18) = 0.9*newrow(9);
        newrow(19) = newrow(9);
        hyNuGen = [hyNuGen;newrow];
    end
end

%% allocate thermal generators in NY
demand = [loaddata.busIdx loaddata.PD];
totalloadny = sum(loaddata.PD);
totalgen = sum(fuelsum.mean_GenMW);
theramlneed = totalgen-sum(hyNuGen(:,2))-windGen-ORGen;
% gendata.BusName = str2num(char(gendata.BusName));
gendata{:,12:13}(isnan(gendata{:,12:13})) = 0;
thegen = zeros(height(gendata),21);
thegen(:,GEN_BUS) = gendata.BusName;
thegen(:,PG) = gendata.hourlyGen;
totalthermal = sum(thegen(:,PG));
thermaldiff = theramlneed-totalthermal;
JK = [79 80,81,82];
JKidx = find(ismember(thegen(:,1),JK)==1);
thegen(JKidx,2) = thegen(JKidx,2)+(thegen(JKidx,2)~=0).*thermaldiff.*thegen(JKidx,2)./sum(thegen(JKidx,2));

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
ThermalGen = sum(thegen(:,PG));

exgen = [];
for i = 1:length(mpc.gen)
    if mpc.gen(i,GEN_BUS)<37 || mpc.gen(i,GEN_BUS)>82
        exgen = [exgen;mpc.gen(i,:)];
    end
end



%% calculate external flow below
exloadtotal = sum(mpc.bus(1:36,PD))+sum(mpc.bus(83:end,PD));
exgentotal = sum(exgen(:,PG));

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
 

Zonalinfo = table2array(Businfo(:,[2,12]));

NYload = sum(mpc.bus(37:82,3));

%% update load in NY
mpc.bus(37:82,PD) = loaddata.PD;
mpc.bus(37:82,QD) = loaddata.QD; 

%update wind and other renewables in NY
for i = 1:length(RenewableGen)
    if RenewableGen(i,9) ~= 0
        windratio = windGen/windCap;
        mpc.bus(RenewableGen(i,1),3) = mpc.bus(RenewableGen(i,1),3) - windratio*RenewableGen(i,9);
    end
end

for i = 1:length(RenewableGen)
    if RenewableGen(i,10) ~= 0
        ORratio = ORGen/ORCap;
        mpc.bus(RenewableGen(i,1),3) = mpc.bus(RenewableGen(i,1),3) - ORratio*RenewableGen(i,10);
    end
end


NYloadratio = sum(mpc.bus(37:82,PD))/NYload;

%% scale up load and generation for external area

idxNE = Zonalinfo(Zonalinfo(:,2) == 1,1);
NEload = sum(mpc.bus(idxNE,PD));
NEgen = sum(mpc.gen(find(ismember(mpc.gen(:,1),idxNE)==1),2));
NEscaleload = NYloadratio;
NEscalegen = (NEload*NEscaleload+NE2NY)/NEgen;
mpc.bus(idxNE,PD) = mpc.bus(idxNE,PD)*NEscaleload;
mpc.gen(find(ismember(mpc.gen(:,1),idxNE)==1),PG) = mpc.gen(find(ismember(mpc.gen(:,1),idxNE)==1),PG) * NEscalegen;


idxIESO = Zonalinfo(Zonalinfo(:,2) == 4,1);
IESOload = sum(mpc.bus(idxIESO,3));
IESOgen = sum(mpc.gen(find(ismember(mpc.gen(:,1),idxIESO)==1),2));
IESOscaleload = NYloadratio;
IESOscalegen = (IESOload*IESOscaleload+IESO2NY)/IESOgen;
mpc.bus(idxIESO,3) = mpc.bus(idxIESO,3)*IESOscaleload;
mpc.gen(find(ismember(mpc.gen(:,1),idxIESO)==1),2) = mpc.gen(find(ismember(mpc.gen(:,1),idxIESO)==1),2) * IESOscalegen;

idxPJM1 = Zonalinfo(Zonalinfo(:,2) == 5,1);
idxPJM2 = Zonalinfo(Zonalinfo(:,2) == 6,1);
idxPJM = [idxPJM1;idxPJM2];
PJMload = sum(mpc.bus(idxPJM,3));
PJMgen = sum(mpc.gen(find(ismember(mpc.gen(:,1),idxPJM)==1),2));
PJMscaleload = NYloadratio;
PJMscalegen = (PJMload*PJMscaleload+PJM2NY)/PJMgen;
mpc.bus(idxPJM,3) = mpc.bus(idxPJM,3)*PJMscaleload;
mpc.gen(find(ismember(mpc.gen(:,1),idxPJM)==1),2) = mpc.gen(find(ismember(mpc.gen(:,1),idxPJM)==1),2) * PJMscalegen;


%update gen

for i = 1:length(mpc.gen)
    if mpc.gen(i,1)<37 || mpc.gen(i,1)>82
        updatedgen = [updatedgen;mpc.gen(i,:)];
    end
end
mpc.gen = updatedgen;

%% Add generator for HQ
HQgen = zeros(1,21);
HQgen(1) = 48;
HQgen(2) = HQ2NY;
HQgen(4) = 9999;
HQgen(5) = -9999;
HQgen(6) = 1;
HQgen(7) = 100;
HQgen(8) = 1;
HQgen(9) = flowlimit.mean_PositiveLimitMWH(string(flowlimit.InterfaceName) == 'SCH - HQ - NY')+...
    flowlimit.mean_PositiveLimitMWH(string(flowlimit.InterfaceName) == 'SCH - HQ_CEDARS');
HQgen(10) = flowlimit.mean_NegativeLimitMWH(string(flowlimit.InterfaceName) == 'SCH - HQ - NY')+...
    flowlimit.mean_NegativeLimitMWH(string(flowlimit.InterfaceName) == 'SCH - HQ_CEDARS');

mpc.gen = [mpc.gen; HQgen];


%% external modification for generators
exidx = mpc.gen(:,PMAX)==9999;
mpc.gen(mpc.gen(:,PMIN)<0,PMIN) = 0;
mpc.gen(mpc.gen(:,PMAX)==9999,PMAX) = mpc.gen(mpc.gen(:,PMAX)==9999,PMAX)*1.5;
mpc.gen(exidx,RAMP_10) = mpc.gen(exidx,PMAX)/20;
mpc.gen(exidx,RAMP_30) = mpc.gen(exidx,RAMP_10)*3;
mpc.gen(exidx,RAMP_AGC) = mpc.gen(exidx,RAMP_10)/10;
mpc.gen(:,PMIN) = 0;
%% Equivelent Reduction

Exbus = [1:20,22:28,30:34,36,83:99,101,104:123,126:131,133,135:137,139:140];
[mpcreduced,Link,BCIRCr] = MPReduction(mpc,Exbus,1);


%% add HVDC lines 
mpcreduced.dcline = [
	21 80	1	NPX1385+CSC	0	0	0	1.01	1	-530	530	-100	100	-100	100	0	0;
	124 79	1	Neptune	0	0	0	1.01	1	-660	660	-100	100	-100	100	0	0;
    125 81	1	HTP	0	0	0	1.01	1	-660	660	-100	100	-100	100	0	0;
];
mpcreduced = toggle_dcline(mpcreduced, 'on');

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
    6   8;        %% 6 : E - G
    7   4;     %% 7 : F - G
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

%% add gencost
% cost curve for NY
NYgenthermalcost = zeros(227,6);
NYgenthermalcost(:,MODEL) = 2;
NYgenthermalcost(:,NCOST) = 2;
NYgenthermalcost(:,COST:COST+1) = table2array(gendata(:,15:16));

% cost curve for hydro and nuclear NY

hynucost = zeros(12,6);
hynucost(:,MODEL) = 2;
hynucost(:,NCOST) = 2;
count = 0;
for i = 1:length(RenewableGen)
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


savecase('Result/mpcreduced.mat',mpcreduced);