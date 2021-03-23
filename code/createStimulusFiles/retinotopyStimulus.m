cd('/Users/aguirre/Dropbox (Aguirre-Brainard Lab)/AGTC_materials/retinotopicMappingStimulus')

stimulus = [];
for ii = 0:174
    filename = sprintf('prf_%d.png',ii);
    A = imread(filename);
    A = squeeze(A(:,:,1));
    A(A<128)=0;
    A(A>=128)=1;
    stimulus(:,:,ii+1)=A;
end
stimTime = 0:1:174;

cd( fileparts(mfilename('fullpath')))
save('retinotopyStimulus.mat','stimulus','stimTime')