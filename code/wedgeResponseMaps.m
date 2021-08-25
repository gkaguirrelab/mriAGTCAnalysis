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


eccenRangeSet = [0, 1.25, 2.5, 5, 10, 20];
polarRangeSet = [{[-180 180]},repmat({-180:60:180},1,length(eccenRangeSet)-1)];
responseMax = 2.0;


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
    fileStem = [subjectNames{ss} '_mtSinai_'];
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
    
    % Flip the polar map sign to create a left and right hemifield
    polarMap(32492:end)=-polarMap(32492:end);
    
    % Download the results file
    fileName = [fileStem 'results.mat'];
    tmpPath = fullfile(saveDir,fileName);
    fw.downloadOutputFromAnalysis(analysisIDs{ss},fileName,tmpPath);
    
    % Load the result file into memory and delete the downloaded file
    clear results
    load(tmpPath,'results')
    
    % Grab the stimLabels
    stimLabels = results.model.opts{find(strcmp(results.model.opts,'stimLabels'))+1};
    
    % Get the goodIdx
    eccenRange = [0 10];
    r2Thresh = 0.1;
    
    %     % Download the templateImage file
    %     fileName = [fileStem 'templateImage.mat'];
    %     tmpPath = fullfile(saveDir,[analysisLabels{ss} '_' fileName]);
    %     fw.downloadOutputFromAnalysis(analysisIDs{ss},fileName,tmpPath);
    %
    %     % Load the result file into memory and delete the downloaded file
    %     clear templateImage
    %     load(tmpPath,'templateImage')
    %        delete(tmpPath)
    
    % Obtain the results vs. the baseline condition for each condition in
    % each wedge
    
    figure('Name',subjectNames{ss});
    cmap = myColorMap();
    for ee = 1:length(eccenRangeSet)-1
        eccenRange = [eccenRangeSet(ee) eccenRangeSet(ee+1)];
        thisPolarRangeSet = polarRangeSet{ee};
        for pp = 1:length(thisPolarRangeSet)-1
            polarRange = [thisPolarRangeSet(pp) thisPolarRangeSet(pp+1)];
            valsR = {};
            valsL = {};
            areaIdx = (vArea==1) .* (eccenMap > eccenRange(1)) .* (eccenMap < eccenRange(2)) .* (polarMap > polarRange(1)) .* (polarMap < polarRange(2)) ;
            goodIdx = logical( (results.R2 > r2Thresh) .* areaIdx );
            for ff = 1:length(notBaselineIdx)
                subString = [fieldNames{notBaselineIdx(ff)},'_R']; % 
                idxVals = find(startsWith(stimLabels,subString));
                idxBase = find(startsWith(stimLabels,[fieldNameBaseline,'_R'])); % 
                valsR{ff} = mean(results.params(goodIdx,idxVals)-results.params(goodIdx,idxBase),'omitnan');

                subString = [fieldNames{notBaselineIdx(ff)},'_L']; % 
                idxVals = find(startsWith(stimLabels,subString));
                idxBase = find(startsWith(stimLabels,[fieldNameBaseline,'_L'])); % 
                valsL{ff} = mean(results.params(goodIdx,idxVals)-results.params(goodIdx,idxBase),'omitnan');

                % Add this plot wedge
                subplot(2,3,ff);
                [~,~,~,thisVal] = ttest2(valsR{ff},valsL{ff});
                thisVal = thisVal.tstat;
                if isnan(thisVal)
                    cIdx = 1;
                else
                cIdx = round(128 + 128*thisVal/responseMax);
                cIdx = max([2 cIdx]);
                cIdx = min([256 cIdx]);
                end
                addRadialPatch(polarRange,eccenRange,cmap(cIdx,:));
                if ee==1
                    hold on
                    axis off
                    title(fieldNames{notBaselineIdx(ff)});
                    axis square
                end
            end
        end
    end
    subplot(2,3,6)
    axis square
    axis off
    colormap(cmap)
    colorbar('Ticks',0:0.25:1,...
        'TickLabels',{'-1','-0.5','0','+0.5','+1'})
    
    foo=1;
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
    
end



function p = addRadialPatch(polarRange,eccenRange,color)

nDivs = 100;

theta = pi/2 + deg2rad(linspace(polarRange(1),polarRange(2),nDivs));
theta = [theta fliplr(theta)];
rho = [eccenRange(1)*ones(nDivs,1)' eccenRange(2)*ones(nDivs,1)'];
[x,y] = pol2cart(theta,rho);

%a = polar(theta,rho);
%rlim([0 45])
%patch( get(a,'XData'), get(a,'YData'),color,'FaceAlpha',0.9)
patch( x,y,color,'FaceAlpha',0.9)
end


function cmap = myColorMap()

