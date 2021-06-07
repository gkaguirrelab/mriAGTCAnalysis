To submit these jobs to Flywheel, use the function submitGears that is included in the flywheelMRSupport toolbox. The syntax is:

	submitGears('tomeHCPStructParams.csv')

NOTE: The ICAFix analyses must be submitted using the high memory virtual machine:

	submitGears('agtcOLHCPFuncICAFIX.csv','tags',{'vm-n1-highmem-8_disk-1500G_swap-60G'})

The order of execution for these should be:

tomeHCPStructParams.csvtomeHCPFuncParams_Session1.csvtomeHCPFuncParams_Session2.csvtomeHCPFuncICAFIX_Session1.csvtomeHCPFuncICAFIX_Session2.csv
tomeHCPforwardModel_flobsHRF -- Calculates the HRF parameters from the FLASH data

Use the function extractHRFParams.m to extract the HRF parameters, and the function SCRIPT_calcMagnification. (in eyeTrackTOMEAnalysis) to get the screen magnification. Use the spreadsheet AssemblePRFModelOpts.xlsx to assemble this info.

tomeHCPforwardModel_prfTimeShift.csv -- Runs the pRF model
tomeHCPbayesPRF.csv -- Fits the bayes V1-V3 template to the pRF data
tomeHCPDiffParams.csv -- Pre-processing for the DTI data
