function sampleHourLoad = allocateLoadHourly(year,month,date,hour,loadType,method)
% AllocateLoadHourly Allocate hourly load to buses in NYS, produces a table
% of power demand at each bus in NYS, for constructing matpower case file
% Inputs:
%   year,month,date,hour - Timestamp information
%   loadType - DAM hourly load or RTM integrated hourly load
%   method - evenly distribution or weighted distribution
% Outputs:
%   sampleHourLoad - load parameter table

% Author: Bo Yuan
% Last modified: July 28, 2021

%% Default function inputs
if nargin < 5 || isempty(loadType)
    loadType = "DAM";
end
if nargin < 6 || isempty(method)
    method = "weighted";
end

%% Read NYS bus table
NYSBus = readtable("Data/bus_ny_type_zone_new.csv");
NYSBus.zoneID = categorical(NYSBus.zoneID);
% Subset bus with load connected, could be all types of bus
NYSBusWLoad = NYSBus(NYSBus.numLoad > 0, :);
NYSBusWLoad = movevars(NYSBusWLoad,"zoneID","After","busType");
NYSBusWLoad = sortrows(NYSBusWLoad,"zoneID","ascend");

%% Load bus and ratio calculation
zoneIDs = {'A','B','C','D','E','F','G','H','I','J','K'};
loadBusZone = cell(11, 1);
loadRatioZone = cell(11, 1);
numLoadBusZone = zeros(11, 1);
for i=1:11
    % If the zone has bus with load, then distribute the load according to
    % the original load ratio
    % Including zone A, B, C, D, E, F, H, I, K
    loadBusTable = NYSBusWLoad(NYSBusWLoad.zoneID == zoneIDs(i), :);
    loadBusZone{i} = loadBusTable.busIdx;
    loadRatioZone{i} = loadBusTable.sumLoadP0/sum(loadBusTable.sumLoadP0);
    
    % If the zone doesn't have bus with load, then evenly distribute the
    % load among all buses in that zone
    % Including zone G, J
    if isempty(loadBusZone{i})
        loadBusZone{i} = NYSBus.busIdx(NYSBus.zoneID == zoneIDs(i));
        loadRatioZone{i} = 1/length(loadBusZone{i});
    end
    numLoadBusZone(i) = length(loadBusZone{i});
end
numLoadBusTot = sum(numLoadBusZone);

%% Read load data
% Read hourly load data
if loadType == "DAM"
    load("Data/hourly_load_DAM_NY_2019.mat","hourlyLoadNY");
elseif loadType == "RTM"
    load("Data/hourly_load_RTM_NY_2019.mat","hourlyLoadNY");
else
    error("Error: Wrong load type!");
end

%% Sample hour load
TimeStamp = datetime(year,month,date,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
sampleLoadZonal = hourlyLoadNY(hourlyLoadNY.TimeStamp == TimeStamp, :);

%% Distribute load to buses
if method == "evenly"
    sampleHourLoad = addLoadEvenly(sampleLoadZonal,NYSBus,zoneIDs);
elseif method == "weighted"
    sampleHourLoad = addLoadWeighted(sampleLoadZonal,loadRatioZone,loadBusZone,numLoadBusTot,NYSBus,zoneIDs,numLoadBusZone);
else
    Error("Error: Undefined load allocation method");
end

end

%% Method 1: Evenly distribte load
function NYSBusLoadEven = addLoadEvenly(hourlyLoadZonal,NYSBus,zoneIDs)
    NYSBusLoadEven = [];
    for i=1:11
        NYSBusZone = NYSBus(NYSBus.zoneID == zoneIDs(i), :);
        zoneLoadTot = hourlyLoadZonal.HourlyLoad(hourlyLoadZonal.ZoneID == categorical(zoneIDs(i)));
        NYSBusZone.PD = zoneLoadTot/height(NYSBusZone)*ones(height(NYSBusZone), 1);
        NYSBusLoadEven = [NYSBusLoadEven; NYSBusZone];
    end
    
    powerFactor = 0.98;
    NYSBusLoadEven.QD = NYSBusLoadEven.PD * tan(acos(powerFactor));
    NYSBusLoadEven = NYSBusLoadEven(:, ["busIdx","busType","name","area","zoneID","PD","QD"]);
    NYSBusLoadEven = sortrows(NYSBusLoadEven, "busIdx");
end

%% Method 2: Weighted distribte load
function NYSBusNew = addLoadWeighted(hourlyLoadZonal,loadRatioZone,loadBusZone,numLoadBusTot,NYSBusOld,zoneIDs,numLoadBusZone)
    zoneLoadBus = cell(11, 1);
    loadBusIdx = zeros(numLoadBusTot, 1);
    loadBusLoad = zeros(numLoadBusTot, 1);
    n = 1;
    for i=1:11
        zoneLoadTot = hourlyLoadZonal.HourlyLoad(hourlyLoadZonal.ZoneID == categorical(zoneIDs(i)));
        zoneLoadBus{i} = loadRatioZone{i}*zoneLoadTot;
        loadBusIdx(n:n+numLoadBusZone(i)-1) = loadBusZone{i};
        loadBusLoad(n:n+numLoadBusZone(i)-1) = zoneLoadBus{i};
        n = n+numLoadBusZone(i);
    end
    busWLoad = array2table([loadBusIdx, loadBusLoad], "VariableNames", ["busIdx", "PD"]);
    busWLoadCleaned = groupsummary(busWLoad, "busIdx", "sum", "PD");
    busWLoadCleaned.Properties.VariableNames(3) = "PD";
    
    % Join table
    NYSBusNew = outerjoin(NYSBusOld,busWLoadCleaned,"Type","left","Keys","busIdx","MergeKeys",true, ...
        "LeftVariables",["busIdx","busType","name","area","zoneID"],"RightVariables","PD");
    NYSBusNew.PD = fillmissing(NYSBusNew.PD, "constant", 0);
    powerFactor = 0.98;
    NYSBusNew.QD = NYSBusNew.PD * tan(acos(powerFactor));
end