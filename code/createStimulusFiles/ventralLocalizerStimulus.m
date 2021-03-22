
labelsA = {'face','blank','face','face','face','red','red','color','color','face','house','color','blank','house','face','color','gray','house','gray','face','house','gray','red','gray','gray','color','blank','blank','house','house','color','color','gray','red','color','red','house','blank','blank','gray','gray','house','face','color','red','face','blank','color','house','blank','face','red','blank','red','house','house','red','gray','face','gray','blank','red','blank','gray','color','face','blank','color','house','red','red','face','gray','blank','blank'};
labelsB = {'house','blank','red','gray','color','face','face','color','blank','blank','face','color','red','face','house','gray','red','blank','blank','house','face','blank','color','house','color','face','gray','red','red','house','blank','color','house','color','red','color','blank','gray','house','face','red','blank','house','house','blank','red','gray','face','house','red','red','face','red','house','house','gray','blank','red','color','color','color','gray','blank','gray','color','gray','gray','face','face','blank','face','gray','gray','house','blank'};

eventDur = 4;
stimDeltaT = 0.5;
nTimeSamples = length(labelsA)*eventDur/stimDeltaT;

stimLabels = unique(labelsA);
labelMatrixA = zeros(length(stimLabels)-1,length(labelsA));
labelMatrixB = zeros(length(stimLabels)-1,length(labelsA));
for ii = 2:length(stimLabels)
    labelMatrixA(ii-1,strcmp(labelsA,stimLabels{ii}))=1;
    labelMatrixB(ii-1,strcmp(labelsB,stimLabels{ii}))=1;
end

% Resample to nTimeSamples
labelTimeA = linspace(0,(length(labelsA)-1)*eventDur,length(labelsA));
labelTimeB = linspace(0,(length(labelsB)-1)*eventDur,length(labelsB));

stimTimeA = linspace(0,(nTimeSamples-1)*stimDeltaT,nTimeSamples);
stimTimeB = linspace(0,(nTimeSamples-1)*stimDeltaT,nTimeSamples);

stimulusA = [];
stimulusB = [];
for ii = 2:length(stimLabels)    
    stimulusA(ii-1,:) = interp1(labelTimeA,labelMatrixA(ii-1,:),stimTimeA,'nearest','extrap');
    stimulusB(ii-1,:) = interp1(labelTimeB,labelMatrixB(ii-1,:),stimTimeB,'nearest','extrap');
end

stimulus = {stimulusA,stimulusB};
stimTime = {stimTimeA,stimTimeB};
save('ventraLocalizerStimulusAB.mat','stimulus','stimTime')
