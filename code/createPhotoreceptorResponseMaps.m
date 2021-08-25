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
    'MELA_5001',...
    'MELA_5002',...
    'MELA_5004',...
    'MELA_5005',...
    'MELA_5006',...
    'MELA_5007',...
    'MELA_5008',...
    'MELA_5009',...
    'MELA_5010'};
analysisIDs = {...
    '6122d039f52d4265b309baa4',...
    '6122d03e191bd692cfc9e6fb',...
    '6122d045369c87580c38cf99',...
    '6122d04fada5a85d7af68a5e',...
    '6122d0548fb7cc95c6c70911',...
    '6122d05bd7113cbf3a09baaf',...
    '6122d061f78eca5102c9e70a',...
    '6122d067369c87580c38cf9f',...
    '6122d06cada5a85d7af68a64',...
     };

retinoMapID = '5dc88aaee74aa3005e169380';
retinoFileName = 'TOME_3021_cifti_maps.zip';

fieldNameBaseline = 'baseline';
fieldNames = {'LminusM','LMS','S','omni','baseline','attention'};
baselineIdx = find(strcmp(fieldNames,fieldNameBaseline));
notBaselineIdx = find(~strcmp(fieldNames,fieldNameBaseline));

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
    
    % Flip the polar map sign to create a Left and right hemifield
    polarMap(32492:end)=-polarMap(32492:end);

    % Download the results file
    fileName = [fileStem 'results.mat'];
    tmpPath = fullfile(saveDir,[analysisLabels{ss} '_' fileName]);
    fw.downloadOutputFromAnalysis(analysisIDs{ss},fileName,tmpPath);
    
    % Load the result file into memory and delete the downloaded file
    clear results
    load(tmpPath,'results')

    % Grab the stimLabels
    stimLabels = results.model.opts{find(strcmp(results.model.opts,'stimLabels'))+1};

%     % Download the templateImage file
%     fileName = [fileStem 'templateImage.mat'];
%     tmpPath = fullfile(saveDir,[analysisLabels{ss} '_' fileName]);
%     fw.downloadOutputFromAnalysis(analysisIDs{ss},fileName,tmpPath);
%     
%     % Load the result file into memory and delete the downloaded file
%     clear templateImage
%     load(tmpPath,'templateImage')
    %        delete(tmpPath)
    
    % Obtain the results vs. the baseline condition
    
    for ff = 1:length(notBaselineIdx)
            subString = sprintf(['f%dHz_' directions{dd}],freqs(ff));
            idx = find(contains(stimLabels,subString));
            vals{ff} = mean(results.params(goodIdx,idx),'omitnan');

            
        if strcmp(fieldNames{ff},fieldNameBaseline)
            continue
        end
        saveFieldNames{ff} = [fieldNames{ff} '_zVal'];
        results.(saveFieldNames{ff}) = results.(fieldNames{ff})-results.(fieldNameBaseline);
    end
%     
%     saveFieldNames = [saveFieldNames 'R2'];
%     
%     % Save the map results into images
%     for ff = 1:length(saveFieldNames)
%         if isempty(saveFieldNames{ff})
%             continue
%         end
%         % The initial, CIFTI space image
%         outCIFTIFile = fullfile(resultsSaveDir, [subjectNames{ss} '_' analysisLabels{ss} '_' saveFieldNames{ff} '.dtseries.nii']);
%         outData = templateImage;
%         outData.cdata = single(results.(saveFieldNames{ff}));
%         outData.diminfo{1,2}.length = 1;
%         cifti_write(outData, outCIFTIFile)
%     end
%     
    
    % Find the vertices for this wedge of the visual field
    eccenRange = [0 90];
    r2Thresh = 0.2;
    areaIdx = (vArea==1) .* (eccenMap > eccenRange(1)) .* (eccenMap < eccenRange(2));
    goodIdx = logical( (results.R2 > r2Thresh) .* areaIdx );
        
   % Loop through the stimuli and obtain the set of values
        vals = cell(1,nFreqs);
        for ff = 1:nFreqs
        end

                % Adjust the values for the zero frequency and plot
        for ff = 2:nFreqs
            data{ss,dd,ff-1} = vals{ff}-vals{1};
            semilogx(zeros(1,length(data{ss,dd,ff-1}))+freqs(ff),data{ss,dd,ff-1},'.','Color',[0.5 0.5 0.5]);
            hold on
        end

        
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



