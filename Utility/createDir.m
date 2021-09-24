function createDir(dir)
%CREATEDIR  Determine if a directory exist and create it if not.

%   Created by Bo Yuan, Cornell University
%   Last modified on Sept. 23, 2021

if isfolder(dir)
    fprintf("Directory already exists: %s!\n",dir);
else
    mkdir(dir);
    fprintf("Created Directory: %s!\n",dir);
end
end