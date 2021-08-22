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
subjectNames = {...
    'MELA_5004','MELA_5004',...
    'MELA_5010','MELA_5010',...
    'MELA_5009','MELA_5009',...
    'MELA_5008','MELA_5008',...
    'MELA_5007','MELA_5007',...
    'MELA_5006','MELA_5006',...
    'MELA_5001','MELA_5001',...
    'MELA_5002','MELA_5002',...
    'MELA_5005','MELA_5005',...,
    'HERO_GKA1'};
analysisIDs = {...
    '60fc8ee91d0da96a50dd8ec9','60fc8ede32d34cfe5ce07630',...
    '60faa6844a153559b9dd9155','60faa654f0ef61900396c880',...
    '60f40daea5405aab2156ad52','60f40da99fed514b76dd8f8a',...
    '60f2b39592808809a556b037','60f2b3909a93f718cadd9005',...
    '60eebf73d06c186a1de073fd','60eebf63a2560bbf7596c724',...
    '60deefe748354d64a8e07913','60deefeb6727937a59dd8e12',...
    '60c23c071dc0f01275982182','60c23c0122a03af03c43f4e3',...
    '60c23bfed8d2fe65073d0684','60c23bf9927feec9c02a88e6',...
    '60db6cf8c1b37b22ee2b6dc9','611c17fea2eccf0ba5a2db70',...
    '60c23c1681ba4f28a42a88a8' };
analysisLabels = {...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim','LeftEyeStim',...
    'RightEyeStim'};

retinoMapID = '5dc88aaee74aa3005e169380';
retinoFileName = 'TOME_3021_cifti_maps.zip';

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
for ss = 1:length(subjectNames)
    
    % Set up the paths for this subject
    fileStem = [subjectNames{ss} '_agtcOL_'];
    resultsSaveDir = ['/Users/aguirre/Desktop/AGTC_OL/' subjectNames{ss}];
    mkdir(resultsSaveDir);
    
    % Download and unzip the retino maps
    fileName = retinoFileName;
    tmpPath = fullfile(saveDir,fileName);
    fw.downloadOutputFromAnalysis(retinoMapID,fileName,tmpPath);
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
        results.(saveFieldNames{ff}) = results.(fieldNames{ff})-results.(fieldNameBaseline);
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
    
    
    % Left and right hemisphere
    polarMap(32492:end)=-polarMap(32492:end);
    
    % generate visual field map
    figHandle = figure( 'Position',  [100, 100, 800, 300],'PaperOrientation','landscape');
    plotSet = [1 2 3 4 6 7];
    for ff = 1:length(plotSet)
        subplot(3,3,ff);
        % The vertices to plot
        if ff<=4
            goodIdx = logical((results.attention > 1).*(results.R2 > 0.1).*(eccenMap>0.1).*(vArea==1));
            vals = results.(saveFieldNames{plotSet(ff)})(goodIdx) ./ results.attention(goodIdx);
            range = [-0.1 0.1];
        else
            goodIdx = logical((results.R2 > 0.00).*(eccenMap>0.1).*(vArea==1));
            vals = results.(saveFieldNames{plotSet(ff)})(goodIdx);
            range = [-1 1];
        end
        createFieldMap(vals,polarMap(goodIdx),eccenMap(goodIdx),sigmaMap(goodIdx),range);
        title(saveFieldNames{plotSet(ff)},'Interpreter', 'none');
    end
    subplot(3,3,length(plotSet)+2);
    createFieldMap([],[],[],[],[-1 1]);
    sgtitle([subjectNames{ss} '_' analysisLabels{ss}],'Interpreter', 'none');
    outFigureFile = fullfile(resultsSaveDir, [subjectNames{ss} '_' analysisLabels{ss} '_FieldMap.pdf']);
    print(figHandle,outFigureFile,'-dpdf','-fillpage');
    close(figHandle);
    
end



