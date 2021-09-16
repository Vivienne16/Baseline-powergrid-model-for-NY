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

[mpcreduced,interflow,flowlimit,fuelsum,NYzp] = updateOpCond(year,month,day,hour);


%% PF test
PFResults = PFtestcase(mpc,interflow,flowlimit);



%% OPF test
OPFResults = OPFtestcase(mpc,fuelsum,month,NYzp);

