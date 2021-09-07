function mpc = OPFtestcase(mpc)
%OPFTESTCASE
% 
%   This file run a test case for OPF using the updated mpc
%   This file should be run after the OperationConditionUpdate.m file. 
%   MATPOWER should have been installed properly to run the test.
% 
%   Inputs:
%       mpc - reduced MATPOWER case
%   Outputs:
%       mpc - updated mpc with Optimal Power Flow results

%   Created by Vivienne Liu, Cornell University
%   Last modified on August 17, 2021

%% Load reduced MATPOWER case
mpcreduced = loadcase('Result/mpcreduced.mat');

%% additional constraints for large hydro to avoid dispatch at upper gen limit
%hydro gen constraints
%%%% Change this to data file reading
RMNcf = [0.8072,0.7688,0.815,0.7178,0.8058,0.7785,0.8275,0.8007,0.7931,0.7626,0.7764,0.8540];
STLcf = [0.9133,0.9483, 1.0112,0.9547,0.9921,1.0984,1.0761,1.0999,1.0976,1.0053,1.0491,1.0456];
mpcreduced.gen(228,9) = 0.8*(fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Hydro')-910)-STLcf(month)*860;
mpcreduced.gen(234,9) = STLcf(month)*860;



%% Run OPF
mpopt = mpoption( 'opf.dc.solver','GUROBI','opf.flow_lim','P');
mpcreduced = toggle_iflims(mpcreduced, 'on');
reducedopf = rundcopf(mpcreduced,mpopt);
rdc = reducedopf.dcline;
rbus = reducedopf.bus;
rbranch = reducedopf.branch;
rgen = reducedopf.gen;
rgencost = reducedopf.gencost;

%% calculate zonal price
PJMbus = rbus(53:57,:);
NEbus = rbus(1:3,:);
IESObus = rbus(50:52,:);
PJMPRICE = PJMbus(:,3)'*PJMbus(:,14)/sum(PJMbus(:,3));
NEPRICE = NEbus(:,3)'*NEbus(:,14)/sum(NEbus(:,3));
IESOPRICE = IESObus(:,3)'*IESObus(:,14)/sum(IESObus(:,3));
busIdA = [54 55 56 57 58 59 60 61];
busIdB = [52 53 62];
busIdC = [50 51 63 64 65 66 67 68 70 71 72];
busIdD = [48 49];
busIdE = [38 43 44 45 46 47 69];
busIdF = [37 40 41 42];
busIdG = [39 73 75 76 77];
busIdH = 74;
busIdI = 78;
busIdJ = [82 81];
busIdK = [79 80];
isAGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdA);
isBGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdB);
isCGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdC);
isDGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdD);
isEGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdE);
isFGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdF);
isGGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdG);
isHGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdH);
isIGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdI);
isJGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdJ);
isKGen = ismember(mpcreduced.gen(:,GEN_BUS),busIdK);


Abus = [];Bbus = [];Cbus = [];Dbus = [];Ebus = [];Fbus = [];Gbus = [];Hbus = [];Ibus = [];Kbus = [];Jbus = [];

Abus_copy = rbus(ismember(rbus(:,BUS_I),busIdA),:);



for i = busIdA
    Abus = [Abus;rbus(rbus(:,1)==i,:)];
end
Aprice = Abus(:,PD)'*Abus(:,LAM_P)/sum(Abus(:,PD));
for i = busIdB
    Bbus = [Bbus;rbus(rbus(:,1)==i,:)];
end
Bprice = Bbus(:,PD)'*Bbus(:,LAM_P)/sum(Bbus(:,PD));
for i = busIdC
    Cbus = [Cbus;rbus(rbus(:,1)==i,:)];
end
Cprice = Cbus(:,PD)'*Cbus(:,14)/sum(Cbus(:,PD));
for i = busIdD
    Dbus = [Dbus;rbus(rbus(:,1)==i,:)];
