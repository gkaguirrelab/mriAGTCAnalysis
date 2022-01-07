% Script that downloads the forwardModel results from AGTC OneLight
% experiments.
%
% The basic design of the experiment presents a set of modulations that
% target different post-receptoral directions repeatedly. There 5 stimulus
% conditions, each a 12 second flicker modulation (baseline, LMS, L-M, S,
% and "omni"). These are presented in a counter-balanced order during scan
% "A", and then in the reverse order in scan "B". There is also a randomly
% occuring attention task. The forwardModel analysis of these data
% concatenates all runs (left and right eye), and identifies the HRF shape
% that best accounts for the data. The amplitude of response to each
% stimulus type in each acquisition is retained.
%
% The analysis IDs are stored in the first entry in the "notes" tab for
% each forward model.
%


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
sessionTypes = {...
    'post',...
    'post',...
    'control',...
    'control',...
    'pre',...
    'control',...
    'post',...
    'control',...
    'pre'};
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
directionNames = {'LminusM','LMS','S','omni','baseline','attention'};
baselineIdx = find(strcmp(directionNames,fieldNameBaseline));
notBaselineIdx = find(~strcmp(directionNames,fieldNameBaseline));

% File save locations
scratchSaveDir = '/Users/aguirre/Desktop/tempFiles';
resultsSaveDir = '/Users/aguirre/Desktop/AGTC_OL/';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','output');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Create a flywheel object
fw = flywheel.Flywheel(getpref('forwardModelWrapper','flywheelAPIKey'));

% Download the standard retino data
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


% Loop over subjects
for ss = 1:length(subjectNames)

    % Set up the paths for this subject
    newDir = fullfile(resultsSaveDir,subjectNames{ss});
    mkdir(newDir);

    % Download the results file
    fileName = [subjectNames{ss} '_mtSinai_results.mat'];
    tmpPath = fullfile(saveDir,fileName);
    fw.downloadOutputFromAnalysis(analysisIDs{ss},fileName,tmpPath);

    % Load the result file into memory and delete the downloaded file
    clear results
    load(tmpPath,'results')

    % Grab the stimLabels
    stimLabels = results.model.opts{find(strcmp(results.model.opts,'stimLabels'))+1};

    % Identify the baseline indices
    baseIdx = find(contains(stimLabels,directionNames(baselineIdx)));

    % Obtain the results vs. the baseline condition
    nAcqs = length(stimLabels)/length(directionNames);
    for dd = 1:length(notBaselineIdx)
        stimIdx = find(contains(stimLabels,directionNames(notBaselineIdx(dd))));
        vals = mean(results.params(:,stimIdx),2,'omitnan') - mean(results.params(:,baseIdx),2,'omitnan');
        saveFieldName = [directionNames{ff} '_vBase'];
        results.(saveFieldName) = vals;
    end

    % Find the vertices for this wedge of the visual field
    eccenRange = [0 90];
    r2Thresh = 0.2;
    areaIdx = (vArea==1) .* (eccenMap > eccenRange(1)) .* (eccenMap < eccenRange(2));
    goodIdx = logical( (results.R2 > r2Thresh) .* areaIdx );

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
        createFieldMap(vals(goodIdx),polarMap(goodIdx),eccenMap(goodIdx),sigmaMap(goodIdx),[-3 3]);
        title(saveFieldNames{plotSet(ff)},'Interpreter', 'none');
    end
    subplot(3,3,length(plotSet)+2);
    createFieldMap([],[],[],[],[-1 1]);
    sgtitle([subjectNames{ss} '_' analysisLabels{ss}],'Interpreter', 'none');
    outFigureFile = fullfile(newDir, [subjectNames{ss} '_' analysisLabels{ss} '_FieldMap.pdf']);
    print(figHandle,outFigureFile,'-dpdf','-fillpage');
    close(figHandle);

end



