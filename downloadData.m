function msg = downloadData()
%DOWNLOADDATA Download market operation data from NYISO's website
%
%   Download NYISO hourly fuel mix data, hourly interface flow data, hourly
%   real-time price data, hourly real-time load data from NYISO's OASIS,
%   and hourly real-time generation data in NY from RGGI.

%   Created by Bo Yuan, Cornell University
%   Last modifed on September 9, 2021

%% Input settings
close all;
clc;
prepDir = 'Prep';
createDir(prepDir);
year = 2019;
apiroot = "http://mis.nyiso.com/public/csv/";

%% Download fuel mix data
fuelmixDir = fullfile(prepDir,'fuelmix');
createDir(fuelmixDir);
api = apiroot+"/rtfuelmix/";
suffix = "rtfuelmix_csv.zip";
fprintf("Downloading and unzipping NYISO fuel mix data in %d ... ",year);
msg = yearlyDownload(api,suffix,fuelmixDir,year);
fprintf("%s\n",msg);

%% Download interface flow data
interfaceDir = fullfile(prepDir,'interflow');
createDir(interfaceDir);
api = apiroot+"ExternalLimitsFlows/";
suffix = "ExternalLimitsFlows_csv.zip";
fprintf("Downloading and unzipping NYISO interface flow data in %d ... ",year);
msg = yearlyDownload(api,suffix,interfaceDir,year);
fprintf("%s\n",msg);

%% Download real-time price data
rtpriceDir = fullfile(prepDir,'rtprice');
createDir(rtpriceDir);
api = apiroot+"realtime/";
suffix = "realtime_zone_csv.zip";
fprintf("Downloading and unzipping NYISO real-time price data in %d ... ",year);
msg = yearlyDownload(api,suffix,rtpriceDir,year);
fprintf("%s\n",msg);

%% Download hourly integrated real-time load data
rtloadDir = fullfile(prepDir, 'rtload');
createDir(rtloadDir);
api = apiroot+"palIntegrated/";
suffix = "palIntegrated_csv.zip";
fprintf("Downloading and unzipping NYISO real-time load data in %d ...",year);
msg = yearlyDownload(api,suffix,rtloadDir,year);
fprintf("%s\n",msg);

%% Downlaod hourly generation data from RGGI
rtgenDir = fullfile(prepDir, 'rtgen');
createDir(rtgenDir);
api = "https://gaftp.epa.gov/DMDnLoad/emissions/hourly/monthly/2019/";
suffix = "ny";
fprintf("Downloading and unzipping RGGI NY real-time generation data in %d ...",year);
msg = yearlyDownload(api,suffix,rtgenDir,year);
fprintf("%s\n",msg);

msg = "Success!";

end

%% Utility functions
function msg = yearlyDownload(api, suffix, dir, year)
if nargin <= 3 && isempty(year)
    year = 2019; % Default to download data in 2019
end
try
    for month = 1:12
        if contains(api, "nyiso")
            filename = sprintf('%d%02d%02d',year,month,1)+suffix;
        elseif contains(api, "epa")
            filename = sprintf('%d%s%02d.zip',year,suffix,month);
        else
            error("Error: Undefined api format!");
        end
        % Download data
        url = api+filename;
        outfilename = websave(fullfile(dir,filename),url);
        % Unzip data
        unzip(outfilename,dir);
        % Delete the zip file
        delete(outfilename);
    end
    msg = "Success!";
catch ME
    msg = ME.message;
end
end

function createDir(dir)
if isfolder(dir)
    fprintf("Directory already exists: %s!\n",dir);
else
    mkdir(dir);
    fprintf("Created Directory: %s!\n",dir);
end
end
