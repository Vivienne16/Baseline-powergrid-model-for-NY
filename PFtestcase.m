%Created on July 20, 2021
%Author: Vivienne Liu
%This file run a test case for PF using the updatedmpc
%This file should be run after the OperationConditionUpdate.m file. 
%MATPOWER should have been installed properly to run the test.

repf = rundcpf(mpcreduced);
rbus = repf.bus;
rbranch = repf.branch;
rgen = repf.gen;

DYSINGEREAST = -rbranch(32,14)+rbranch(34,14)+rbranch(37,14)+rbranch(47,14);
Westcentral = -rbranch(28,14)-rbranch(29,14)+rbranch(33,14)+rbranch(50,14);
Totaleast = -rbranch(16,14)-rbranch(20,14)-rbranch(21,14)+rbranch(56,14)-rbranch(62,14)+rbranch(8,14);
mosesouth = -rbranch(24,14)-rbranch(18,14)-rbranch(23,14);
centraleast = -rbranch(14,14)-rbranch(12,14)-rbranch(3,14)-rbranch(6,14);
upnyconed = rbranch(65,14)-rbranch(66,14);
sprdunsouth = rbranch(73,14)+rbranch(74,14);

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