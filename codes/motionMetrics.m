subjectID={'HC002 retest','HC003 test','HC006 test','HC006 retest','HC007 test','HC007 retest','HC010 test','HC010 retest','HC012 retest','HC013 retest','HC014 test','HC014 retest'};
for lp=1:length(subjectID)
   PathToMRnavigators=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp},'/Processed data/PANDA-JNM/PET-navigators'];
   cd(PathToMRnavigators)
   refImg=dir('*-25.nii');
   fixedImg=spm_vol(refImg.name);
   disp(['Processing subject: ',subjectID{lp}]);
   %for ilp=26:37
   ilp=32
       srcImg=dir(['*-',num2str(ilp),'.nii']);
       movingImg=spm_vol(srcImg.name);
       motionValues=spm_coreg(fixedImg,movingImg)
       motionProfile{lp}(ilp,:)=motionValues;
       disp(['Coregistering frame number: ',num2str(ilp),'...']); 
  % end
end