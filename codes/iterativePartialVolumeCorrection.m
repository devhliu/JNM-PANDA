function [ipvcOutputs] = iterativePartialVolumeCorrection(iPVCinputs)

%% Hard-coded variables : 

numberOfThresholds        =    10;                                         % Define the number of thresholds for otsu thresholding (the number 20 is basically chosen in a random manner)
widthOfSE                 =    10;
plasmaInputFunction       =    iPVCinputs.plasmaInputFunction;
toleranceLevel            =    1;

%% Local-variable pass for preventing parallel computing overhead

crossCalibrationFactor    =    iPVCinputs.crossCalibrationFactor;

%% Read in PET volumes 

cd(iPVCinputs.pathOfPET); % go to the folder containing the nifti pet volumes 

PETfiles=dir('*nii'); PETfiles=PETfiles(arrayfun(@(x) x.name(1), PETfiles) ~= '.'); % read the PET files in the folder

parfor lp=1:length(PETfiles)
    PETfilesToSort{lp,:}=PETfiles(lp).name;
end
sortedPETfiles=natsort(PETfilesToSort); % sorting the pet files based on their name.

parfor lp=1:length(PETfiles)
    PET{lp}=spm_read_vols(spm_vol(sortedPETfiles{lp}))./(crossCalibrationFactor); % loading the pet files.
    petHdr{lp}=spm_vol(sortedPETfiles{lp});
    disp(['Reading ',sortedPETfiles{lp},'...']);
end
PETframeStruct=petHdr{1}; % grab the header information for further


%% Normalized psfSigma based on PET voxel size. 
xDim=abs(PETframeStruct.mat(1,1)); % get the voxel size (x dimension)
yDim=abs(PETframeStruct.mat(2,2));% get the voxel size (y dimension)
zDim=abs(PETframeStruct.mat(3,3));% get the voxel size (z dimension)
voxelSize=[xDim yDim zDim];

% normalize the FWHM to voxel size 

if numel(iPVCinputs.psfFWHM)==1
    psfFWHM=[iPVCinputs.psfFWHM iPVCinputs.psfFWHM iPVCinputs.psfFWHM]; % isotropic filtering.                
else
end

psfFWHM  = psfFWHM./voxelSize; % normalizing the fwhm to the pet voxel dimensions.
psfSigma = psfFWHM/sqrt(8*log(2)); % calculating the sigma from fwhm    

%% calculate pet mid time

[PETframingMidPoint]=getPETmidTime();

%% Read in MR masks and brain masks (all aligned)

% Read in mr masks

cd(iPVCinputs.pathOfAlignedMRmasks)
mrMaskFiles=dir('MR*');
parfor lp=1:length(mrMaskFiles)
    mrMaskFilesToSort{lp,:}=mrMaskFiles(lp).name;
end
sortedMRmasks=natsort(mrMaskFilesToSort); % sorting the pet files based on their name.

parfor lp=1:length(sortedMRmasks)
    carotidMasks{lp}=spm_read_vols(spm_vol(sortedMRmasks{lp}));  
    disp(['Reading ',sortedMRmasks{lp},'...'])
end

% Read in brain masks 

cd(iPVCinputs.pathOfAlignedBrainMasks)
brainMaskFiles=dir('Brain*');
parfor lp=1:length(brainMaskFiles)
    nativeBrain=strcmp(brainMaskFiles(lp).name,'Brain-mask.nii')
    if nativeBrain == 1 
        brainFiles2Sort{lp,:}=[];
    else
        brainFiles2Sort{lp,:}=brainMaskFiles(lp).name;
    end
end
brainFiles2Sort=brainFiles2Sort(~cellfun('isempty',brainFiles2Sort))

sortedBrainMasks=natsort(brainFiles2Sort);

parfor lp=1:length(sortedBrainMasks)
    brainMasks{lp}=spm_read_vols(spm_vol(sortedBrainMasks{lp}));
    disp(['Reading ',sortedBrainMasks{lp},'...'])
end


%% Calculate the recovery coefficients for the carotid artery

parfor lp=1:length(PET)
    recoveryCoefficients{lp}=imgaussfilt3(double(carotidMasks{lp}),psfSigma);
end


%% Create background mantel from the edges of the carotid artery. 

