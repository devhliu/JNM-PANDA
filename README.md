# Overview
This repository contains the codes that were developed for the manuscript - "PANDA - PET nAvigators usiNg Deep leArning: A data-driven approach to perform automatic motion correction in 18F-FDG dynamic PET brain studies"

# Log book of Problems and solutions

* The time-of-flight MR angiography (TOF-MRA) was acquired at the start of the dynamic scan (time, t=0), whereas the usable PANDA navigator starts at 4 min. There is a considerable chance that the two volumes are not perfectly aligned
  * First, we tried to register the time-of-flight MR angiography with the PANDA navigator (as it has enough fake information for NMI registration) and apply the same transformation matrix to the MR-mask. However, the registration was not perfect because of the wrap-around artefacts present in some TOF-MRA images.
  * After some thorough discussions, we agreed to manually align the TOF-MRA and the MR mask with the PET frame 25. This will be the only interaction mandated by the user. Since the MR-mask is now aligned with the reference volume of PET frame 25 (acquired at 4 min), everything after this step is automated. 
    * Manual alignment procedure: 
       1. Use ITK snap to open the PET-frame-25.nii (naming convention based on our work-flow).
       2. Similarly open the high-resolution TOF-MRA angiography volume and the high-resolution carotid mask as an "additional image". 
       3. Follow the animation on how to manually align, Since our TOF-MRA image was acquired on an integrated PET/MR, it was fairly easy. However, if it was acquired on a seperate system, the manual alignment will take some time.
