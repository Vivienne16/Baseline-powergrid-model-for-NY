clear all
addpath(genpath("."))
addpath(genpath([pwd filesep 'matpower']));
% Save figure or not
savefig = true;
% Save PF and OPF results or not
savedata = true; 
% Verbose printing or not
verbose = false; 
% Add additional renewable or not
addrenew = false; 
% Read mat files, otherwise read csv files
usemat = true;
% Add project to MATLAB path
addpath(genpath("."))
year = 2019;
mpc = modifyMPC();
pfval = [];
load('Data/interflowHourly_2019.mat')

interflowHourly.month = month(interflowHourly.TimeStamp);
interflowHourly.day = day(interflowHourly.TimeStamp);
interflowHourly.hour = hour(interflowHourly.TimeStamp);
InterFlow = interflowHourly;
for month = 1:12
    if ismember(month,[1,3,5,7,8,10,12])
        darange = 31;
    elseif ismember(month,[4,6,9,11])
        darange = 30;
    else
        darange = 28;
    end
    for day = 1:darange
        for hour = 0:23
            timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
                fprintf("Start running %s ...\n",datestr(timeStamp));
                % Update operation conditions
                mpcreduced = updateOpCond(mpc,timeStamp,savedata,verbose,usemat);
                % Add additional renewables if provided
            
            subflow = InterFlow(InterFlow.hour == hour&InterFlow.day==day&InterFlow.month==month,:);
            flowlimit = subflow(:,{'InterfaceName','PositiveLimitMWH','NegativeLimitMWH'});
            subflow = subflow(:,{'InterfaceName','FlowMWH'});
            subflow = groupsummary(subflow,'InterfaceName','mean');
            flowlimit = groupsummary(flowlimit,'InterfaceName','mean');
            if isempty(flowlimit)
                continue
            end
            oripf = rundcpf(mpc);
            repf = rundcpf(mpcreduced);
            obus = oripf.bus;
            obranch = oripf.branch;
            ogen = oripf.gen;
            rbus = repf.bus;
            rbranch = repf.branch;
            rgen = repf.gen;
            pferr = [];
            for i = 1:length(rbranch(rbranch(:,6)<999))
                ind1 = find(obranch(:,1) == rbranch(i,1));
                ind2 = find(obranch(:,2) == rbranch(i,2));
                ind = intersect(ind1,ind2);
                if min(obus(rbranch(i,1),10),obus(rbranch(i,2),10)) >= 500
                    ratefactor = 2700;
                end
                if min(obus(rbranch(i,1),10),obus(rbranch(i,2),10)) >= 345 && min(obus(rbranch(i,1),10),obus(rbranch(i,2),10)) < 500
                    ratefactor = 1650;
                end
                if min(obus(rbranch(i,1),10),obus(rbranch(i,2),10)) >= 200 && min(obus(rbranch(i,1),10),obus(rbranch(i,2),10)) >=230
                    ratefactor = 650;
                end
                if min(obus(rbranch(i,1),10),obus(rbranch(i,2),10)) >= 115 && min(obus(rbranch(i,1),10),obus(rbranch(i,2),10)) <120
                    ratefactor = 175;
                end
                if  min(obus(rbranch(i,1),10),obus(rbranch(i,2),10)) <50
                    ratefactor = 85;
                end
                for kk = length(ind)
                    pferr = [pferr abs(rbranch(i,14)-obranch(ind(kk),14))/ratefactor];
                end
            end
           
            idx = 37:82;
            Verr = [];
            theaerr = [];
            Perr = [];
            Qerr = [];
            for i = 1:length(idx)
                indr = find(rbus(:,1)==idx(i));
                indo = find(obus(:,1)==idx(i));
                Verr(i) = abs(rbus(indr,8)-obus(indo,8));
                theaerr(i) = abs(rbus(indr,9)-obus(indo,9));
                Perr(i) = abs(rbus(indr,3)-obus(indo,3));
                Qerr(i) = abs(rbus(indr,4)-obus(indo,4));
            end
            %% 37 in G
