% This function performs motion correction based on motion fields derived
% from PANDA (PET navigators using deep learning). The function does all
% the preprocessing necessary for the current study, however can be
% modified to suit for your individual needs.
%
% Author: Lalith Kumar Shiyam Sundar, PhD
% Date  : 27.01.2020
% 
% Inputs: 
%        [1]ppmInputs.pathOfWorkingFolder = Path where the resampled
%        images will be created (inside a folder).
%        [2]ppmInputs.pathToPanda = path to the panda navigators
%        [3]ppmInputs.pathToMRmask = path to the high-resolution MR
%        mask.
%        [4]ppmInputs.pathToTOF = path to the high-resolution
%        3D-TOF MR angiography
%        [5]ppmInputs.initialAlignmentVerified=true or false
%        [6]ppmInputs.manualAlignment=true or false
%
% Usage: 
%        performPandaMoCo(ppmInputs);
%
%-------------------------------------------------------------------------%
%                               PROGRAM START
%-------------------------------------------------------------------------%
function []=performPandaMoco(ppmInputs)

% Hard-coded variables

highResTOFname='TOF_MRA.nii';
highResMask='Native_MR_mask.nii';
referenceImg='PANDA-27.nii';
pandaFolder='PANDA-Analysis';
mrImg='T1_MR.nii';
brain='Brain-mask.nii';
AMIDE='AMIDE-25';

% Load switch variables

initialAlignmentVerified=ppmInputs.initialAlignmentVerified;
manualAlignment=ppmInputs.manualAlignment;

% load the path of the TOF-MRA
pathOfTOF=[ppmInputs.pathToTOF,filesep,highResTOFname];

% load the path of the MR mask

pathOfMask=[ppmInputs.pathToMRmask,filesep,highResMask];

% load the reference image.

pathOfReferenceImg=[ppmInputs.pathOfPandaNavigators,filesep,referenceImg];

% load the brain mask

pathOfBrainMask=[ppmInputs.pathOfMPRage,filesep,brain];
pathOfT1MR=[ppmInputs.pathOfMPRage,filesep,mrImg];

% create a working folder

cd(ppmInputs.pathOfWorkingFolder)
mkdir(pandaFolder)
pathOfPanda=[ppmInputs.pathOfWorkingFolder,filesep,pandaFolder];
cd(pathOfPanda)
mkdir('TOF')
pathOfPandaTOF=[pathOfPanda,filesep,'TOF'];
mkdir('MR-masks')
pathOfPandaMask=[pathOfPanda,filesep,'MR-masks'];
mkdir('Ref-img')
pathOfPandaRefImg=[pathOfPanda,filesep,'Ref-img'];
mkdir('Brain-masks')
pathOfPandaBrain=[pathOfPanda,filesep,'Brain-masks'];
mkdir('T1-MR')
pathOfPandaMR=[pathOfPanda,filesep,'T1-MR'];
copyfile(pathOfMask,pathOfPandaMask);
copyfile(pathOfTOF,pathOfPandaTOF);
copyfile(pathOfReferenceImg,pathOfPandaRefImg);
copyfile(pathOfBrainMask,pathOfPandaBrain)
copyfile(pathOfT1MR,pathOfPandaMR)

% load the coregistration module for the first img (mask).

CoregInputs.RefImgPath=[pathOfPandaRefImg,filesep,referenceImg];
CoregInputs.SourceImgPath=[pathOfPandaTOF,filesep,highResTOFname];
CoregInputs.MaskImgPath={[pathOfPandaMask,filesep,highResMask]};
CoregInputs.Interp=0;
CoregInputs.Prefix='Ref_';
%Coregistration_job(CoregInputs);
cd(pathOfPandaMask)
%rotatedMask=dir('Ref*nii');
%movefile(rotatedMask.name,'MR-mask-25.nii');
oldFileName='MR-mask-27.nii';
for lp=1:26
    newFileName=['MR-mask-',num2str(lp),'.nii'];
    copyfile(oldFileName,newFileName);
    oldFileName=newFileName;
end

% load the coregistration module for registring the brain 

CoregInputs.SourceImgPath=[pathOfPandaMR,filesep,mrImg];
CoregInputs.MaskImgPath={[pathOfPandaBrain,filesep,brain]};
%Coregistration_job(CoregInputs)
cd(pathOfPandaBrain)
%rotatedMask=dir('Ref*nii');
%movefile(rotatedMask.name,'Brain-25.nii');
oldFileName='Brain-27.nii';
for lp=1:26
    newFileName=['Brain-',num2str(lp),'.nii'];
    copyfile(oldFileName,newFileName);
    oldFileName=newFileName;
end


% If the alignment between the TOF-MRA (moving) and the PANDA-25
% (reference) is perfect then proceed with further alignments

pathOfPandaNav=ppmInputs.pathOfPandaNavigators;
cd(pathOfPandaNav)
pandaFiles=dir('P*nii');
for lp=1:length(pandaFiles)
    pandaNav{lp,:}=pandaFiles(lp).name;
end
sortedPanda=natsort(pandaNav);



parfor lp=27:length(sortedPanda)
   CoregInputs = struct();
   CoregInputs.SourceImgPath=[pathOfPandaRefImg,filesep,referenceImg]; % after the first time, the reference img becomes the source image, refer the paper. (panda-25)
   CoregInputs.MaskImgPath{1,:}=[pathOfPandaMask,filesep,'MR-mask-27.nii'];
   CoregInputs.MaskImgPath{2,:}=[pathOfPandaBrain,filesep,'Brain-27.nii'];
   CoregInputs.Interp=0;
   CoregInputs.Prefix=['Moved-',num2str(lp),'-'];
   CoregInputs.RefImgPath=[pathOfPandaNav,filesep,sortedPanda{lp,:}];
   panda_coregistration_job(CoregInputs);
   cd(pathOfPandaMask)
   oldFile=dir(['Moved-',num2str(lp),'-*']);
   movefile(oldFile.name,['MR-mask-',num2str(lp),'.nii']);
   cd(pathOfPandaBrain)
   oldFile=dir(['Moved-',num2str(lp),'-*']);
   movefile(oldFile.name,['Brain-',num2str(lp),'.nii']);
end


end
