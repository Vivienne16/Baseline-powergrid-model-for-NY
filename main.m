%% Main file
% Description of the main file
%
%

%% Modify MPC
modifyMPC;


%% Operation condition update

year = 2019;
month = 1;
day = 10;
hour = 16;

mpcreduced = updateOperationCondition(year,month,day,hour);


%% PF test
PFtestcase



%% OPF test
OPFtestcase

