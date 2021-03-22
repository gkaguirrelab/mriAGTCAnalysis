
labelsA = {'face','blank','face','face','face','red','red','color','color','face','house','color','blank','house','face','color','gray','house','gray','face','house','gray','red','gray','gray','color','blank','blank','house','house','color','color','gray','red','color','red','house','blank','blank','gray','gray','house','face','color','red','face','blank','color','house','blank','face','red','blank','red','house','house','red','gray','face','gray','blank','red','blank','gray','color','face','blank','color','house','red','red','face','gray','blank','blank'};
labelsB = {'house','blank','red','gray','color','face','face','color','blank','blank','face','color','red','face','house','gray','red','blank','blank','house','face','blank','color','house','color','face','gray','red','red','house','blank','color','house','color','red','color','blank','gray','house','face','red','blank','house','house','blank','red','gray','face','house','red','red','face','red','house','house','gray','blank','red','color','color','color','gray','blank','gray','color','gray','gray','face','face','blank','face','gray','gray','house','blank'};

stimLabels = unique(labelsA);
stimulusA = zeros(length(stimLabels)-1,length(labelsA));
stimulusB = zeros(length(stimLabels)-1,length(labelsB));
for ii = 2:length(stimLabels)
    stimulusA(ii-1,strcmp(labelsA,stimLabels{ii}))=1;
    stimulusB(ii-1,strcmp(labelsB,stimLabels{ii}))=1;
end
stimTimeA = (0:length(stimulusA)-1)*4;
stimTimeB = (0:length(stimulusB)-1)*4;

stimulus = {stimulusA,stimulusB};
stimTime = {stimTimeA,stimTimeB};
save('ventraLocalizerStimulusAB.mat','stimulus','stimTime')