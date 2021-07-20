%Created on July 20, 2021
%Author: Vivienne Liu
%This file run a test case for OPF using the updated mpc
%This file should be run after the OperationConditionUpdate.m file. 
%MATPOWER should have been installed properly to run the test.


%% additional constraints for large hydro to avoid dispatch at upper gen limit
%hydro gen constraints
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
A = [54 55 56 57 58 59 60 61];
B = [62 52 53];
C = [50 51 63 64 65 66 67 68 70 71 72];
D = [48 49];
E = [69 38 43 44 45 46 47];
F = [37 40 41 42];
G = [39 73 75 76 77];
H = [74];
I = 78;
J = [82 81];
K = [79 80];
Aidx = find(ismember(mpcreduced.gen(:,1),A)==1);
Bidx = find(ismember(mpcreduced.gen(:,1),B)==1);
Cidx = find(ismember(mpcreduced.gen(:,1),C)==1);
Didx = find(ismember(mpcreduced.gen(:,1),D)==1);
Eidx = find(ismember(mpcreduced.gen(:,1),E)==1);
Fidx = find(ismember(mpcreduced.gen(:,1),F)==1);
Gidx = find(ismember(mpcreduced.gen(:,1),G)==1);
Hidx = find(ismember(mpcreduced.gen(:,1),H)==1);
Iidx = find(ismember(mpcreduced.gen(:,1),I)==1);
Jidx = find(ismember(mpcreduced.gen(:,1),J)==1);
Kidx = find(ismember(mpcreduced.gen(:,1),K)==1);


Abus = [];Bbus = [];Cbus = [];Dbus = [];Ebus = [];Fbus = [];Gbus = [];Hbus = [];Ibus = [];Kbus = [];Jbus = [];

for i = A
    Abus = [Abus;rbus(rbus(:,1)==i,:)];
end
Aprice = Abus(:,3)'*Abus(:,14)/sum(Abus(:,3));
for i = B
    Bbus = [Bbus;rbus(rbus(:,1)==i,:)];
end
Bprice = Bbus(:,3)'*Bbus(:,14)/sum(Bbus(:,3));
for i = C
    Cbus = [Cbus;rbus(rbus(:,1)==i,:)];
end
Cprice = Cbus(:,3)'*Cbus(:,14)/sum(Cbus(:,3));
for i = D
    Dbus = [Dbus;rbus(rbus(:,1)==i,:)];
end
Dprice = Dbus(:,3)'*Dbus(:,14)/sum(Dbus(:,3));
for i = E
    Ebus = [Ebus;rbus(rbus(:,1)==i,:)];
end
EMHKVLprice = Ebus(:,3)'*Ebus(:,14)/sum(Ebus(:,3));
for i = F
    Fbus = [Fbus;rbus(rbus(:,1)==i,:)];
end
FCAPITLprice = Fbus(:,3)'*Fbus(:,14)/sum(Fbus(:,3));
for i = G
    Gbus = [Gbus;rbus(rbus(:,1)==i,:)];
end
GHUDVLprice = Gbus(:,3)'*Gbus(:,14)/sum(Gbus(:,3));
for i = H
    Hbus = [Hbus;rbus(rbus(:,1)==i,:)];
end
HMILLWDprice = Hbus(:,3)'*Hbus(:,14)/sum(Hbus(:,3));
for i = I
    Ibus = [Ibus;rbus(rbus(:,1)==i,:)];
end
IDUNWODprice = Ibus(:,3)'*Ibus(:,14)/sum(Ibus(:,3));
for i = J
    Jbus = [Jbus;rbus(rbus(:,1)==i,:)];
end
JNYCprice = Jbus(:,3)'*Jbus(:,14)/sum(Jbus(:,3));
for i = K
    Kbus = [Kbus;rbus(rbus(:,1)==i,:)];
end
KLIprice = Kbus(:,3)'*Kbus(:,14)/sum(Kbus(:,3));
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
h = legend('Historical LMP','Simulated LMP','Real Power Error','FontSize', 18);
set(h,'Location','best')
ax = gca;
ax.FontSize = 16; 
xticks([1:14])
xticklabels({'West','Genese','Central','North','MHK VL','Capital','HUD VL','MILLWD','DUNWOD','NYC','Long IL','PJM','NE','Ontario'})
xtickangle(45)
xlabel('Zone','FontSize', 18)
ylabel('LMP ($/MW)','FontSize', 18)


       