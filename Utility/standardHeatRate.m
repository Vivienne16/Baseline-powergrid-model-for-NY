function HeatRateLM_1 = standardHeatRate(unitType, fuelType)
switch unitType
    case "Combined Cycle"
        switch fuelType
            case "Natural Gas"
                HeatRateLM_1 = 7.633;
            case {"Fuel Oil 2","Fuel Oil 6","Kerosene"}
                HeatRateLM_1 = 9.662;
            otherwise
                disp("Error: Undefined fuel type!");
        end            
    case {"Combustion Turbine", "Jet Engine"}
        switch fuelType
            case "Natural Gas"
                HeatRateLM_1 = 11.098;
            case {"Fuel Oil 2","Fuel Oil 6","Kerosene"}
                HeatRateLM_1 = 13.315;
            otherwise
                disp("Error: Undefined fuel type!");
        end                
     case "Internal Combustion"
        switch fuelType
            case "Natural Gas"
                HeatRateLM_1 = 8.899;
            case {"Fuel Oil 2","Fuel Oil 6","Kerosene"}
                HeatRateLM_1 = 10.325;
            otherwise
                disp("Error: Undefined fuel type!");
        end
    case "Steam Turbine"
        switch fuelType
            case "Natural Gas"
                HeatRateLM_1 = 10.347;
            case {"Fuel Oil 2","Fuel Oil 6","Kerosene"}
                HeatRateLM_1 = 10.236;
            case "Coal"
                HeatRateLM_1 = 10.002;
            otherwise
                disp("Error: Undefined fuel type!");
        end
    otherwise
            disp("Error: Undefined unit type!");
end
end

