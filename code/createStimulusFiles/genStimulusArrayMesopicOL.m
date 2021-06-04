projectName = 'mriAGTCAnalysis';

clear protocolParams responseStruct block responseTypes stimulusFull stimTimeFull performanceFull
    
dataPath =    getpref(projectName,'dataPath');
analysisPath =   getpref(projectName, 'analysisPath');
projectDataDir = fullfile(dataPath,'Experiments','OLApproach_TrialSequenceMR','MRAGTC','DataFiles');
selpath = uigetdir(projectDataDir,'Select a session directory (i.e., session_1)');
matFileList = dir(fullfile(selpath,'*.mat'));

% Load the the next acquisition file
for ii = 1:length(matFileList)
    
    % Assemble the file name. This is to enfoce the loading order
    load(fullfile(selpath,matFileList(ii).name),'protocolParams','responseStruct','block');

    trialOrder = protocolParams.trialTypeOrder(2,:);    
    deltaT = 0.1;
    trialDuration = protocolParams.trialDuration;
    nTrials = length(trialOrder);
    temporalSupport = 0:0.1:(trialDuration*nTrials)-deltaT;
    nTrialTypes = length(unique(trialOrder));
    stimMat = zeros(nTrialTypes+1,length(temporalSupport));
    
    for ss = 1:nTrialTypes
        for tt = 1:nTrials
            if trialOrder(tt)==ss
                startIdx = 1+(tt-1)*trialDuration/deltaT;
                stimMat(ss,startIdx:startIdx+trialDuration/deltaT-1)=1;
            end
        end
    end
    
    % Add the attention task and record performance
    for tt = 1:nTrials
        buttonPress = false;
        if any(responseStruct.events(tt).buffer.keyCode~=18)
            buttonPress = true;
        end
        
        
        if block(tt).attentionTask.theStartBlankIndex ~= -1
            startIdx = 1+(tt-1)*trialDuration/deltaT;
            theStartBlankIndex = round(block(tt).attentionTask.theStartBlankIndex/100./deltaT);
            theStopBlankIndex = round(block(tt).attentionTask.theStopBlankIndex/100./deltaT);
            stimMat(nTrialTypes+1,startIdx+theStartBlankIndex:startIdx+theStopBlankIndex)=1;
            if buttonPress
                responseTypes(1,tt) = 1; % Hit
            else
                responseTypes(2,tt) = 1; % Miss
            end
        else
            if buttonPress
                responseTypes(3,tt) = 1; % False alarm
            else
                responseTypes(4,tt) = 1; % Correct rejection
            end
        end
    end
    
    stimulusFull{ii}=stimMat;
    stimTimeFull{ii}=temporalSupport;
    performanceFull{ii}=responseTypes;
    
    clear protocolParams responseStruct block responseTypes
end


% Summarize performance
scores = sum(cell2mat(cellfun(@(x) sum(x,2),performanceFull,'UniformOutput',false)),2);
fprintf('hits: %d, miss: %d, false alarm: %d, cr: %d \n',scores);
