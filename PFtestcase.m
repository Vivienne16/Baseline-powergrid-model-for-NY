%Created on July 20, 2021
%Author: Vivienne Liu
%This file run a test case for PF using the updatedmpc
%This file should be run after the OperationConditionUpdate.m file. 
%MATPOWER should have been installed properly to run the test.

%% Load reduced MATPOWER case
define_constants;
mpcreduced = loadcase('Result/mpcreduced.mat');

%% Run reduced MATPOWER case
repf = rundcpf(mpcreduced);
rbus = repf.bus;
rbranch = repf.branch;
rgen = repf.gen;

%% Calculate and compare power flow data
DYSINGEREAST = -rbranch(32,PF)+rbranch(34,PF)+rbranch(37,PF)+rbranch(47,PF);
Westcentral = -rbranch(28,PF)-rbranch(29,PF)+rbranch(33,PF)+rbranch(50,PF);
Totaleast = -rbranch(16,PF)-rbranch(20,PF)-rbranch(21,PF)+rbranch(56,PF)-rbranch(62,PF)+rbranch(8,PF);
mosesouth = -rbranch(24,PF)-rbranch(18,PF)-rbranch(23,PF);
centraleast = -rbranch(14,PF)-rbranch(12,PF)-rbranch(3,PF)-rbranch(6,PF);
upnyconed = rbranch(65,PF)-rbranch(66,PF);
sprdunsouth = rbranch(73,PF)+rbranch(74,PF);

CE = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'CENTRAL EAST - VC');
WC = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'WEST CENTRAL');
TE = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'TOTAL EAST');
MS = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'MOSES SOUTH');
DY = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'DYSINGER EAST');
UC = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'UPNY CONED');
SDS = interflow.mean_FlowMWH(string(interflow.InterfaceName) == 'SPR/DUN-SOUTH');

A_B = flowlimit(string(flowlimit.InterfaceName) == 'DYSINGER EAST',:);
B_C = flowlimit(string(flowlimit.InterfaceName) == 'WEST CENTRAL',:);
C_E = flowlimit(string(flowlimit.InterfaceName) == 'TOTAL EAST',:);
D_E = flowlimit(string(flowlimit.InterfaceName) == 'MOSES SOUTH',:);
E_F = flowlimit(string(flowlimit.InterfaceName) == 'CENTRAL EAST - VC',:);
G_H = flowlimit(string(flowlimit.InterfaceName) == 'UPNY CONED',:);
I_J = flowlimit(string(flowlimit.InterfaceName) == 'SPR/DUN-SOUTH',:);


DCE = (CE - centraleast)/E_F.mean_PositiveLimitMWH;
DWC = (WC - Westcentral)/B_C.mean_PositiveLimitMWH;
DTE = (TE - Totaleast)/C_E.mean_PositiveLimitMWH;
DMS = (MS - mosesouth)/D_E.mean_PositiveLimitMWH;
DDY = (DY - DYSINGEREAST)/A_B.mean_PositiveLimitMWH;
DUC = (UC - upnyconed)/G_H.mean_PositiveLimitMWH;
DSDS = (SDS - sprdunsouth)/I_J.mean_PositiveLimitMWH;

plot([DCE,DWC,DTE,DMS,DDY,DUC,DSDS]*100,'k*-')
ax = gca;
ax.FontSize = 18; 
xticklabels({'Central East','West Central','Total East','Moses South','Dysinger East','UpNY-Coned','Dun/SPR-South'})
ylabel('Power Flow Error %','FontSize',18)
xlabel('Interface','FontSize',18)
xtickangle(45)