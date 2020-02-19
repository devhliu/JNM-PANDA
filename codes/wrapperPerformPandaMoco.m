subjectID={'HC006 retest'};
for lp=1:length(subjectID)
    ppmInputs.pathOfPandaNavigators=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/PANDA-JNM/PET-navigators'];
    ppmInputs.pathToTOF=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/MoCo/Nifti working folder/MR MoCo/MoCo_TOF_MRA'];
    ppmInputs.pathToMRmask=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/MoCo/Nifti working folder/MR MoCo/MoCo_MR_masks'];
    ppmInputs.pathOfWorkingFolder=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data'];
    ppmInputs.pathOfMPRage=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/MoCo/Nifti working folder/T1_MR'];
    ppmInputs.manualAlignment=true;
    ppmInputs.initialAlignmentVerified=true;
    performPandaMoco(ppmInputs);
end