subjectID={'HC006 test'};
shortID={'HC006_m1'};
pathOfAIF='/Users/lalithsimac/Documents/Input functions/Arterial input functions';% arterial input function

for lp=1:length(subjectID)
    iPVCinputs.AC='CT_'
    iPVCinputs.pathOfPET=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/Reconstructed PET/Nifti_MoCo_Recons_PET_CT'];
    iPVCinputs.pathOfAlignedMRmasks=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/PANDA-Analysis/MR-masks'];
    iPVCinputs.pathOfAlignedBrainMasks=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/PANDA-Analysis/Brain-masks'];
    iPVCinputs.psfFWHM=5;
    iPVCinputs.whereToProcess=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp}];
    iPVCinputs.p2bRatio = getP2Bratio(shortID{lp});
    cd(pathOfAIF)
    aifFile=dir([shortID{lp},'*']);
    iPVCinputs.plasmaInputFunction=readtable(aifFile.name);
    iPVCinputs.subjectID=subjectID{lp};

    % automatic calculation of cross-calibration factor
    
    [dateVector]=DCMinfoExtractor(subjectID{lp});

    tLower1=datetime(2016,04,11); tUpper1=datetime(2016,06,17)
    tLower2=datetime(2016,06,25); tUpper2=datetime(2016,10,13)
    tLower3=datetime(2016,10,24); tUpper3=datetime(2017,1,12)
    tLower4=datetime(2017,01,23); tUpper4=datetime(2017,04,25)

    if isbetween(dateVector(lp,:),tLower1,tUpper1)
       iPVCinputs.crossCalibrationFactor=1.141;
    end
    if isbetween(dateVector(lp,:),tLower2,tUpper2)
       iPVCinputs.crossCalibrationFactor=1.126;
    end
    if isbetween(dateVector(lp,:),tLower3,tUpper3)
       iPVCinputs.crossCalibrationFactor=1.111;
    end
    if isbetween(dateVector(lp,:),tLower4,tUpper4)
       iPVCinputs.crossCalibrationFactor= 1.0880;
    end
    
   [ipvcOutputs] = iterativePartialVolumeCorrection(iPVCinputs);
    
end