subjectID={'HC002 retest','HC003 test','HC003 retest','HC004 test','HC004 retest','HC006 test','HC006 retest','HC007 test','HC007 retest','HC009 test','HC009 retest','HC010 test','HC010 retest','HC012 test','HC012 retest','HC013 test','HC013 retest','HC014 test','HC014 retest'}

for lp=1:length(subjectID)
    motherFolder=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data'];
    cd(motherFolder)
    mkdir('PANDA-JNM')
    pathOfPanda=[motherFolder,filesep,'PANDA-JNM'];
    pathOfTransformedMRNavigators=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/MoCo/Nifti working folder'];
    pathOfMRcorrespondence=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/Reconstruction parameters'];
    cd(pathOfMRcorrespondence)
    mrCorrespondence=readtable('MR_correspondence.txt');
    mrCorrespondence=mrCorrespondence.Var1;
    cd(pathOfPanda)
    for ilp=1:length(mrCorrespondence)
        string2Search=['Transform_MRnav_',num2str(mrCorrespondence(ilp)),'_*'];
        cd(pathOfTransformedMRNavigators)
        fileOfInterest=dir(string2Search)
        copyfile(fileOfInterest.name,pathOfPanda)
        cd(pathOfPanda)
        movefile(fileOfInterest.name,['MR-navigator-',num2str(ilp),'.nii']);
    end
            
end