function nfbSave(indVol)
% Function to clear workspase and save the necessary information.
%
% input:
% indVol - volume(scan) index
% Workspace variables.
%
% output:
% Output is a storage into the neurofeedback run directory.
%__________________________________________________________________________
% Copyright (C) 2016-2021 OpenNFT.org
%
% Written by Yury Koush, Artem Nikonorov

disp('Save...')

P = evalin('base', 'P');
mainLoopData = evalin('base', 'mainLoopData');


if P.UseTCPData
    tcp = evalin('base', 'tcp');
    tcp.CloseConnection;
end

flags = getFlagsType(P);

if isfield(P, 'nfbDataFolder')
    folder = P.nfbDataFolder;
else
    return;
end

% save rtqa data
if P.isRTQA
    rtQA_matlab = evalin('base', 'rtQA_matlab');
    rtQA_python = evalin('base', 'rtQA_python');
    save([folder '\rtQA_matlab.mat'], '-struct', 'rtQA_matlab');
    save([folder '\rtQA_python.mat'], '-struct', 'rtQA_python');
end

% % save last volume stat data for offline access
if mainLoopData.statMapCreated
    slNrImg2DdimX = mainLoopData.slNrImg2DdimX;
    slNrImg2DdimY = mainLoopData.slNrImg2DdimY;
    img2DdimX = mainLoopData.img2DdimX;
    img2DdimY = mainLoopData.img2DdimY;
    dimVol = mainLoopData.dimVol;
    tn = mainLoopData.tn;
    indVolIglmIndx = length(mainLoopData.idxActVoxIGLM.pos);
    idxActVoxIGLM.pos = mainLoopData.idxActVoxIGLM.pos{indVolIglmIndx};
    statMap3D_pos = mainLoopData.statMap3D_pos;
    statMap3D_neg = mainLoopData.statMap3D_neg;

    maskedStatMapVect = tn.pos(idxActVoxIGLM.pos);
    maxTval = max(maskedStatMapVect);
    if isempty(maxTval)
        maxTval = 1;
    end
    statMapVect = maskedStatMapVect;
    statMap3D_pos(idxActVoxIGLM.pos) = statMapVect;

    idxActVoxIGLM.neg = mainLoopData.idxActVoxIGLM.neg{indVolIglmIndx};
    maskedStatMapVect = tn.neg(idxActVoxIGLM.neg);
    maxTval = max(maskedStatMapVect);
    if isempty(maxTval)
        maxTval = 1;
    end
    statMapVect = maskedStatMapVect;
    statMap3D_neg(idxActVoxIGLM.neg) = statMapVect;
    
    if P.isRTQA
        assignin('base', 'rtQA_matlab', rtQA_matlab);
     end
    
end

% save feedback values
if ~P.isAutoRTQA
    % check if vectNFBs exists
    if sum(strcmp(fieldnames(mainLoopData), 'vectNFBs')) == 1
        save([folder filesep P.SubjectID '_' ...
            num2str(P.NFRunNr) '_NFBs' '.mat'], ...
            '-struct', 'mainLoopData', 'vectNFBs');
    end
end

% save time-series
if P.NrROIs >0
    save([folder filesep P.SubjectID '_' ...
        num2str(P.NFRunNr) '_raw_tsROIs' '.mat'], ...
        '-struct', 'mainLoopData', 'rawTimeSeries');
    save([folder filesep P.SubjectID '_' ...
        num2str(P.NFRunNr) '_proc_tsROIs' '.mat'], ...
        '-struct', 'mainLoopData', 'kalmanProcTimeSeries');
end

%% Configuration
% save parameters
save([folder filesep P.SubjectID '_' ...
    num2str(P.NFRunNr) '_mainLoopData' '.mat'],'-struct','mainLoopData');
save([folder filesep P.SubjectID '_' ...
    num2str(P.NFRunNr) '_P' '.mat'], '-struct', 'P');