SE = strel('cube',widthOfSE);   
parfor lp=1:length(PETfiles)
    backgroundMantel{lp}=imdilate(carotidMasks{lp},SE)-carotidMasks{lp};
    disp(['Background mantel ',num2str(lp),' created!']);
    significantBrain{lp}=backgroundMantel{lp}.*brainMasks{lp};
    brainSpillOutGeometry{lp}=(imgaussfilt3(double(significantBrain{lp}),psfSigma))>0.03; 
    arterySpillOutGeometry{lp}=recoveryCoefficients{lp}>0.03;
    cranialMixedZone{lp}=(brainSpillOutGeometry{lp}.*~significantBrain{lp});
    cranialMixedZone{lp}=cranialMixedZone{lp}.*(arterySpillOutGeometry{lp}.*~carotidMasks{lp});
    caudalMixedZone{lp}=arterySpillOutGeometry{lp}-(carotidMasks{lp}+cranialMixedZone{lp});
end
disp('Cranial Mixed zone geoemetry calculated...');
disp('Part of the brain which contributes to the spill-over to carotid calculated...');
disp('Background mantel calculated...');



%% Visualize the intensities in the above mentioned segments.
figure,
ylabel('Activity kBq/mL');xlabel('Time in seconds');title('Raw Activity analysis');
arteryProfile=animatedline('Color','red','Marker','o','LineWidth',3);
brainProfile=animatedline('Color','green','Marker','o','LineWidth',3);
cranialMixedZoneProfile=animatedline('Color','blue','Marker','o','LineWidth',3);
caudalMixedZoneProfile=animatedline('Color','black','Marker','o','LineWidth',3);
arteryProfile.DisplayName='Artery activity';
brainProfile.DisplayName='Brain activity';
cranialMixedZoneProfile.DisplayName='Cranial mixed zone activity';
caudalMixedZoneProfile.DisplayName='Caudal mixed zone activity';
for lp=1:length(significantBrain)
    brainTAC(lp)=median(PET{lp}(significantBrain{lp}>0))/1000;
    arteryTAC(lp)=mean(PET{lp}(carotidMasks{lp}>0))/1000;
    cranialTAC(lp)=median(PET{lp}(cranialMixedZone{lp}>0))/1000;
    caudalTAC(lp)=median(PET{lp}(caudalMixedZone{lp}>0))/1000;
    addpoints(brainProfile,PETframingMidPoint(lp),brainTAC(lp));
    hold on
    if arteryTAC(lp)<0
        arteryTAC(lp)=0;
    end
    addpoints(arteryProfile,PETframingMidPoint(lp),arteryTAC(lp));
    addpoints(cranialMixedZoneProfile,PETframingMidPoint(lp),cranialTAC(lp));
    addpoints(caudalMixedZoneProfile,PETframingMidPoint(lp),caudalTAC(lp));
    arteryProfile.DisplayName='Artery activity';
    brainProfile.DisplayName='Brain activity';
    cranialMixedZoneProfile.DisplayName='Cranial mixed zone activity';
    caudalMixedZoneProfile.DisplayName='Caudal mixed zone activity';
    legend(arteryProfile.DisplayName,brainProfile.DisplayName,cranialMixedZoneProfile.DisplayName,caudalMixedZoneProfile.DisplayName,'FontSize',20);
    drawnow;
end
arteryTAC(arteryTAC<0)=0;

interpArteryTAC=interp1(PETframingMidPoint,arteryTAC,1:3600,'pchip');
ipvcOutputs.arteryTACarea=trapz(interpArteryTAC);


% Logic for performing partial volume correction based on activity distribution as a function of time.

framesContainingProminentSpillOutFromArtery=(round(arteryTAC,2)>round(brainTAC,2));% & (round(caudalTAC,2)>round(cranialTAC,2));
framesContainingProminentSpillOutFromBrain=(round(arteryTAC,2)<round(brainTAC,2));% & (round(caudalTAC,2)<round(cranialTAC,2)) & (round(arteryTAC,2)<round(cranialTAC,2));
earlyFrames=find(framesContainingProminentSpillOutFromArtery);
lateFrames=find(framesContainingProminentSpillOutFromBrain);
plot(PETframingMidPoint(framesContainingProminentSpillOutFromArtery),arteryTAC(framesContainingProminentSpillOutFromArtery),'mo--','LineWidth',2)
hold on
plot(PETframingMidPoint(framesContainingProminentSpillOutFromBrain),arteryTAC(framesContainingProminentSpillOutFromBrain),'ko--','LineWidth',2)

