subjectID={'HC006 retest','HC007 test','HC007 retest','HC010 test','HC010 retest','HC012 retest','HC013 retest','HC014 test','HC014 retest'};
for lp=1:length(subjectID)
    ppmInputs.pathOfPandaNavigators=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/PANDA-JNM/PET-navigators'];
    ppmInputs.pathToTOF=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/MoCo/Nifti working folder/MR MoCo/MoCo_TOF_MRA'];
    ppmInputs.pathToMRmask=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/MoCo/Nifti working folder/MR MoCo/MoCo_MR_masks'];
    ppmInputs.pathOfWorkingFolder=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data'];
    ppmInputs.pathOfMPRage=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/MoCo/Nifti working folder/T1_MR'];
    performPandaMoco(ppmInputs);
end