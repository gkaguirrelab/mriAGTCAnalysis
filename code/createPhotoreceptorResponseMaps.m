% Script that downloads the forwardModel results from the Mt Sinai flicker
% frequency experiments, and then fits a difference-of-exponentials model
% to the data. The resulting fits are saved back as maps.

% To find the analysis IDs, get the ID for the session (which is in the URL
% of the web GUI, and then use this command to get a list of the analyses
% associated with that session, and then find the analysis ID the we want.
%
%{
    toolboxName = 'flywheelMRSupport';
    fw = flywheel.Flywheel(getpref(toolboxName,'flywheelAPIKey'));
    sessionID = '5a1fa4b33b71e50019fd55dd';
    analysisList = fw.getSessionAnalyses(sessionID);
%}


% Save location for the maps
subjectNames = {'MELA_5001','MELA_5001','HERO_GKA1'};
analysisIDs = {'60bf58d10225b31ff498256c','60bf58d79f682035099824d6','60bf58cd9f682035099824d4' };
analysisLabels = {'LeftEyeStim','RightEyeStim','RightEyeStim'};
retinoMapIDs = {'5dc88aaee74aa3005e169380','5dc88aaee74aa3005e169380','5dc88aaee74aa3005e169380' };
retinoFileNames = {'TOME_3021_cifti_maps.zip','TOME_3021_cifti_maps.zip','TOME_3021_cifti_maps.zip'};
fieldNameBaseline = 'baseline';
fieldNames = {'LminusM','LMS','S','omni','baseline','attention'};

% Analysis parameters
%scratchSaveDir = getpref('flywheelMRSupport','flywheelScratchDir');
scratchSaveDir = '/Users/aguirre/Desktop/tempFiles';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','output');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Create a flywheel object
fw = flywheel.Flywheel(getpref('forwardModelWrapper','flywheelAPIKey'));

% Loop over subjects
for ss = 1: length(subjectNames)
    
    % Set up the paths for this subject
    fileStem = [subjectNames{ss} '_eventGain_'];
    resultsSaveDir = ['/Users/aguirre/Desktop/' subjectNames{ss}];
    mkdir(resultsSaveDir);
    
    % Download and unzip the retino maps
    fileName = retinoFileNames{ss};
    tmpPath = fullfile(saveDir,fileName);
    fw.downloadOutputFromAnalysis(retinoMapIDs{ss},fileName,tmpPath);
    command = ['unzip -q -n ' tmpPath ' -d ' saveDir];
    system(command);
    
    % Load the retino maps
    tmpPath = fullfile(saveDir,strrep(fileName,'_cifti_maps.zip','_inferred_varea.dtseries.nii'));
    vArea = cifti_read(tmpPath);
    vArea = vArea.cdata;
    tmpPath = fullfile(saveDir,strrep(fileName,'_cifti_maps.zip','_inferred_eccen.dtseries.nii'));
    eccenMap = cifti_read(tmpPath);
    eccenMap = eccenMap.cdata;
    tmpPath = fullfile(saveDir,strrep(fileName,'_cifti_maps.zip','_inferred_angle.dtseries.nii'));
    polarMap = cifti_read(tmpPath);
    polarMap = polarMap.cdata;
    tmpPath = fullfile(saveDir,strrep(fileName,'_cifti_maps.zip','_inferred_sigma.dtseries.nii'));
    sigmaMap = cifti_read(tmpPath);
    sigmaMap = sigmaMap.cdata;
    
    % Download the results file
    fileName = [fileStem 'results.mat'];
    tmpPath = fullfile(saveDir,[analysisLabels{ss} '_' fileName]);
    fw.downloadOutputFromAnalysis(analysisIDs{ss},fileName,tmpPath);
    
    % Load the result file into memory and delete the downloaded file
    clear results
    load(tmpPath,'results')
    %        delete(tmpPath)
    
    % Download the templateImage file
    fileName = [fileStem 'templateImage.mat'];
    tmpPath = fullfile(saveDir,[analysisLabels{ss} '_' fileName]);
    fw.downloadOutputFromAnalysis(analysisIDs{ss},fileName,tmpPath);
    
    % Load the result file into memory and delete the downloaded file
    clear templateImage
    load(tmpPath,'templateImage')
    %        delete(tmpPath)
        
    % Obtain the results vs. the baseline condition
    saveFieldNames = {};
    for ff = 1:length(fieldNames)
        if strcmp(fieldNames{ff},fieldNameBaseline)
            continue
        end
        saveFieldNames{ff} = [fieldNames{ff} '_zVal'];
        results.(saveFieldNames{ff}) = (results.(fieldNames{ff})-results.(fieldNameBaseline)) ./ ...
        results.fVal;
    end

    saveFieldNames = [saveFieldNames 'R2'];
    
    % Save the map results into images
    for ff = 1:length(saveFieldNames)
        if isempty(saveFieldNames{ff})
            continue
        end
        % The initial, CIFTI space image
        outCIFTIFile = fullfile(resultsSaveDir, [subjectNames{ss} '_' analysisLabels{ss} '_' saveFieldNames{ff} '.dtseries.nii']);
        outData = templateImage;
        outData.cdata = single(results.(saveFieldNames{ff}));
        outData.diminfo{1,2}.length = 1;
        cifti_write(outData, outCIFTIFile)
    end

    % The vertices to plot
    goodIdx = logical((results.R2 > 0.05).*(eccenMap>0.05).*(vArea==1));

    % Left and right hemisphere
    polarMap(32492:end)=-polarMap(32492:end);
    
    % generate visual field map
    figHandle = figure( 'Position',  [100, 100, 800, 300],'PaperOrientation','landscape');
    plotSet = [1 2 4];
    for ff = 1:length(plotSet)
        subplot(1,3,ff);
        createFieldMap(results.(saveFieldNames{plotSet(ff)})(goodIdx),polarMap(goodIdx),eccenMap(goodIdx),sigmaMap(goodIdx),[-1 1]);
        title(saveFieldNames{plotSet(ff)},'Interpreter', 'none');
    end
    sgtitle([subjectNames{ss} '_' analysisLabels{ss}],'Interpreter', 'none');
    outFigureFile = fullfile(resultsSaveDir, [subjectNames{ss} '_' analysisLabels{ss} '_FieldMap.pdf']);
    print(figHandle,outFigureFile,'-dpdf','-fillpage');
    close(figHandle);
    
end



