subjectID={'HC002 retest','HC003 test','HC003 retest','HC004 test','HC004 retest','HC006 test','HC006 retest','HC007 test','HC007 retest','HC009 test','HC009 retest','HC010 test','HC010 retest','HC012 test','HC012 retest','HC013 test','HC013 retest','HC014 test','HC014 retest'}
for lp=1:length(subjectID)
    pathOfPanda=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/PANDA-JNM'];
    cd(pathOfPanda)
    rmdir('PET-navigators','s');
    mkdir('PET-navigators')
    pathOfPETnav=[pathOfPanda,filesep,'PET-navigators'];
    pathOfPET=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/Reconstructed PET/Nifti_MoCo_Recons_PET_CT'];
    cd(pathOfPET)
    copyfile('PET*',pathOfPETnav)
    cd(pathOfPETnav)
    PETfiles=dir('PET*')
    for ilp=1:length(PETfiles)
        sortedPET{ilp,:}=PETfiles(ilp).name;
    end
    sortedPETfiles=natsort(sortedPET);
    for ilp=1:length(sortedPETfiles)
        movefile(sortedPETfiles{ilp,:},['PANDA-',num2str(ilp),'.nii']);
    end
end