%%
% Perform correction for early frames.
% Logic behind this correction: Early frames have very high activity in the
% artery and very less activity in the brain. Therefore it is sufficient to
% perform spill-out correction only.

PVCProfile=animatedline('Color','cyan','Marker','o','LineWidth',3);
PVCProfile_1=animatedline('Color','blue','Marker','p','LineWidth',3);
PVCProfile_2=animatedline('Color','magenta','Marker','p','LineWidth',3);
frameSegmentOne=earlyFrames;

if isempty(frameSegmentOne)
    frameSegmentOne=1:26;
end

for lp=1:length(frameSegmentOne)
   indexOfInterest=frameSegmentOne(lp);
   spillOutCorrected=PET{indexOfInterest}./recoveryCoefficients{indexOfInterest};
    pvcTarget(indexOfInterest)=(mean(spillOutCorrected(carotidMasks{indexOfInterest}>0))./1000);
    [mask_1,mask_2]=VolumePartitioner(carotidMasks{indexOfInterest}>0);
    pvcTarget1(indexOfInterest)=(mean(spillOutCorrected(mask_1>0))./1000);
    pvcTarget2(indexOfInterest)=(mean(spillOutCorrected(mask_2>0))./1000);
    if pvcTarget(indexOfInterest)<0
        pvcTarget(indexOfInterest)=0;
        pvcTarget1(indexOfInterest)=0;
        pvcTarget2(indexOfInterest)=0;
    end
    addpoints(PVCProfile,PETframingMidPoint(indexOfInterest),pvcTarget(indexOfInterest));
    drawnow
    text(PETframingMidPoint(lp),pvcTarget(lp)+2,num2str(lp));

end


%% Partial volume correction for middle frames: Artery activity ~= Brain activity

for lp=26:33
    fusedBrain=significantBrain{lp}.*PET{lp}; % sample the background brain activity from PET, which contributes to the spill-over in a significant manner.
    scaledBrain=performOtsu(fusedBrain,numberOfThresholds); % account for circumferential variability
    brainContribution=imgaussfilt3(scaledBrain,psfSigma); % calculate the spill-over factors.
    brainContribution=brainContribution.*~significantBrain{lp}; % isolate spill-over factors to mixed-zone, not to the brain.
    brainContribution=brainContribution.*~carotidMasks{lp}; % isolate spill-over factors to mixed-zone, not to the artery.
    modPET=PET{lp}; % Passing the original PET volume to a dummy PET variable.
    convergenceAchieved=false;
    [initialEstimate,newPET, newEstimate_1,newEstimate_2]=hardPVC(modPET,backgroundMantel{lp},numberOfThresholds,psfSigma,recoveryCoefficients{lp},double(carotidMasks{lp}));
    initialEstimate=initialEstimate*1000; % Initial crude estimate of the ICA, obtained from the previous step and conversion from kBq/mL to Bq/mL
    incrm=0;
    while convergenceAchieved==false
            incrm=incrm+1; 
            % clean mixed zone and recalculate
            modPET=PET{lp}-brainContribution;
            modPET(modPET<0)=0;
            scaledArtery=initialEstimate.*carotidMasks{lp};
            arteryContribution=imgaussfilt3(scaledArtery,psfSigma);
            arteryContribution=arteryContribution.*~carotidMasks{lp};
            modPET=modPET-arteryContribution;
            modPET(modPET<0)=0;
            [newEstimate,newPET, newEstimate_1,newEstimate_2]=hardPVC(modPET,backgroundMantel{lp},numberOfThresholds,psfSigma,recoveryCoefficients{lp},double(carotidMasks{lp}));
            newEstimateVec(incrm)=newEstimate;
            relDiff=abs((((newEstimate*1000)-initialEstimate)./initialEstimate)*100);
            disp(['Processing Frame: ',num2str(lp),'! The relative difference is ',num2str(relDiff),'!'])
            initialEstimate=newEstimate*1000;
            relDiffVec(incrm)=relDiff;
          
            if incrm==1
                convergenceAchieved=false; % proceeds the calculation
            else
                isConverging          = relDiffVec(incrm) < relDiffVec(incrm-1);
                isAboveToleranceLevel = relDiffVec(incrm) > toleranceLevel;
       
                if isConverging && isAboveToleranceLevel
                    convergenceAchieved = false; % continue calculating new estimates
                end
        
                if isConverging && ~(isAboveToleranceLevel)
                    convergenceAchieved = true;  % stop calculating
                    disp(['Convergence achieved at iteration no: ',num2str(incrm)]);
                end
        
                if ~(isConverging) && ~(isAboveToleranceLevel)
                    convergenceAchieved = true; % stop calculating
                    disp(['Convergence achieved at iteration no: ',num2str(incrm)]);
                    newEstimate=newEstimateVec(incrm-1);
                    newEstimate_1=newEstimate_1_Vec(incrm-1);
                    newEstimate_2=newEstimate_2_Vec(incrm-1);
                end
            end
    end   
        if newEstimate<0
            newEstimate=0;
        end
        if newEstimate_1<0
            newEstimate_1=0;
        end
        if newEstimate_2<0
            newEstimate_2=0;
        end
        pvcTarget(lp)=newEstimate;
        pvcTarget1(lp)=newEstimate_1;
        pvcTarget2(lp)=newEstimate_2;
        addpoints(PVCProfile,PETframingMidPoint(lp),pvcTarget(lp));
        addpoints(PVCProfile_1,PETframingMidPoint(lp),pvcTarget1(lp));
        addpoints(PVCProfile_2,PETframingMidPoint(lp),pvcTarget2(lp));
        drawnow
        text(PETframingMidPoint(lp),pvcTarget(lp)+2,num2str(lp));

