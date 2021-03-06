frameNum='25';
subjectID={'HC002 test','HC002 retest','HC003 test','HC003 retest','HC004 test','HC004 retest','HC006 test','HC006 retest','HC007 test','HC007 retest','HC009 retest','HC010 test','HC010 retest','HC012 test','HC012 retest','HC013 test','HC013 retest','HC014 test','HC014 retest'};
motherFolder=cd;
h = cProgress ( 0, 'Reading images');
for lp=1:length(subjectID)
    cProgress(100.*(lp/length(subjectID)),h)
    cd(motherFolder)
    folderOfInt=[subjectID{lp},'*'];
    navFolder=dir(folderOfInt);
    intFolder=[motherFolder,filesep,navFolder.name];
    cd(intFolder)
    gzFile=dir('*.gz');
    gunzip(gzFile.name)
    niftyFile=dir('*.nii');
    movefile(niftyFile.name,['PANDA-',frameNum,'.nii']);
    pathOfPanda=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/PANDA-JNM/PET-navigators'];
    %copyfile(niftyFile.name,pathOfPanda)
    copyfile(['PANDA-',frameNum,'.nii'],pathOfPanda)
end
close(h)


