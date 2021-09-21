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
[fuelMix,interFlow,flowLimit,nuclearCf,hydroCf,zonalPrice] = readOpCond(timeStamp);
busInfo = importBusInfo(fullfile("Data","npcc.csv"));

define_constants;

if isempty(mpcreduced)
    mpcreduced = loadcase('Result/mpcreduced.mat');
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

savecase('Result\resultOPF.mat', resultOPF);

fprintf("Saved optimal power flow results!\n");

%% calculate zonal price
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

%% Get simulated price

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
    averagePrice(resultBus,busIdNE);
    averagePrice(resultBus,busIdIESO);
    averagePrice(resultBus,busIdPJM);
];

%% Get real price

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
    zonalPrice.LBMP(zonalPrice.ZoneName == "O H")
    ];

%% Plot price comparison

x0=100;
y0=100;
width=800;
height=600;
ftsz = 16;
%%%%%%%%%%%%%plot figure%%%%%%%%%%%%%%%%%
f = figure();
hold on;
p1 = plot(priceReal,'LineWidth',3);
p2 = plot(priceSim,'LineWidth',3);
legend([p1,p2],["Historical LMP","Simulated LMP"],"FontSize",ftsz,"Location","northeast");
xticks([1:14])
xticklabels({'West','Genese','Central','North','MHK VL','Capital','HUD VL','MILLWD','DUNWOD','NYC','Long IL','PJM','NE','Ontario'})
gca.FontSize = ftsz;
xtickangle(45)
xlabel('Zone','FontSize', ftsz)
ylabel('LMP ($/MW)','FontSize', ftsz)
set(f,'position',[x0,y0,width,height]);

end

function avgPrice = averagePrice(resultBus, busId)
%AVGPRICE Calculate weighted average price of a zone
define_constants;
busM = resultBus(ismember(resultBus(:,BUS_I),busId),:);
avgPrice = sum(busM(:,PD).*busM(:,LAM_P))/sum(busM(:,PD));
end
       