end

%% Partial volume correction for middle frames: Brain activity >> Artery activity

for lp=34:length(PET)
    fusedBrain=significantBrain{lp}.*PET{lp};
    scaledBrain=performOtsu(fusedBrain,numberOfThresholds);
    brainContribution=imgaussfilt3(scaledBrain,psfSigma);
    brainContribution=brainContribution.*~significantBrain{lp};
    newBrainContribution=brainContribution;
    modPET=PET{lp};
    %relDiff=10;
    convergenceAchieved = false;
    [initialEstimate,newPET, newEstimate_1,newEstimate_2]=hardPVC(modPET,backgroundMantel{lp},numberOfThresholds,psfSigma,recoveryCoefficients{lp},double(carotidMasks{lp}));
    initialEstimate=initialEstimate*1000; % conversion from kBq/mL to Bq/mL
    incrm=0;
    while convergenceAchieved == false 
        incrm=incrm+1; 
        % clean mixed zone and recalculate
        modPET=PET{lp}-newBrainContribution;
        modPET(modPET<0)=0;
        scaledArtery=initialEstimate.*carotidMasks{lp};
        arteryContribution=imgaussfilt3(scaledArtery,psfSigma);
        arteryContribution=arteryContribution.*~carotidMasks{lp};
        arteryContribution=arteryContribution.*~significantBrain{lp};
        modPET=modPET-arteryContribution;
        modPET(modPET<0)=0;
        [newEstimate,newPET, newEstimate_1,newEstimate_2]=hardPVC(modPET,backgroundMantel{lp},numberOfThresholds,psfSigma,recoveryCoefficients{lp},double(carotidMasks{lp}));
        newEstimateVec(incrm)=newEstimate;
        newEstimate_1_Vec(incrm)=newEstimate_1;
        newEstimate_2_Vec(incrm)=newEstimate_2;
        relDiff=abs((((newEstimate*1000)-initialEstimate)./initialEstimate)*100);
        disp(['Processing Frame: ',num2str(lp),'! The relative difference is ',num2str(relDiff),'!'])
        initialEstimate=newEstimate*1000;
        relDiffVec(incrm)=relDiff;
        relDiffVec(relDiffVec==0)=[]; 
        if incrm==1
            convergenceAchieved=false; % proceeds the calculation
        else
            isConverging          = relDiffVec(incrm) < relDiffVec(incrm-1);
            isAboveToleranceLevel = relDiffVec(incrm) > toleranceLevel;
       
            if isConverging && isAboveToleranceLevel
                convergenceAchieved = false; % continue calculating new estimates
            end
        
            if isConverging && ~(isAboveToleranceLevel)
                convergenceAchieved = true;  % stop calculating 
                disp(['Convergence achieved at iteration no: ',num2str(incrm)]);
            end
        
            if ~(isConverging) && ~(isAboveToleranceLevel)
                convergenceAchieved = true; % stop calculating 
                disp(['Convergence achieved at iteration no: ',num2str(incrm)]);
                newEstimate=newEstimateVec(incrm-1);
                newEstimate_1=newEstimate_1_Vec(incrm-1);
                newEstimate_2=newEstimate_2_Vec(incrm-1);
            end
        end
    
    end   
    if newEstimate<0
        newEstimate=0;
    end
    if newEstimate_1<0
        newEstimate_1=0;
    end
    if newEstimate_2<0
        newEstimate_2=0;
    end
    pvcTarget(lp)=newEstimate;
    pvcTarget1(lp)=newEstimate_1;
    pvcTarget2(lp)=newEstimate_2;
    addpoints(PVCProfile,PETframingMidPoint(lp),pvcTarget(lp));
    addpoints(PVCProfile_1,PETframingMidPoint(lp),pvcTarget1(lp));
    addpoints(PVCProfile_2,PETframingMidPoint(lp),pvcTarget2(lp));
    drawnow
    text(PETframingMidPoint(lp),pvcTarget(lp)+2,num2str(lp));
    
