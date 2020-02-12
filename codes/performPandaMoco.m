% This function performs motion correction based on motion fields derived
% from PANDA (PET navigators using deep learning). The function does all
% the preprocessing necessary for the current study, however can be
% modified to suit for your individual needs.
%
% Author: Lalith Kumar Shiyam Sundar, PhD
% Date  : 27.01.2020
% 
% Inputs: 
%        [1]pandaMocoInputs.pathOfWorkingFolder = Path where the resampled
%        images will be created (inside a folder).
%        [2]pandaMocoInputs.pathToPanda = path to the panda navigators
%        [3]pandaMocoInputs.pathToMRmask = path to the high-resolution MR
%        mask.
%        [4]pandaMoCoInputs.pathToTOF = path to the high-resolution
%        3D-TOF MR angiography
%
% Usage: 
%        performPandaMoCo(pandaMocoInputs);
%
%-------------------------------------------------------------------------%
%                               PROGRAM START
%-------------------------------------------------------------------------%
function []=performPandaMoco(ppmInputs)

% Hard-coded variables

highResTOFname='TOF_MRA.nii';
highResMask='Native_MR_mask.nii';
referenceImg='PANDA-25.nii';
pandaFolder='PANDA-Analysis';
mrImg='T1_MR.nii';
brain='Brain-mask.nii';

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
Coregistration_job(CoregInputs);
cd(pathOfPandaMask)
rotatedMask=dir('Ref*nii');
movefile(rotatedMask.name,'MR-mask-25.nii');
oldFileName='MR-mask-25.nii';
for lp=1:25
    newFileName=['MR-mask-',num2str(lp),'.nii'];
    copyfile(oldFileName,newFileName);
    oldFileName=newFileName;
end

% load the coregistration module for registring the brain 

CoregInputs.SourceImgPath=[pathOfPandaMR,filesep,mrImg];
CoregInputs.MaskImgPath={[pathOfPandaBrain,filesep,brain]};
Coregistration_job(CoregInputs)
cd(pathOfPandaBrain)
rotatedMask=dir('Ref*nii');
movefile(rotatedMask.name,'Brain-25.nii');
oldFileName='Brain-25.nii';
for lp=1:25
    newFileName=['Brain-',num2str(lp),'.nii'];
    copyfile(oldFileName,newFileName);
    oldFileName=newFileName;
end


% load the coregistration for continous motion correction from frame-25
% here Panda-25 becomes the source image and all the others become the
% reference Images.

pathOfPandaNav=ppmInputs.pathOfPandaNavigators
cd(pathOfPandaNav)
pandaFiles=dir('*nii');
for lp=1:length(pandaFiles)
    pandaNav{lp,:}=pandaFiles(lp).name;
end
sortedPanda=natsort(pandaNav);
CoregInputs.SourceImgPath=[pathOfPandaRefImg,filesep,referenceImg]; % after the first time, the reference img becomes the source image, refer the paper. (panda-25)
for lp=26:length(sortedPanda)
    CoregInputs.RefImgPath=[pathOfPandaNav,filesep,sortedPanda{lp,:}];
    CoregInputs.MaskImgPath{1,:}=[pathOfPandaMask,filesep,'MR-mask-25.nii'];
    CoregInputs.MaskImgPath{2,:}=[pathOfPandaBrain,filesep,'Brain-25.nii'];
    CoregInputs.Interp=0;
    CoregInputs.Prefix='Moved-';
    Coregistration_job(CoregInputs);
    cd(pathOfPandaMask)
    oldFile=dir('Moved*')
    movefile(oldFile.name,['MR-mask-',num2str(lp),'.nii']);
    cd(pathOfPandaBrain)
    oldFile=dir('Moved*')
    movefile(oldFile.name,['Brain-',num2str(lp),'.nii']);
end
end





