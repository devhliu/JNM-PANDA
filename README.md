# Log-book
This repository contains the codes that were developed for the manuscript - "PANDA - PET nAvigators usiNg Deep leArning: A data-driven approach to perform automatic motion correction in 18F-FDG dynamic PET brain studies"

# Problems and solutions

* The time-of-flight MR angiography (TOF-MRA) was acquired at the start of the dynamic scan (time, t=0), whereas the usable PANDA navigator starts at 4 min. There is a considerable chance that the two volumes are not perfectly aligned
  * First, we tried to register the time-of-flight MR angiography with the PANDA navigator (as it has enough fake information for NMI registration) and apply the same transformation matrix to the MR-mask. However, the registration was not perfect because of the wrap-around artefacts present in some TOF-MRA images.
  * After some thorough discussions, we agreed to manually align the TOF-MRA and the MR mask with the PET frame 25. This will be the only interaction mandated by the user. Since the MR-mask is now aligned with the reference volume of PET frame 25 (acquired at 4 min), everything after this step is automated. 
    * Manual alignment procedure: 
      1. Using AMIDE open the PET frame 25, along with TOF-MRA, MR-mask and brain mask
      2. Manually align the TOF-MRA (moving) to the PET-frame 25 (fixed).
      3. Once aligned, right-click TOF-MRA to open the dialog box. 
      4. Click the "Center" tab and copy the 'x', 'y' and 'z' offsets and paste it on "Center" fields of the MR-mask, brain mask volumes. This is pretty much applying the transformation matrix to the other volumes. Of course, you can also rotate using the "rotate" tab, but the entries should be manually entered to other volumes.
      5. Now, right-click the MR mask, in the "Basic Info" dialog box, change the modality to "MRI". This is very important for reading in the volumes back to MATLAB.
      6. Do the same for the brain mask.
      7. To export the aligned masks, Go to "File"->"Export Data set", in the export option - click "Resliced orientation", change the voxel size to exactly match the PET voxel size (critical!). And choose the export format as "DICOM via DCMTK", nothing else (don't be adventurous)
     
    
