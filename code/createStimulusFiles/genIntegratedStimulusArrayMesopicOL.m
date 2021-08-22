%{
    save('/Users/aguirre/Desktop/MELA_5001_stim.mat','stimulus','stimTime')
%}

projectName = 'mriAGTCAnalysis';

clear protocolParams responseStruct block responseTypes stimulus stimTime performance

% Load the two mat file lists
dataPath =    getpref(projectName,'dataPath');
analysisPath =   getpref(projectName, 'analysisPath');
projectDataDir = fullfile(dataPath,'Experiments','OLApproach_TrialSequenceMR','MRAGTC','DataFiles');
title_str = 'Select the RIGHT eye stim session directory';
if ~ispc; menu(title_str,'OK'); end
selpathRight = uigetdir(projectDataDir,projectDataDir);
matFileListRightEye = dir(fullfile(selpathRight,'*.mat'));
if mod(length(matFileListRightEye),2)==1
    error('There must be an even number of acquisitions');
end

title_str = 'Select the LEFT eye stim session directory';
if ~ispc; menu(title_str,'OK'); end
selpathLeft = uigetdir(projectDataDir,projectDataDir);
matFileListLeftEye = dir(fullfile(selpathLeft,'*.mat'));
if mod(length(matFileListLeftEye),2)==1
    error('There must be an even number of acquisitions');
end

eyeLabel = [repmat({'R'},1,length(matFileListRightEye)) repmat({'L'},1,length(matFileListLeftEye))];
acqIdx = [1:length(matFileListRightEye) 1:length(matFileListLeftEye)];
matFileList = [matFileListRightEye; matFileListLeftEye];

% Define some stimulus variables
stimulus = {};
condLabels = {'LminusM','LMS','S','omni','baseline','attention'};
nConds = length(condLabels);
nCols = nConds*length(matFileList);
stimLabels = '(stimLabels),{';

stimMatIdx = 0;

% Load the the next acquisition file
for ii = 1:length(matFileList)
    
    load(fullfile(matFileList(ii).folder,matFileList(ii).name),'protocolParams','responseStruct','block');
    trialOrder = protocolParams.trialTypeOrder(2,:);
    deltaT = 0.1;
    trialDuration = protocolParams.trialDuration;
    nTrials = length(trialOrder);
    temporalSupport = 0:0.1:(trialDuration*nTrials)-deltaT;
    nTrialTypes = length(unique(trialOrder));
    stimMat = zeros(nCols,length(temporalSupport));
    
    for ss = 1:nTrialTypes
        for tt = 1:nTrials
            if trialOrder(tt)==ss
                startIdx = 1+(tt-1)*trialDuration/deltaT;
                stimMat(ss+stimMatIdx*nConds,startIdx:startIdx+trialDuration/deltaT-1)=1;
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
            stimMat(nTrialTypes+1+stimMatIdx*nConds,startIdx+theStartBlankIndex:startIdx+theStopBlankIndex)=1;
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
    
    stimulus{ii}=stimMat;
    stimTime{ii}=temporalSupport;
    performance{ii}=responseTypes;
    
    theseLabels = cellfun(@(x) ['(' x '_' eyeLabel{ii} '_' sprintf('%0.2d',acqIdx(ii)) '),'],condLabels,'UniformOutput',false);
    theseLabels = strcat(theseLabels{:});
    stimLabels = [stimLabels theseLabels];
        
    stimMatIdx = stimMatIdx+1;
    
    clear protocolParams responseStruct block responseTypes
end

% Remove trailing comma from the stimLabels and cap with bracket
stimLabels = [stimLabels(1:end-1) '}' ];

% Add the acquisition index averaging
avgAcqIdx = '(avgAcqIdx),{';
for ii=1:length(matFileList)/2
    avgAcqIdx = [avgAcqIdx sprintf('%d:%d,',1+(ii-1)*500,ii*500)];
end
avgAcqIdx = [avgAcqIdx(1:end-1) '}' ];

% Assemble the modelOpts
modelOpts = ['''' '(polyDeg),13,' stimLabels ',(confoundStimLabel),(attention),' avgAcqIdx ''''];
fprintf([modelOpts '\n']);

% Summarize performance
scores = sum(cell2mat(cellfun(@(x) sum(x,2),performance,'UniformOutput',false)),2);
fprintf('hits: %d, miss: %d, false alarm: %d, cr: %d \n',scores);
