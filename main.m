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
mpcreduced = updateOpCond(timeStamp);


%% PF test
resultPF = PFtestcase(mpcreduced, timeStamp);



%% OPF test
OresultOPF = OPFtestcase(mpcreduced, timeStamp);

