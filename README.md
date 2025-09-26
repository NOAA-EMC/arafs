# Atmospheric River Analysis and Forecast System

Atmospheric River Analysis and Forecast System (ARAFS) is a high-resolution regional modeling system within the Unified Forecast System (UFS) framework for advancing Atmospheric River forecasts based on Hurrican Analysis and Forecast System (HAFS) and Rapid Refresh Forecast System (RRFS).

For information about how to contribute to ARAFS development, please review the [code repository governance](https://github.com/hafs-community/HAFS/wiki/HAFS-Code-Repository-Governance).  

# Disclaimer

This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.

How to use the workflow to run a test
A. Get the code

For example, git clone https://github.com/NOAA-EMC/arafs

cd arafs

git checkout arafs_test

git submodule update --init --recursive
B. Build and install

cd sorc

./build_all.sh

./install_all.sh

./link_fix.sh
C. Configure

Edit system.conf in arafs/parm:

disk_project (your project)

cpu_account (your account)

CDSAVE (your directory where you install your “ARAFS”)

CDSCRUB (where you will find the model output)

Edit physics configuration file, e.g.

parm/arafs_exp4.conf

cd arafs/rocoto

In cronjob_arafs_3km.sh, change(or add)

HOMEarafs=${HOMEarafs:-{your ARAFS directory}}
D. Run ARAFS

Edit cronjob_arafs_3km.sh to use your own configurations and forecast dates

sh cronjob_arafs_3km.sh
E. Available gfs data for input:

Gaea/C6:

/gpfs/f6/drsa-hurr4/scratch/Keqin.Wu/arafs-input/ctrl

Hera:

/scratch4/NCEPDEV/hurricane/save/Keqin.Wu/arafs-input/ctrl
