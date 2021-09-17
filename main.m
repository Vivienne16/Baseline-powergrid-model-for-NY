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

timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
[mpcreduced,interflow,flowlimit,fuelsum,NYzp] = updateOpCond(timeStamp);


%% PF test
PFResults = PFtestcase(mpc,interflow,flowlimit);



%% OPF test
OPFResults = OPFtestcase(mpc,fuelsum,month,NYzp);