cmap = [...
    0         0    0
    0.0071    0.0071    0.9992
    0.0142    0.0142    0.9985
    0.0213    0.0213    0.9977
    0.0284    0.0284    0.9969
    0.0355    0.0355    0.9961
    0.0426    0.0426    0.9954
    0.0497    0.0497    0.9946
    0.0568    0.0568    0.9938
    0.0639    0.0639    0.9931
    0.0710    0.0710    0.9923
    0.0781    0.0781    0.9915
    0.0852    0.0852    0.9907
    0.0923    0.0923    0.9900
    0.0994    0.0994    0.9892
    0.1065    0.1065    0.9884
    0.1136    0.1136    0.9876
    0.1207    0.1207    0.9869
    0.1278    0.1278    0.9861
    0.1349    0.1349    0.9853
    0.1420    0.1420    0.9846
    0.1491    0.1491    0.9838
    0.1562    0.1562    0.9830
    0.1633    0.1633    0.9822
    0.1704    0.1704    0.9815
    0.1776    0.1776    0.9807
    0.1847    0.1847    0.9799
    0.1918    0.1918    0.9792
    0.1989    0.1989    0.9784
    0.2060    0.2060    0.9776
    0.2131    0.2131    0.9768
    0.2202    0.2202    0.9761
    0.2273    0.2273    0.9753
    0.2344    0.2344    0.9745
    0.2415    0.2415    0.9738
    0.2486    0.2486    0.9730
    0.2557    0.2557    0.9722
    0.2628    0.2628    0.9714
    0.2699    0.2699    0.9707
    0.2770    0.2770    0.9699
    0.2841    0.2841    0.9691
    0.2912    0.2912    0.9683
    0.2983    0.2983    0.9676
    0.3054    0.3054    0.9668
    0.3125    0.3125    0.9660
    0.3196    0.3196    0.9653
    0.3267    0.3267    0.9645
    0.3338    0.3338    0.9637
    0.3409    0.3409    0.9629
    0.3480    0.3480    0.9622
    0.3551    0.3551    0.9614
    0.3622    0.3622    0.9606
    0.3693    0.3693    0.9599
    0.3764    0.3764    0.9591
    0.3835    0.3835    0.9583
    0.3906    0.3906    0.9575
    0.3977    0.3977    0.9568
    0.4048    0.4048    0.9560
    0.4119    0.4119    0.9552
    0.4190    0.4190    0.9545
    0.4261    0.4261    0.9537
    0.4332    0.4332    0.9529
    0.4403    0.4403    0.9521
    0.4474    0.4474    0.9514
    0.4545    0.4545    0.9506
    0.4616    0.4616    0.9498
    0.4687    0.4687    0.9491
    0.4758    0.4758    0.9483
    0.4829    0.4829    0.9475
    0.4900    0.4900    0.9467
    0.4971    0.4971    0.9460
    0.5042    0.5042    0.9452
    0.5113    0.5113    0.9444
    0.5184    0.5184    0.9436
    0.5256    0.5256    0.9429
    0.5327    0.5327    0.9421
    0.5398    0.5398    0.9413
    0.5469    0.5469    0.9406
    0.5540    0.5540    0.9398
    0.5611    0.5611    0.9390
    0.5682    0.5682    0.9382
    0.5753    0.5753    0.9375
    0.5824    0.5824    0.9367
    0.5895    0.5895    0.9359
    0.5966    0.5966    0.9352
    0.6037    0.6037    0.9344
    0.6108    0.6108    0.9336
    0.6179    0.6179    0.9328
    0.6250    0.6250    0.9321
    0.6321    0.6321    0.9313
    0.6392    0.6392    0.9305
    0.6463    0.6463    0.9298
    0.6534    0.6534    0.9290
    0.6605    0.6605    0.9282
    0.6676    0.6676    0.9274
    0.6747    0.6747    0.9267
    0.6818    0.6818    0.9259
    0.6889    0.6889    0.9251
    0.6960    0.6960    0.9243
    0.7031    0.7031    0.9236
    0.7102    0.7102    0.9228
    0.7173    0.7173    0.9220
    0.7244    0.7244    0.9213
    0.7315    0.7315    0.9205
    0.7386    0.7386    0.9197
    0.7457    0.7457    0.9189
    0.7528    0.7528    0.9182
    0.7599    0.7599    0.9174
    0.7670    0.7670    0.9166
    0.7741    0.7741    0.9159
    0.7812    0.7812    0.9151
    0.7883    0.7883    0.9143
    0.7954    0.7954    0.9135
    0.8025    0.8025    0.9128
    0.8096    0.8096    0.9120
    0.8167    0.8167    0.9112
    0.8238    0.8238    0.9105
    0.8309    0.8309    0.9097
    0.8380    0.8380    0.9089
    0.8451    0.8451    0.9081
    0.8522    0.8522    0.9074
    0.8593    0.8593    0.9066
    0.8665    0.8665    0.9058
    0.8736    0.8736    0.9050
    0.8807    0.8807    0.9043
    0.8878    0.8878    0.9035
    0.8949    0.8949    0.9027
    0.9020    0.9020    0.9020
    0.9035    0.8879    0.8879
    0.9050    0.8738    0.8738
    0.9066    0.8597    0.8597
    0.9081    0.8456    0.8456
    0.9096    0.8315    0.8315
    0.9112    0.8174    0.8174
    0.9127    0.8033    0.8033
    0.9142    0.7892    0.7892
    0.9157    0.7751    0.7751
    0.9173    0.7610    0.7610
    0.9188    0.7469    0.7469
    0.9203    0.7328    0.7328
    0.9219    0.7188    0.7188
    0.9234    0.7047    0.7047
    0.9249    0.6906    0.6906
    0.9265    0.6765    0.6765
    0.9280    0.6624    0.6624
    0.9295    0.6483    0.6483
    0.9311    0.6342    0.6342
    0.9326    0.6201    0.6201
    0.9341    0.6060    0.6060
    0.9357    0.5919    0.5919
    0.9372    0.5778    0.5778
    0.9387    0.5637    0.5637
    0.9403    0.5496    0.5496
    0.9418    0.5355    0.5355
    0.9433    0.5214    0.5214
    0.9449    0.5074    0.5074
    0.9464    0.4933    0.4933
    0.9479    0.4792    0.4792
    0.9494    0.4651    0.4651
    0.9510    0.4510    0.4510
    0.9525    0.4369    0.4369
    0.9540    0.4228    0.4228
    0.9556    0.4087    0.4087
    0.9571    0.3946    0.3946
    0.9586    0.3805    0.3805
    0.9602    0.3664    0.3664
    0.9617    0.3523    0.3523
    0.9632    0.3382    0.3382
    0.9648    0.3241    0.3241
    0.9663    0.3100    0.3100
    0.9678    0.2960    0.2960
    0.9694    0.2819    0.2819
    0.9709    0.2678    0.2678
    0.9724    0.2537    0.2537
    0.9740    0.2396    0.2396
    0.9755    0.2255    0.2255
    0.9770    0.2114    0.2114
    0.9786    0.1973    0.1973
    0.9801    0.1832    0.1832
    0.9816    0.1691    0.1691
    0.9831    0.1550    0.1550
    0.9847    0.1409    0.1409
    0.9862    0.1268    0.1268
    0.9877    0.1127    0.1127
    0.9893    0.0987    0.0987
    0.9908    0.0846    0.0846
    0.9923    0.0705    0.0705
    0.9939    0.0564    0.0564
    0.9954    0.0423    0.0423
    0.9969    0.0282    0.0282
    0.9985    0.0141    0.0141
    1.0000         0         0
    1.0000    0.0156    0.0010
    1.0000    0.0312    0.0021
    1.0000    0.0469    0.0031
    1.0000    0.0625    0.0042
    1.0000    0.0781    0.0052
    1.0000    0.0938    0.0063
    1.0000    0.1094    0.0073
    1.0000    0.1250    0.0083
    1.0000    0.1406    0.0094
    1.0000    0.1562    0.0104
    1.0000    0.1719    0.0115
    1.0000    0.1875    0.0125
    1.0000    0.2031    0.0135
    1.0000    0.2188    0.0146
    1.0000    0.2344    0.0156
    1.0000    0.2500    0.0167
    1.0000    0.2656    0.0177
    1.0000    0.2812    0.0188
    1.0000    0.2969    0.0198
    1.0000    0.3125    0.0208
    1.0000    0.3281    0.0219
    1.0000    0.3438    0.0229
    1.0000    0.3594    0.0240
    1.0000    0.3750    0.0250
    1.0000    0.3906    0.0260
    1.0000    0.4062    0.0271
    1.0000    0.4219    0.0281
    1.0000    0.4375    0.0292
    1.0000    0.4531    0.0302
    1.0000    0.4688    0.0312
    1.0000    0.4844    0.0323
    1.0000    0.5000    0.0333
    1.0000    0.5156    0.0344
    1.0000    0.5312    0.0354
    1.0000    0.5469    0.0365
    1.0000    0.5625    0.0375
    1.0000    0.5781    0.0385
    1.0000    0.5938    0.0396
    1.0000    0.6094    0.0406
    1.0000    0.6250    0.0417
    1.0000    0.6406    0.0427
    1.0000    0.6562    0.0438
    1.0000    0.6719    0.0448
    1.0000    0.6875    0.0458
    1.0000    0.7031    0.0469
    1.0000    0.7188    0.0479
    1.0000    0.7344    0.0490
    1.0000    0.7500    0.0500
    1.0000    0.7656    0.0510
    1.0000    0.7812    0.0521
    1.0000    0.7969    0.0531
    1.0000    0.8125    0.0542
    1.0000    0.8281    0.0552
    1.0000    0.8438    0.0563
    1.0000    0.8594    0.0573
    1.0000    0.8750    0.0583
    1.0000    0.8906    0.0594
    1.0000    0.9062    0.0604
    1.0000    0.9219    0.0615
    1.0000    0.9375    0.0625
    1.0000    0.9531    0.0635
    1.0000    0.9688    0.0646
    1.0000    0.9844    0.0656
    1.0000    1.0000    0.0667];

%    colormap(map);

end
