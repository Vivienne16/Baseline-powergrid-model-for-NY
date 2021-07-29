close all;
clear all;
clc

%% MPC modification
% Load original NPCC-140 bus MATPOWER case
load('Data/npcc.mat','mpc');

% Add MOST constant parameter names
define_constants;

%% delete transmission lines between PJM and IESO
mpc.branch(find((mpc.branch(:,1) == 84).*(mpc.branch(:,2)==116)==1),:)=[];
mpc.branch(find((mpc.branch(:,1) == 87).*(mpc.branch(:,2)==115)==1),:)=[];
mpc.branch(find((mpc.branch(:,1) == 90).*(mpc.branch(:,2)==114)==1),:)=[];

% fix negative load
mpc.bus(:,3) = abs(mpc.bus(:,3));

%% update branch limit external
%PJM 124-75, 125-81, 134-66, 138-67
mpc.branch(find((mpc.branch(:,1) == 66).*(mpc.branch(:,2)==134)==1),6) = 315;
mpc.branch(find((mpc.branch(:,1) == 67).*(mpc.branch(:,2)==138)==1),6) = 660;
mpc.branch(find((mpc.branch(:,1) == 81).*(mpc.branch(:,2)==125)==1),6) = 660;
mpc.branch(find((mpc.branch(:,1) == 75).*(mpc.branch(:,2)==124)==1),6) = 2000;
% mpc.branch(find((mpc.branch(:,1) == 60).*(mpc.branch(:,2)==140)==1),6) = 550;

% 
% NE 29-37 35-73
mpc.branch(find((mpc.branch(:,1) == 29).*(mpc.branch(:,2)==37)==1),6:8) = 200;
mpc.branch(find((mpc.branch(:,1) == 35).*(mpc.branch(:,2)==73)==1),6:8) = 1400;
% 
%IESO 100-48 102-54 103-54
mpc.branch(find((mpc.branch(:,1) == 48).*(mpc.branch(:,2)==100)==1),6) = 450;
mpc.branch(find((mpc.branch(:,1) == 54).*(mpc.branch(:,2)==102)==1),6) = 650;
mpc.branch(find((mpc.branch(:,1) == 54).*(mpc.branch(:,2)==103)==1),6) = 650;

%% Update bus types
%PQ - PV
mpc.bus(mpc.bus(:,1) == 39,2) = 2;
mpc.bus(mpc.bus(:,1) == 77,2) = 2;
mpc.bus(mpc.bus(:,1) == 45,2) = 2;
mpc.bus(mpc.bus(:,1) == 62,2) = 2;

%PV -PQ
mpc.bus(mpc.bus(:,1) == 72,2) = 1;
mpc.bus(mpc.bus(:,1) == 53,2) = 1;
mpc.bus(mpc.bus(:,1) == 54,2) = 1;
mpc.bus(mpc.bus(:,1) == 68,2) = 1;

%slack
mpc.bus(mpc.bus(:,1) == 78,2) = 1;
mpc.bus(mpc.bus(:,1) == 74,2) = 3;

%% Add branch
% add E-G 
addline = [38 77 0.02 0.02 0 0 0 0 0 0 1 -360 360];
mpc.branch = [mpc.branch;addline];

%% Save updated MATPOWER case
save('Result/mpcupdated.mat','mpc')