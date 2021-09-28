function writeFuelPrice(yr)
%WRITEFUELPRICE Download and process fuel price data

%   Created by Bo Yuan, Cornell University
%   Last modified on Sept. 27, 2021

%% Input handling

if isempty(yr)
    yr = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','fuelPriceWeekly_'+string(yr)+'.csv');

if ~isfile(outfilename) % File doesn't exist    
    %% Download fuel price table form NYISO's CARIS report
    fuelpriceDir = fullfile('Prep',string(yr),'fuelprice');
    createDir(fuelpriceDir);
    url = "https://www.nyiso.com/documents/20142/1399076/17CARIS1_Base_Fuel_Price_Final.xls";
    filename = "17CARIS1_Base_Fuel_Price_Final.xls";
    downloadname = websave(fullfile(fuelpriceDir,filename),url);
    
    %% Read fuel price data
    opts = spreadsheetImportOptions("NumVariables", 3);
    % Specify sheet and range
    opts.Sheet = "17CARIS1_Base_Final_Fuel";
    opts.DataRange = "A2:C10171";
    % Specify column names and types
    opts.VariableNames = ["Date", "FuelName", "FuelPricemmBTU"];
    opts.VariableTypes = ["datetime", "categorical", "double"];   
    % Specify variable properties
    opts = setvaropts(opts, "FuelName", "EmptyFieldRule", "auto");
    opts = setvaropts(opts, "Date", "InputFormat", "MM/dd/yyyy");    
    % Import the data
    fuelPrice = readtable(downloadname, opts, "UseExcel", false);
    % Clear options
    clear opts;
    
    %% Get fuel price for a specific year
    fuelPrice = fuelPrice(year(fuelPrice.Date) == yr,:);
    
    %% Write a fuel price table
    fuelPriceTable = fuelPrice(fuelPrice.FuelName == "NG_A-E", :);
    fuelPriceTable = removevars(fuelPriceTable, "FuelName");
    fuelPriceTable.Properties.VariableNames = ["TimeStamp","NG_A2E"];
    fuelPriceTable.NG_F2I = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "NG_F-I", :);
    fuelPriceTable.NG_J = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "NG_ZONEJ", :);
    fuelPriceTable.NG_K = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "NG_ZONEK", :);
    fuelPriceTable.FO2_UPNY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "DFO_UPNY", :);
    fuelPriceTable.FO2_DSNY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "DFO_DSNY", :);
    fuelPriceTable.FO6_UPNY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "RFO_UPNY", :);
    fuelPriceTable.FO6_DSNY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "RFO_DSNY", :);
    fuelPriceTable.coal_NY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "BIT_NY", :)*ones(height(fuelPriceTable),1);
    
    %% Save the data
    writetable(fuelPriceTable,outfilename);
    fprintf("Finished writing fuel price data in %s\n",outfilename);
    
else
    
    fprintf("Fuel price data already exists in %s!\n",outfilename);
    
end

end