%             DYSINGEREAST = -rbranch(32,14)+rbranch(34,14)+rbranch(37,14)+rbranch(47,14);
%             Westcentral = -rbranch(28,14)-rbranch(29,14)+rbranch(33,14)+rbranch(50,14);
%             % Totaleast = -rbranch(16,14)-rbranch(20,14)-rbranch(21,14)+rbranch(56,14)-rbranch(62,14)+rbranch(8,14);
%             Totaleast = -rbranch(14,14)-rbranch(12,14)-rbranch(3,14)-rbranch(6,14)+rbranch(8,14);
%             mosesouth = -rbranch(24,14)-rbranch(18,14)-rbranch(23,14);
%             centraleast = -rbranch(14,14)-rbranch(12,14)-rbranch(3,14)-rbranch(6,14);
%             upnyconed = rbranch(65,14)-rbranch(66,14);
%             sprdunsouth = rbranch(73,14)+rbranch(74,14);
%MScase3
            DYSINGEREAST = -rbranch(33,14)+rbranch(35,14)+rbranch(38,14)+rbranch(48,14);
            Westcentral = -rbranch(29,14)-rbranch(30,14)+rbranch(34,14)+rbranch(51,14);
            % Totaleast = -rbranch(16,14)-rbranch(20,14)-rbranch(21,14)+rbranch(56,14)-rbranch(62,14)+rbranch(8,14);
            Totaleast = -rbranch(14,14)-rbranch(12,14)-rbranch(3,14)-rbranch(6,14)+rbranch(8,14);
            mosesouth = -rbranch(25,14)-rbranch(19,14)-rbranch(24,14);
            centraleast = -rbranch(14,14)-rbranch(12,14)-rbranch(3,14)-rbranch(6,14);
            upnyconed = rbranch(66,14)-rbranch(67,14);
            sprdunsouth = rbranch(74,14)+rbranch(75,14);
% % 765KV
%             DYSINGEREAST = -rbranch(34,14)+rbranch(36,14)+rbranch(39,14)+rbranch(49,14);
%             Westcentral = -rbranch(30,14)-rbranch(31,14)+rbranch(35,14)+rbranch(52,14);
%             % Totaleast = -rbranch(16,14)-rbranch(20,14)-rbranch(21,14)+rbranch(56,14)-rbranch(62,14)+rbranch(8,14);
%             Totaleast = -rbranch(14,14)-rbranch(12,14)-rbranch(3,14)-rbranch(6,14)+rbranch(8,14);
%             mosesouth = -rbranch(26,14)-rbranch(19,14)-rbranch(24,14);
%             centraleast = -rbranch(14,14)-rbranch(12,14)-rbranch(3,14)-rbranch(6,14);
%             upnyconed = rbranch(67,14)-rbranch(68,14);
%             sprdunsouth = rbranch(75,14)+rbranch(76,14);
            
            CE = subflow.mean_FlowMWH(string(subflow.InterfaceName) == 'CENTRAL EAST - VC');
            WC = subflow.mean_FlowMWH(string(subflow.InterfaceName) == 'WEST CENTRAL');
            TE = subflow.mean_FlowMWH(string(subflow.InterfaceName) == 'TOTAL EAST');
            MS = subflow.mean_FlowMWH(string(subflow.InterfaceName) == 'MOSES SOUTH');
            DY = subflow.mean_FlowMWH(string(subflow.InterfaceName) == 'DYSINGER EAST');
            UC = subflow.mean_FlowMWH(string(subflow.InterfaceName) == 'UPNY CONED');
            SDS = subflow.mean_FlowMWH(string(subflow.InterfaceName) == 'SPR/DUN-SOUTH');
            
            A_B = flowlimit(string(flowlimit.InterfaceName) == 'DYSINGER EAST',:);
            B_C = flowlimit(string(flowlimit.InterfaceName) == 'WEST CENTRAL',:);
            C_E = flowlimit(string(flowlimit.InterfaceName) == 'TOTAL EAST',:);
            D_E = flowlimit(string(flowlimit.InterfaceName) == 'MOSES SOUTH',:);
            E_F = flowlimit(string(flowlimit.InterfaceName) == 'CENTRAL EAST - VC',:);
            G_H = flowlimit(string(flowlimit.InterfaceName) == 'UPNY CONED',:);
            I_J = flowlimit(string(flowlimit.InterfaceName) == 'SPR/DUN-SOUTH',:);
            
            
            % DCE = abs(CE - centraleast);
            % DWC = abs(WC - Westcentral);
            % DTE = abs(TE - Totaleast);
            % DMS = abs(MS - mosesouth);
            % DDY = abs(DY - DYSINGEREAST);
            % DUC = abs(UC - upnyconed);
            % DSDS = abs(SDS - sprdunsouth);
            
            DCE = CE - centraleast;
            DWC = WC - Westcentral;
            DTE = TE - Totaleast;
            DMS = MS - mosesouth;
            DDY = DY - DYSINGEREAST;
            DUC = UC - upnyconed;
            DSDS = SDS - sprdunsouth;
            
            pfval = [pfval;[month,day,hour,mean(pferr),mean(Verr),mean(Perr),CE,WC,TE,MS,DY,UC,SDS,DCE,DWC,DTE,DMS,DDY,DUC,DSDS,...
                A_B.mean_PositiveLimitMWH,B_C.mean_PositiveLimitMWH,C_E.mean_PositiveLimitMWH,D_E.mean_PositiveLimitMWH,...
                E_F.mean_PositiveLimitMWH,G_H.mean_PositiveLimitMWH,I_J.mean_PositiveLimitMWH]];

        end
    end
end
writematrix(pfval,'pf2018.csv')