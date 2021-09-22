%% Main file
% Description of the main file
%
%

%% Parameter settings
savefig = true;
verbose = true;

%% Modify MPC
modifyMPC;

%% Test case
year = 2019;
month = 1;
day = 1;
hour = 24;

timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");

% Operation condition update
mpcreduced = updateOpCond(timeStamp);

% PF test
resultPF = PFtestcase(mpcreduced,timeStamp);

% OPF test
resultOPF = OPFtestcase(mpcreduced,timeStamp);


%% Loop through the whole year 2019

year = 2019;
for month = 7
    parfor day = 1:eomday(year,month)
        for hour = 1:3:24
            % Operation condition update
            timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
            mpcreduced = updateOpCond(timeStamp);

            % PF test
            resultPF = PFtestcase(mpcreduced, timeStamp);

            % OPF test
            resultOPF = OPFtestcase(mpcreduced, timeStamp);
        end
    end
end

