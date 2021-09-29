function bus = addRenewable(bus,timeStamp)
%ADDRENEWABLE Add additional renewable generators to the network

%   Created by Bo Yuan, Cornell University
%   Last modified on Sept. 28, 2021

testday = day(timeStamp);
testhour = hour(timeStamp);

define_constants;

%% Add solar

% Solar sample data: 20200630-20200708
solarTS = datetime(2020,7,testday,testhour,0,0);
filename = "D:\EERL\Solar\solarGenBus_20200630_20200708.csv";
solarGen = readSolarGen(filename,solarTS);

% Allocate wind
for i=1:size(solarGen,1)
    busIdx = (solarGen(i,1) == bus(:,BUS_I));
    bus(busIdx,PD) = bus(busIdx,PD)-solarGen(i,2);
end

%% Add wind

% Wind sample data: 20100701-20190710
windTS = datetime(2010,7,testday,testhour,0,0);
filename = "D:\EERL\Offshore Wind\WRF Output Processed Shiyan\CSV\2010-07-01.csv";
windGen = readWindGen(filename,windTS);

% Allocate wind
for i=1:size(windGen,1)
    busIdx = (windGen(i,1) == bus(:,BUS_I));
    bus(busIdx,PD) = bus(busIdx,PD)-windGen(i,2);
end


end