end 
if isempty(pvcTarget1) 
   pvcTarget1=pvcTarget;
else
    if isnan(pvcTarget1)
        pvcTarget1=pvcTarget;
    else
    end
end
if isempty(pvcTarget2) 
    pvcTarget2=pvcTarget;
else
    if isnan(pvcTarget2)
        pvcTarget2=pvcTarget;
    else
    end
end
IDIFpostProcessingParameters.time=PETframingMidPoint./60;
IDIFpostProcessingParameters.P2Bratio=iPVCinputs.p2bRatio;
IDIFpostProcessingParameters.IDIF=pvcTarget;
[postProcessedIDIF]=IDIFpostProcessing(IDIFpostProcessingParameters);
IDIFpostProcessingParameters.IDIF=pvcTarget1;
[postProceesedIDIF_1]=IDIFpostProcessing(IDIFpostProcessingParameters);
IDIFpostProcessingParameters.IDIF=pvcTarget2;
[postProceesedIDIF_2]=IDIFpostProcessing(IDIFpostProcessingParameters);

time=1:3600;
plot(time,postProcessedIDIF,'b-','LineWidth',2)
%% // to uncomment
interpAIF=interp1((plasmaInputFunction.time_minutes_.*60),plasmaInputFunction.value_kBq_cc_,1:3600,'pchip');
interpAIF(isnan(interpAIF))=0;
[alignedIDIF,alignedAIF,delayPoints]=alignsignals((postProcessedIDIF),interpAIF);
[alignedIDIF1,alignedAIF,delayPoints]=alignsignals((postProceesedIDIF_1),interpAIF);
[alignedIDIF2,alignedAIF,delayPoints]=alignsignals((postProceesedIDIF_2),interpAIF);
figure,plot(time,alignedIDIF(time),'mo-');hold on
plot(time,alignedIDIF1(time),'ko-');
plot(time,alignedIDIF2(time),'yo-');
plot(time,alignedAIF(time),'bo-');
hLegend=legend('Image-derived input function','Mask-1: IDIF','Mask-2: IDIF','Arterial input function')
hLegend.FontSize=20;
xlabel('Time in seconds','FontSize',20);
ylabel('Activity in kBq/mL','FontSize',20);
aucAIF=trapz(time,alignedAIF(time));
aucIDIF=trapz(time,alignedIDIF(time));
rAUC=aucIDIF/aucAIF;
disp([' The similarity ratio is ',num2str(rAUC),'!'])
aucIDIF_1=trapz(time,alignedIDIF1(time));
rAUC_1=aucIDIF_1/aucAIF;
aucIDIF_2=trapz(time,alignedIDIF2(time));
rAUC_2=aucIDIF_2/aucAIF;
disp([' The similarity ratio is ',num2str(rAUC_1),'!'])
disp([' The similarity ratio is ',num2str(rAUC_2),'!'])

