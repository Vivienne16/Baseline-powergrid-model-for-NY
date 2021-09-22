function [priceSim,priceReal,priceError,zoneName] = price4Plot(resultBus,zonalPrice,busInfo)
%FLOW4PLOT Construct matrices for plotting interface flow

define_constants;

% Define bus indices
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
busIdHQ = 48;

% Simulated price data
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
    averagePrice(resultBus,busIdIESO);
    averagePrice(resultBus,busIdHQ)];

% Historical price data
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
    zonalPrice.LBMP(zonalPrice.ZoneName == "O H");
    zonalPrice.LBMP(zonalPrice.ZoneName == "H Q")];

% Price error
priceError = (priceSim-priceReal)./priceReal;

% Zone name
zoneName = ["A";"B";"C";"D";"E";"F";"G";"H";"I";"J";"K";"PJM";"NE";"IESO";"HQ"];

end

function avgPrice = averagePrice(resultBus, busId)
%AVGPRICE Calculate weighted average price of a zone
define_constants;
busM = resultBus(ismember(resultBus(:,BUS_I),busId),:);
avgPrice = sum(busM(:,PD).*busM(:,LAM_P))/sum(busM(:,PD));
end