close all;
clear all;
clc;

%% Input settings
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
interfaceDir = fullfile(prepDir,'interface');
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

%% Functions
function msg = yearlyDownload(api, suffix, dir, year)
if nargin <= 3 && isempty(year)
    year = 2019; % Default to download data in 2019
end
try
    for month = 1:12
        filename = sprintf('%d%02d%02d',year,month,1)+suffix;
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