end
Dprice = Dbus(:,PD)'*Dbus(:,14)/sum(Dbus(:,PD));
for i = busIdE
    Ebus = [Ebus;rbus(rbus(:,1)==i,:)];
end
EMHKVLprice = Ebus(:,PD)'*Ebus(:,14)/sum(Ebus(:,PD));
for i = busIdF
    Fbus = [Fbus;rbus(rbus(:,1)==i,:)];
end
FCAPITLprice = Fbus(:,PD)'*Fbus(:,14)/sum(Fbus(:,PD));
for i = busIdG
    Gbus = [Gbus;rbus(rbus(:,1)==i,:)];
end
GHUDVLprice = Gbus(:,PD)'*Gbus(:,14)/sum(Gbus(:,PD));
for i = busIdH
    Hbus = [Hbus;rbus(rbus(:,1)==i,:)];
end
HMILLWDprice = Hbus(:,PD)'*Hbus(:,14)/sum(Hbus(:,PD));
for i = busIdI
    Ibus = [Ibus;rbus(rbus(:,1)==i,:)];
end
IDUNWODprice = Ibus(:,PD)'*Ibus(:,14)/sum(Ibus(:,PD));
for i = busIdJ
    Jbus = [Jbus;rbus(rbus(:,1)==i,:)];
end
JNYCprice = Jbus(:,PD)'*Jbus(:,14)/sum(Jbus(:,PD));
for i = busIdK
    Kbus = [Kbus;rbus(rbus(:,1)==i,:)];
end
KLIprice = Kbus(:,PD)'*Kbus(:,14)/sum(Kbus(:,PD));
simprice = [Aprice,Bprice,Cprice,Dprice,EMHKVLprice,FCAPITLprice,GHUDVLprice,HMILLWDprice,IDUNWODprice,JNYCprice,KLIprice,PJMPRICE,NEPRICE,IESOPRICE];

%% read real price
load('Data/NYRTMprice.mat');
NYzp = NYRTMprice(NYRTMprice.month == month & NYRTMprice.day == day & NYRTMprice.hour == hour,:);
NYzp = NYzp(:,{'Name','LBMPMWHr'});
NYzp = groupsummary(NYzp,'Name','mean');
Apr = NYzp.mean_LBMPMWHr(NYzp.Name == 'WEST');
Bpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'GENESE');
Cpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'CENTRL');
Dpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'NORTH');
Epr = NYzp.mean_LBMPMWHr(NYzp.Name == 'MHK VL');
Fpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'CAPITL');
Gpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'HUD VL');
Hpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'MILLWD');
Ipr = NYzp.mean_LBMPMWHr(NYzp.Name == 'DUNWOD');
Jpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'N.Y.C.');
Kpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'LONGIL');
PJMpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'PJM');
NEpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'NPX');
IESOpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'O H');
HQpr = NYzp.mean_LBMPMWHr(NYzp.Name == 'H Q');
realprice = [Apr,Bpr,Cpr,Dpr,Epr,Fpr,Gpr,Hpr,Ipr,Jpr,Kpr,PJMpr,NEpr,IESOpr];


x0=10;
y0=10;
width=550;
height=400;
%%%%%%%%%%%%%plot figure%%%%%%%%%%%%%%%%%
figure
set(gca,'FontSize',18)
set(gcf,'position',[x0,y0,width,height])
plot(realprice,'LineWidth',3)
hold on
plot(simprice,'LineWidth',3)
h = legend({'Historical LMP','Simulated LMP'},'FontSize', 18);
set(h,'Location','best')
ax = gca;
ax.FontSize = 16; 
xticks([1:14])
xticklabels({'West','Genese','Central','North','MHK VL','Capital','HUD VL','MILLWD','DUNWOD','NYC','Long IL','PJM','NE','Ontario'})
xtickangle(45)
xlabel('Zone','FontSize', 18)
ylabel('LMP ($/MW)','FontSize', 18)
end

       