% save ROIs
if flags.isPSC || flags.isSVM || flags.isCorr
    roiData.ROIs = evalin('base', 'ROIs');
end
if flags.isDCM
    roiData.ROIsAnat = evalin('base', 'ROIsAnat');
    roiData.ROIsGroup = evalin('base', 'ROIsGroup');
    roiData.ROIsGlmAnat = evalin('base', 'ROIsGlmAnat');
    roiData.ROIoptimGlmAnat = evalin('base', 'ROIoptimGlmAnat');
end
if ~P.isAutoRTQA
    save([folder filesep P.SubjectID '_' ...
        num2str(P.NFRunNr) '_roiData' '.mat'], 'roiData');
end

%% Results
if isfield(mainLoopData, 'vectNFBs')
    
    % save feedback values
    save([folder filesep P.SubjectID '_' ...
        num2str(P.NFRunNr) '_NFBs' '.mat'], ...
        '-struct', 'mainLoopData', 'vectNFBs');
    
    % save time-series
    if P.NrROIs >0
        save([folder filesep P.SubjectID '_' ...
            num2str(P.NFRunNr) '_raw_tsROIs' '.mat'], ...
            '-struct', 'mainLoopData', 'rawTimeSeries');
        save([folder filesep P.SubjectID '_' ...
            num2str(P.NFRunNr) '_proc_tsROIs' '.mat'], ...
            '-struct', 'mainLoopData', 'kalmanProcTimeSeries');
    end
    
    % save reward values
    if strcmp(P.Prot, 'Inter') && strcmp(P.Type, 'PSC')
        % save reward vector for subsequent NF run, i.e. it becomes previous
        if isfield(P, 'actValue')
            prev_actValue = P.actValue;
        else
            prev_actValue = 0;
            fprintf('\nCheck Reward algorithm!\n');
        end
        save([folder filesep 'reward_' sprintf('%02d',P.NFRunNr) '.mat'], ...
            'prev_actValue');
    end
    
    % save activation map(s)
    folder = [P.WorkFolder filesep 'NF_Data_' num2str(P.NFRunNr)];
    if ~isempty(mainLoopData.statMap3D_iGLM)
        if ~flags.isDCM
            statVolData = mainLoopData.statMap3D_iGLM;
            save([folder filesep 'statVolData_' ...
                sprintf('%02d',P.NFRunNr) '.mat'], 'statVolData');
        else
            for iDcmBlock = 1: size(mainLoopData.statMap3D_iGLM,4)
                statVolData = ...
                    squeeze(mainLoopData.statMap3D_iGLM(:,:,:, iDcmBlock));
                save([folder filesep 'statVolData_' ...
                    sprintf('%02d',iDcmBlock) '.mat'],'statVolData');
            end
        end
    end
    
    % concatenate two TimeVector event files
    fileTimeVectors_display = [folder filesep 'TimeVectors_display_' ...
        sprintf('%02d', P.NFRunNr) '.txt'];
    
    if ~flags.isSVM && exist(fileTimeVectors_display, 'file')
        recs = load([folder filesep 'TimeVectors_' ...
            sprintf('%02d', P.NFRunNr) '.txt']);
        recsDisplay = load(fileTimeVectors_display);
        sz = size(recs);
        % Times.t9 and Times.t10
        tmpVect = 1:size(recsDisplay,1);
        recs(tmpVect, 10:11) = recsDisplay(:,1:2);
        % Abs Matlab PTB Helper times for display
        recs(tmpVect, sz(2)+1:sz(2)+2) = recsDisplay(:,3:4);
        save([folder filesep 'TimeVectors_' ...
            sprintf('%02d', P.NFRunNr) '.txt'], 'recs', '-ascii', '-double');
    end
    
end

disp('Saving done')

% Clear workspace
evalin('base', 'clear mmTransferVol;');
evalin('base', 'clear mmStatVol;');
evalin('base', 'clear mmOrthView;');
