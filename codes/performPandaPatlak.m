subjectID={'HC002 test','HC002 retest','HC003 test','HC003 retest','HC004 test','HC004 retest','HC006 test','HC006 retest','HC007 test','HC007 retest','HC009 test','HC009 retest','HC010 test','HC010 retest','HC012 test','HC012 retest','HC013 test','HC013 retest','HC014 test','HC014 retest'}
shortSubjectID={'HC002_m1','HC002_m2','HC003_m1','HC003_m2','HC004_m1','HC004_m2','HC006_m1','HC006_m2','HC007_m1','HC007_m2','HC009_m1','HC009_m2','HC010_m1','HC010_m2','HC012_m1','HC012_m2','HC013_m1','HC013_m2','HC014_m1','HC014_m2'}%
IDIFname='PANDA-IDIF.txt';

for lp=1:length(subjectID)
    pathOfPANDAIdif=['/Volumes/p_Epilepsy/Andy playground/',subjectID{lp}];
    cd(pathOfPANDAIdif);
    pandaIDIF=readtable(