frameNumbers=1:length(PET); rotAlignedIDIF=alignedIDIF'; 
text(PETframingMidPoint,(rotAlignedIDIF(round(PETframingMidPoint))+2),num2str(frameNumbers'));

% // to uncomment 
%% Saving the analysis report. // to uncomment

title([iPVCinputs.subjectID,': The similarity ratio is ',num2str(rAUC), 'Mask_1: ',num2str(rAUC_1),' Mask_2: ',num2str(rAUC_2),'!'],'FontSize',20);
set(gcf,'position',get(0,'ScreenSize')) % expand figure to whole screen;
cd(iPVCinputs.whereToProcess);
saveas(gcf,[iPVCinputs.AC,iPVCinputs.subjectID,'PANDA_IDIF_AIF','.png']);
IDIFtxtCreator(time,alignedIDIF(time),[iPVCinputs.AC,iPVCinputs.subjectID ,'_Aligned_IDIF']);
delayPoints=-delayPoints; % change the sign for matching the AIF to IDIF
modTime=(time+delayPoints);
IDIFtxtCreator(modTime,interpAIF,[iPVCinputs.AC,iPVCinputs.subjectID,'_DC_AIF']);
% // to uncomment
title([iPVCinputs.subjectID],'FontSize',20);
set(gcf,'position',get(0,'ScreenSize')) % expand figure to whole screen;
cd(iPVCinputs.whereToProcess);
IDIFtxtCreator(time,postProcessedIDIF,[iPVCinputs.AC,iPVCinputs.subjectID,'_PANDA_native_IDIF']);
IDIFtxtCreator(time,postProceesedIDIF_1,[iPVCinputs.AC,iPVCinputs.subjectID,'_PANDA_mask_1_IDIF']);
IDIFtxtCreator(time,postProceesedIDIF_2,[iPVCinputs.AC,iPVCinputs.subjectID,'_PANDA_mask_2_IDIF']);
%IDIFtxtCreator(PETframingMidPoint,arteryTAC,[PVC.AC,'_No_MoCo_',PVC.subjectID,'_RAW_IDIF']);
%save('Artery_values',arteryTAC);
%% // to uncomment
ipvcOutputs.IDIF=alignedIDIF(time);
ipvcOutputs.Time=time;
ipvcOutputs.rAUC1=rAUC_1;
ipvcOutputs.rAUC2=rAUC_2;
ipvcOutputs.rAUC=rAUC;
ipvcOutputs.RMSE = sqrt((mean((alignedAIF(time)-alignedIDIF(time)).^2)));
ipvcOutputs.APD=abs((aucIDIF-aucAIF)/aucAIF)*100;
disp(['Absolute percentage difference: ',num2str(ipvcOutputs.APD)]);
ipvcOutputs.rawAUC=(ipvcOutputs.arteryTACarea./aucAIF)
disp(['RMSE: ', num2str(ipvcOutputs.RMSE)]); 
% to uncomment
end

% function which performs the second pvc after the background is modelled accurately.
function [lateFramesPVC,newPET, newEstimate_1,newEstimate_2]=hardPVC(PETimg,backgroundRegion,numberOfThresholds,psfSigma,recoveryCoefficients,carotidMasks)
        fusedBG=PETimg.*backgroundRegion;
        scaledBackground=performOtsu(fusedBG,numberOfThresholds);
        spillInToArtery=imgaussfilt3(scaledBackground,psfSigma);
        spillInCorrectedPET=PETimg-spillInToArtery;
        spillInCorrectedPET(spillInCorrectedPET<0)=0;
        spillOutCorrectedPET=spillInCorrectedPET./recoveryCoefficients;
        spillOutCorrectedPET(isinf(spillOutCorrectedPET))=0;
        spillOutCorrectedPET(isnan(spillOutCorrectedPET))=0;
        newPET=spillOutCorrectedPET;
        pvcTarget=mean(spillOutCorrectedPET(carotidMasks>0))./1000;
        lateFramesPVC=pvcTarget;
        [mask1,mask2]=VolumePartitioner(carotidMasks>0);
        newEstimate_1=mean(spillOutCorrectedPET(mask1>0))./1000;
        newEstimate_2=mean(spillOutCorrectedPET(mask2>0))./1000;
end
