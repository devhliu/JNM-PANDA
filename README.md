# Log-book
This repository contains the codes that were developed for the manuscript - "PANDA - PET nAvigators usiNg Deep leArning: A data-driven approach to perform automatic motion correction in 18F-FDG dynamic PET brain studies"

# Problems and solutions

* The time-of-flight MR angiography (TOF-MRA) was acquired at the start of the dynamic scan (time, t=0), whereas the usable PANDA navigator starts at 4 min. There is a huge chance that the two volumes are not perfectly aligned
  * First, we tried to register the time-of-flight MR angiography with the PANDA navigator (as it has enough fake information for NMI registration) and apply the same transformation matrix to the MR-mask. However, the registration was not perfect, because of the wrap-around artifacts present in some TOF-MRA images.
  * After some thorough discussions, we agreed to manually align the TOF-MRA and the MR mask with the PET frame 25. This will be the only interaction mandated by the user. Since the MR-mask is now aligned with the reference volume of PET frame 25 (acquired at 4 min), everything after this step is automated. 
    * Manual alignment
