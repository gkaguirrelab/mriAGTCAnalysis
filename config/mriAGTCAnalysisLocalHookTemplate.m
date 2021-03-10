function mrAGTCAnalysisLocalHook
%  mrAGTCAnalysisLocalHook
%
% For use with the ToolboxToolbox.
%
% If you 'git clone' ILFContrastAnalsysis into your ToolboxToolbox "projectRoot"
% folder, then run in MATLAB
%   tbUseProject('mrAGTCAnalysis')
% ToolboxToolbox will set up IBIOColorDetect and its dependencies on
% your machine.
%
% As part of the setup process, ToolboxToolbox will copy this file to your
% ToolboxToolbox localToolboxHooks directory (minus the "Template" suffix).
% The defalt location for this would be
%   ~/localToolboxHooks/LFContrastAnalsysisLocalHook.m
%
% Each time you run tbUseProject('mrAGTCAnalysis'), ToolboxToolbox will
% execute your local copy of this file to do setup for LFContrastAnalsysis.
%
% You should edit your local copy with values that are correct for your
% local machine, for example the output directory location.
%


projectName = 'mriAGTCAnalysis';

%% Delete any old prefs
if (ispref(projectName))
    rmpref(projectName);
end


%% handle hosts with custom dropbox locations

[~,hostname] = system('hostname');
hostname = strtrim(lower(hostname));
switch hostname
    case 'seele.psych.upenn.edu'
        dropboxDir = '/Volumes/seeleExternalDrive/Dropbox (Aguirre-Brainard Lab)';
    case 'magi-1-melchior.psych.upenn.edu'
        dropboxDir = '/Volumes/melchiorBayTwo/Dropbox (Aguirre-Brainard Lab)';
    case 'magi-2-balthasar.psych.upenn.edu'
        dropboxDir = '/Volumes/balthasarExternalDrive/Dropbox (Aguirre-Brainard Lab)';
    otherwise
        [~, userName] = system('whoami');
        userName = strtrim(userName);
        dropboxDir = ...
            fullfile('/Users', userName, ...
            'Dropbox (Aguirre-Brainard Lab)');
end


%% Specify base paths for materials and data
[~, userID] = system('whoami');
userID = strtrim(userID);
switch userID
    case {'harrisonmcadams'}
        AGTC_dataBasePath = ['/Users/' userID '/Dropbox-Aguirre-Brainard-Lab/AGTC_data/'];
        AGTC_analysisBasePath = ['/Users/' userID '/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/'];
        AGTC_processingBasePath = ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/AGTC_processing/'];
        
    otherwise
        AGTC_dataBasePath = fullfile(dropboxDir,'AGTC_data');
        AGTC_analysisBasePath = fullfile(dropboxDir,'AGTC_analysis');
        AGTC_processingBasePath = fullfile(dropboxDir,'AGTC_processing');
        
end

%% Specify where output goes

if ismac
    % Code to run on Mac plaform
    setpref(projectName,'analysisScratchDir','/tmp/flywheel');
    setpref(projectName,'projectRootDir',fullfile('/Users/',userID,'/Documents/flywheel',projectName));
    setpref(projectName,'AGTCDataPath', AGTC_dataBasePath);
    setpref(projectName, 'AGTCAnalysisPath', AGTC_analysisBasePath);
    setpref(projectName, 'AGTCProcessingPath', AGTC_processingBasePath);
    
elseif isunix
    % Code to run on Linux plaform
    setpref(projectName,'analysisScratchDir','/tmp/flywheel');
    setpref(projectName,'projectRootDir',fullfile('/home/',userID,'/Documents/flywheel',projectName));
    setpref(projectName,'AGTCDataPath', AGTC_dataBasePath);
    setpref(projectName, 'AGTCAnalysisPath', AGTC_analysisBasePath);
    setpref(projectName, 'AGTCProcessingPath', AGTC_processingBasePath);
    
elseif ispc
    % Code to run on Windows platform
    warning('No supported for PC')
else
    disp('What are you using?')
end
