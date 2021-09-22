function resultPF = PFtestcase(mpcreduced, timeStamp)
%PFTESTCASE
%   
%   This file run a test case for PF using the updatedmpc
%   This file should be run after the OperationConditionUpdate.m file. 
%   MATPOWER should have been installed properly to run the test.
% 
%   Inputs:
%       mpc - reduced MATPOWER case
%   Outputs:
%       mpc - updated MATPOWER case with Power Flow results
% 
%   Created by Vivienne Liu, Cornell University
%   Last modified on August 17, 2021

%% Input parameters

% Read operation condition for NYS
[~,interFlow,flowLimit,~,~,~] = readOpCond(timeStamp);

define_constants;

if isempty(mpcreduced)
    mpcreduced = loadcase('Result/mpcreduced.mat');
end

fprintf("Finished reading MATPOWER case!\n");

%% Run reduced MATPOWER case

resultPF = rundcpf(mpcreduced);
resultBus = resultPF.bus;
resultBranch = resultPF.branch;
resultGen = resultPF.gen;

fprintf("Finished solving power flow!\n");

timeStampStr = datestr(timeStamp,"yyyymmdd_hh");
outfilename = "Result\"+"resultPF_"+timeStampStr+".mat";
save(outfilename,"resultPF");


fprintf("Saved power flow results!\n");

%% Calculate and compare power flow data

A2BResult = -resultBranch(32,PF)+resultBranch(34,PF)+resultBranch(37,PF)+resultBranch(47,PF);
B2CResult = -resultBranch(28,PF)-resultBranch(29,PF)+resultBranch(33,PF)+resultBranch(50,PF);
C2EResult = -resultBranch(16,PF)-resultBranch(20,PF)-resultBranch(21,PF)...
    +resultBranch(56,PF)-resultBranch(62,PF);
D2EResult = -resultBranch(24,PF)-resultBranch(18,PF)-resultBranch(23,PF);
E2FResult = -resultBranch(14,PF)-resultBranch(12,PF)-resultBranch(3,PF)-resultBranch(6,PF);
E2GResult = resultBranch(8,PF);
F2GResult = resultBranch(4,PF);
G2HResult = resultBranch(65,PF)-resultBranch(66,PF);
H2IResult = resultBranch(67,PF);
I2JResult = resultBranch(73,PF)+resultBranch(74,PF);
I2KResult = resultBranch(71,PF)+resultBranch(72,PF);

%%%% Read historical interface flow and limits data from a funciton
% Historical interface flow data
A2BFlow = interFlow.FlowMWH(interFlow.InterfaceName == 'DYSINGER EAST');
B2CFlow = interFlow.FlowMWH(interFlow.InterfaceName == 'WEST CENTRAL');
C2EFlow = interFlow.FlowMWH(interFlow.InterfaceName == 'TOTAL EAST');
D2EFlow = interFlow.FlowMWH(interFlow.InterfaceName == 'MOSES SOUTH');
E2FFlow = interFlow.FlowMWH(interFlow.InterfaceName == 'CENTRAL EAST - VC');
G2HFlow = interFlow.FlowMWH(interFlow.InterfaceName == 'UPNY CONED');
I2JFlow = interFlow.FlowMWH(interFlow.InterfaceName == 'SPR/DUN-SOUTH');

% Historical interface flow limit data
A2BLimit = flowLimit(flowLimit.InterfaceName == 'DYSINGER EAST',:);
B2CLimit = flowLimit(flowLimit.InterfaceName == 'WEST CENTRAL',:);
C2ELimit = flowLimit(flowLimit.InterfaceName == 'TOTAL EAST',:);
D2ELimit = flowLimit(flowLimit.InterfaceName == 'MOSES SOUTH',:);
E2FLimit = flowLimit(flowLimit.InterfaceName == 'CENTRAL EAST - VC',:);
G2HLimit = flowLimit(flowLimit.InterfaceName == 'UPNY CONED',:);
I2JLimit = flowLimit(flowLimit.InterfaceName == 'SPR/DUN-SOUTH',:);

% Difference between historical and simulated data
A2BError = (A2BFlow - A2BResult)/A2BLimit.PositiveLimitMWH;
B2CError = (B2CFlow - B2CResult)/B2CLimit.PositiveLimitMWH;
C2EError = (C2EFlow - C2EResult)/C2ELimit.PositiveLimitMWH;
D2EError = (D2EFlow - D2EResult)/D2ELimit.PositiveLimitMWH;
E2FError = (E2FFlow - E2FResult)/E2FLimit.PositiveLimitMWH;
G2HError = (G2HFlow - G2HResult)/G2HLimit.PositiveLimitMWH;
I2JError = (I2JFlow - I2JResult)/I2JLimit.PositiveLimitMWH;

%% Plot interface flow error

bar([E2FError,B2CError,C2EError,D2EError,A2BError,G2HError,I2JError]*100);
xticklabels({'Central East','West Central','Total East','Moses South','Dysinger East','UpNY-Coned','Dun/SPR-South'})
ylabel('Power Flow Error %','FontSize',14)
xlabel('Interface','FontSize',14)
xtickangle(45)
end