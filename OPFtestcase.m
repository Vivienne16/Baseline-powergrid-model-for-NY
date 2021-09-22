function resultOPF = OPFtestcase(mpcreduced, timeStamp)
%OPFTESTCASE
% 
%   This file run a test case for OPF using the updated mpc
%   This file should be run after the OperationConditionUpdate.m file. 
%   MATPOWER should have been installed properly to run the test.
% 
%   Inputs:
%       mpc - reduced MATPOWER case
%   Outputs:
%       mpc - updated mpc with Optimal Power Flow results

%   Created by Vivienne Liu, Cornell University
%   Last modified on August 17, 2021

%% Input parameters

% Read operation condition for NYS
[~,~,~,~,~,zonalPrice] = readOpCond(timeStamp);
busInfo = importBusInfo(fullfile("Data","npcc.csv"));

define_constants;

if isempty(mpcreduced)
    mpcreduced = loadcase("Result/mpcreduced.mat");
end

%% additional constraints for large hydro to avoid dispatch at upper gen limit
%hydro gen constraints
% RMNcf = [0.8072,0.7688,0.815,0.7178,0.8058,0.7785,0.8275,0.8007,0.7931,0.7626,0.7764,0.8540];
% STLcf = [0.9133,0.9483, 1.0112,0.9547,0.9921,1.0984,1.0761,1.0999,1.0976,1.0053,1.0491,1.0456];
% mpcreduced.gen(228,9) = 0.8*(fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Hydro')-910)-STLcf(month)*860;
% mpcreduced.gen(234,9) = STLcf(month)*860;



%% Run OPF
mpopt = mpoption( 'opf.dc.solver','GUROBI','opf.flow_lim','P');
mpcreduced = toggle_iflims(mpcreduced, 'on');
resultOPF = rundcopf(mpcreduced,mpopt);
resultDCLine = resultOPF.dcline;
resultBus = resultOPF.bus;
resultBranch = resultOPF.branch;
resultGen = resultOPF.gen;
resultGencost = resultOPF.gencost;

fprintf("Finished solving optimal power flow!\n");

timeStampStr = datestr(timeStamp,"yyyymmdd_hh");
outfilename = "Result\"+"resultOPF_"+timeStampStr+".mat";
save(outfilename,"resultOPF");

fprintf("Saved optimal power flow results!\n");

%% Define bus indices

busIdNY = busInfo.idx(busInfo.zone ~= "NA");
busIdExt = busInfo.idx(busInfo.zone == "NA");

busIdA = busInfo.idx(busInfo.zone == "A");
busIdB = busInfo.idx(busInfo.zone == "B");
busIdC = busInfo.idx(busInfo.zone == "C");
busIdD = busInfo.idx(busInfo.zone == "D");
busIdE = busInfo.idx(busInfo.zone == "E");
busIdF = busInfo.idx(busInfo.zone == "F");
busIdG = busInfo.idx(busInfo.zone == "G");
busIdH = busInfo.idx(busInfo.zone == "H");
busIdI = busInfo.idx(busInfo.zone == "I");
busIdJ = busInfo.idx(busInfo.zone == "J");
busIdK = busInfo.idx(busInfo.zone == "K");

busIdNE = [21;29;35];
busIdIESO = [100;102;103];
busIdPJM = [124;125;132;134;138];

%% Get simulated and real price

priceSim = [
    averagePrice(resultBus,busIdA);
    averagePrice(resultBus,busIdB);
    averagePrice(resultBus,busIdC);
    averagePrice(resultBus,busIdD);
    averagePrice(resultBus,busIdE);
    averagePrice(resultBus,busIdF);
    averagePrice(resultBus,busIdG);
    averagePrice(resultBus,busIdH);
    averagePrice(resultBus,busIdI);
    averagePrice(resultBus,busIdJ);
    averagePrice(resultBus,busIdK);
    averagePrice(resultBus,busIdPJM);
    averagePrice(resultBus,busIdNE);
    averagePrice(resultBus,busIdIESO)];

% Get real price
priceReal = [
    zonalPrice.LBMP(zonalPrice.ZoneName == "WEST");
    zonalPrice.LBMP(zonalPrice.ZoneName == "GENESE");
    zonalPrice.LBMP(zonalPrice.ZoneName == "CENTRL");
    zonalPrice.LBMP(zonalPrice.ZoneName == "NORTH");
    zonalPrice.LBMP(zonalPrice.ZoneName == "MHK VL");
    zonalPrice.LBMP(zonalPrice.ZoneName == "CAPITL");
    zonalPrice.LBMP(zonalPrice.ZoneName == "HUD VL");
    zonalPrice.LBMP(zonalPrice.ZoneName == "MILLWD");
    zonalPrice.LBMP(zonalPrice.ZoneName == "DUNWOD");
    zonalPrice.LBMP(zonalPrice.ZoneName == "N.Y.C.");
    zonalPrice.LBMP(zonalPrice.ZoneName == "LONGIL");
    zonalPrice.LBMP(zonalPrice.ZoneName == "PJM");
    zonalPrice.LBMP(zonalPrice.ZoneName == "NPX");
    zonalPrice.LBMP(zonalPrice.ZoneName == "O H")];

%% Plot price comparison

zoneName = ["A";"B";"C";"D";"E";"F";"G";"H";"I";"J";"K";"PJM";"NE";"IESO"];
f = figure();
price = [priceSim priceReal];
bar(price)
xticklabels(zoneName);
legend(["Historical LMP","Simulated LMP"],"FontSize",14,"Location","northwest");
xlabel("Zone","FontSize", 12);
ylabel("LMP ($/MW)","FontSize", 12); 
set(f,"position",[100,100,800,600]);

end

function avgPrice = averagePrice(resultBus, busId)
%AVGPRICE Calculate weighted average price of a zone
define_constants;
busM = resultBus(ismember(resultBus(:,BUS_I),busId),:);
avgPrice = sum(busM(:,PD).*busM(:,LAM_P))/sum(busM(:,PD));
end
       