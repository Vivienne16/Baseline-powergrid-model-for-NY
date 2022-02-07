function writeFuelPrice(testyear)
%WRITEFUELPRICE Download and process fuel price data
% Only supports year 2017 and later for now.

%   Created by Bo Yuan, Cornell University
%   Last modified on Sept. 27, 2021

%% Input handling

if isempty(testyear)
    testyear = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','fuelPriceWeekly_'+string(testyear)+'.csv');
matfilename = fullfile('Data','fuelPriceWeekly_'+string(testyear)+'.mat');

if ~isfile(outfilename) || ~isfile(matfilename) % File doesn't exist    
    %% Download fuel price table form NYISO's CARIS report
    fuelpriceDir = fullfile('Prep',string(testyear),'fuelprice');
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
    fuelPrice = fuelPrice(year(fuelPrice.Date) == testyear,:);
    
    %% Write a fuel price table
    fuelPriceWeekly = fuelPrice(fuelPrice.FuelName == "NG_A-E", :);
    fuelPriceWeekly = removevars(fuelPriceWeekly, "FuelName");
    fuelPriceWeekly.Properties.VariableNames = ["TimeStamp","NG_A2E"];
    fuelPriceWeekly.NG_F2I = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "NG_F-I", :);
    fuelPriceWeekly.NG_J = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "NG_ZONEJ", :);
    fuelPriceWeekly.NG_K = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "NG_ZONEK", :);
    fuelPriceWeekly.FO2_UPNY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "DFO_UPNY", :);
    fuelPriceWeekly.FO2_DSNY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "DFO_DSNY", :);
    fuelPriceWeekly.FO6_UPNY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "RFO_UPNY", :);
    fuelPriceWeekly.FO6_DSNY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "RFO_DSNY", :);
    fuelPriceWeekly.coal_NY = fuelPrice.FuelPricemmBTU(fuelPrice.FuelName == "BIT_NY", :)*ones(height(fuelPriceWeekly),1);
    
    %% Save the data
    writetable(fuelPriceWeekly,outfilename);
    save(matfilename,'fuelPriceWeekly');
    fprintf("Finished writing fuel price data in %s and %s!\n",outfilename,matfilename);
    
else
    
    fprintf("Fuel price data already exists in %s and %s!\n",outfilename,matfilename);
    
end

end