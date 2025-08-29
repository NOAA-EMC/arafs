#!/bin/sh
################################################################################
# Script Name: exhafs_ocn_prep.sh
# Authors: NECP/EMC Hurricane Project Team and UFS Hurricane Application Team
# Abstract:
#   This script runs the HAFS oceanic preprocessing steps to generate MOM6
#   coupling needed ocean initial condition (IC), open boundary condition (OBC)
#   and atmospheric forcings.
# History:
#   05/13/2023: Enabled MOM6 coupling in HAFS application/workflow
# Condition codes:
#   == 0 : success
#   != 0 : fatal error encounted
################################################################################
set -x -o pipefail
module load ncl
which ncl

CDATE=${CDATE:-${YMDH}}
cyc=${cyc:-00}
STORM=${STORM:-FAKE}
STORMID=${STORMID:-00L}

ymd=`echo $CDATE | cut -c 1-8`
hour=`echo $CDATE | cut -c 9-10`
CDATEprior=`${NDATE} -6 $CDATE`
ymd_prior=`echo ${CDATEprior} | cut -c1-8`
cyc_prior=`echo ${CDATEprior} | cut -c9-10`

pubbasin2=${pubbasin2:-AL}
if [ ${ocean_domain:-auto} = "auto" ]; then

if [ ${pubbasin2} = "AL" ] || [ ${pubbasin2} = "EP" ] || [ ${pubbasin2} = "CP" ] || \
   [ ${pubbasin2} = "SL" ] || [ ${pubbasin2} = "LS" ]; then
#  ocean_domain=nhc
  ocean_domain=ar2
elif [ ${pubbasin2} = "WP" ] || [ ${pubbasin2} = "IO" ]; then
  ocean_domain=jtnh
elif [ ${pubbasin2} = "SH" ] || [ ${pubbasin2} = "SP" ] || [ ${pubbasin2} = "SI" ]; then
  ocean_domain=jtsh
else
  echo "FATAL ERROR: Unknown/unsupported basin of ${pubbasin2}"
  exit 1
fi

fi

if [ "${hour}" == "00" ]; then
  type=${type:-n}
else
  type=${type:-f}
fi

# Make the intercom dir
mkdir -p ${WORKhafs}/intercom/ocn_prep/mom6

DATA=${DATA:-${WORKhafs}/ocn_prep}
mkdir -p ${DATA}
cd $DATA

#==============================================================================
# Generate MOM6 ICs from RTOFS
mkdir -p ${DATA}/mom6_init
cd ${DATA}/mom6_init

# Link global RTOFS depth and grid files
if [ ${pubbasin2} = "AL" ] || [ ${pubbasin2} = "EP" ] || [ ${pubbasin2} = "CP" ] || \
   [ ${pubbasin2} = "SL" ] || [ ${pubbasin2} = "LS" ]; then
  ${NLN} ${FIXhafs}/fix_hycom/rtofs_glo.navy_0.08.regional.depth.a regional.depth.a
  ${NLN} ${FIXhafs}/fix_hycom/rtofs_glo.navy_0.08.regional.depth.b regional.depth.b
elif [ ${pubbasin2} = "WP" ] || [ ${pubbasin2} = "IO" ] || \
     [ ${pubbasin2} = "SH" ] || [ ${pubbasin2} = "SP" ] || [ ${pubbasin2} = "SI" ]; then
  ${NLN} ${FIXhafs}/fix_mom6/fix_gofs/depth_GLBb0.08_09m11ob.a regional.depth.a
  ${NLN} ${FIXhafs}/fix_mom6/fix_gofs/depth_GLBb0.08_09m11ob.b regional.depth.b
else
  echo "FATAL ERROR: Unknown/supported basin of ${pubbasin2}"
  exit 1
fi

${NLN} ${FIXhafs}/fix_hycom/rtofs_glo.navy_0.08.regional.grid.a regional.grid.a
${NLN} ${FIXhafs}/fix_hycom/rtofs_glo.navy_0.08.regional.grid.b regional.grid.b

# Link global RTOFS analysis or forecast files
if [ -e ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.a ]; then
  ${NLN} ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.a archv_in.a
elif [ -e ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.a.tgz ]; then
  tar -xpvzf ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.a.tgz
  ${NLN} rtofs_glo.t00z.${type}${hour}.archv.a archv_in.a
else
  echo "FATAL ERROR: ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.a does not exist."
  echo "FATAL ERROR: ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.a.tgz does not exist either."
  echo "FATAL ERROR: Cannot generate MOM6 IC. Exiting"
  exit 1
fi
if [ -e ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.b ]; then
  ${NLN} ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.b archv_in.b
else
  echo "FATAL ERROR: ${COMINrtofs}/rtofs.$ymd/rtofs_glo.t00z.${type}${hour}.archv.b does not exist."
  echo "FATAL ERROR: Cannot generate MOM6 IC. Exiting"
  exit 1
fi

outnc_2d=ocean_ssh_ic.nc
outnc_ts=ocean_ts_ic.nc
outnc_uv=ocean_uv_ic.nc
export CDF038=rtofs_${outnc_2d}
export CDF034=rtofs_${outnc_ts}
export CDF033=rtofs_${outnc_uv}

# run HYCOM-tools executables to produce IC netcdf files
${NCP} ${PARMmom6}/hafs_mom6_${ocean_domain}.rtofs_ocean_ssh_ic.in ./rtofs_ocean_ssh_ic.in
${APRUNS} ${EXEChafs}/hafs_hycom_utils_archv2ncdf2d.x < ./rtofs_ocean_ssh_ic.in 2>&1 | tee ./archv2ncdf2d_ssh_ic.log
export err=$?; err_chk

${NCP} ${PARMmom6}/hafs_mom6_${ocean_domain}.rtofs_ocean_3d_ic.in ./rtofs_ocean_3d_ic.in
${APRUNS} ${EXEChafs}/hafs_hycom_utils_archv2ncdf3z.x < ./rtofs_ocean_3d_ic.in 2>&1 | tee archv2ncdf3z_3d_ic.log
export err=$?; err_chk

if [ ${ocean_domain} == "ar2" ]; then
  ${NCP} ${FIXhafs}/fix_mom6_${ocean_domain}/map_rtofs_to_ar2_regular.nc .
  ${NCP} ${FIXhafs}/fix_mom6_${ocean_domain}/lon_lat_ar2_regular_grid.nc .
  cp ${USHhafs}/ncl/regrid_ssh.ncl .
  cp ${USHhafs}/ncl/regrid_ts.ncl .
  cp ${USHhafs}/ncl/regrid_uv_no_stagger.ncl .

# get ocean_ssh_ic.nc
  ncl <  regrid_ssh.ncl

# get ocean_ts_ic.nc
  ncl <  regrid_ts.ncl

# get ocean_uv_ic_no_stagger.nc
  ncl < regrid_uv_no_stagger.ncl

# Average velocities on u and v points in order to
#    stagger them
  cp ${USHhafs}/stagger_uv_from_ts_points.py .
  python stagger_uv_from_ts_points.py lon_lat_ar2_regular_grid.nc ocean_uv_no_stagger.nc ocean_uv_ic.nc
fi

# Deliver to intercom
${NCP} -p ${outnc_2d} ${WORKhafs}/intercom/ocn_prep/mom6/ocean_ssh_ic.nc
${NCP} -p ${outnc_ts} ${WORKhafs}/intercom/ocn_prep/mom6/ocean_ts_ic.nc
${NCP} -p ${outnc_uv} ${WORKhafs}/intercom/ocn_prep/mom6/ocean_uv_ic.nc

#==============================================================================

# Generate MOM6 OBC from RTOFS
mkdir -p ${DATA}/mom6_init
cd ${DATA}/mom6_init

#IFHR=0
#FHR=0
#FHR2=$(printf "%02d" "$FHR")
#FHR3=$(printf "%03d" "$FHR")
#NOBCHRS=24

# Run Python script to generate OBC
#${NLN} ${FIXhafs}/fix_mom6/${ocean_domain}/ocean_hgrid.nc ./
${NLN} ${FIXhafs}/fix_mom6_${ocean_domain}/ocean_hgrid.nc ./
cp ${USHhafs}/hafs_mom6_obc_from_rtofs.py .
cp ${USHhafs}/mom6_obc/*.py .
${APRUNS} hafs_mom6_obc_from_rtofs.py \
    ocean_ssh_ic.nc ocean_ts_ic.nc ocean_uv_no_stagger.nc \
    ocean_hgrid.nc 2>&1 | tee ./mom6_obc_from_rtofs.log
export err=$?; err_chk

# Deliver to intercom
${NCP} -p ocean_*obc_*.nc ${WORKhafs}/intercom/ocn_prep/mom6/

#==============================================================================

# Prepare atmospheric forcings from GFS forcing
mkdir -p ${DATA}/mom6_forcings
cd ${DATA}/mom6_forcings

PARMave=":USWRF:surface|:DSWRF:surface|:ULWRF:surface|:DLWRF:surface|:UFLX:surface|:VFLX:surface|:SHTFL:surface|:LHTFL:surface"
PARMins=":UGRD:10 m above ground|:VGRD:10 m above ground|:PRES:surface|:PRATE:surface|:TMP:surface"
PARMlist="${PARMave}|${PARMins}"

# Use gfs forcing from prior cycle's 6-h forecast
grib2_file=${COMINgfs}/gfs.${ymd_prior}/${cyc_prior}/atmos/gfs.t${cyc_prior}z.pgrb2.0p25.f006
if [ ! -s ${grib2_file} ]; then
  echo "FATAL ERROR: ${grib2_file} does not exist. Exiting"
  exit 1
fi
# Extract atmospheric forcing related variables
${WGRIB2} ${grib2_file} -match "${PARMlist}" -netcdf gfs_global_${ymd_prior}${cyc_prior}_f006.nc

FHRB=${FHRB:-0}
FHRE=${FHRE:-$((${NHRS}+3))}
FHRI=${FHRI:-3}
FHR=${FHRB}
FHR3=$( printf "%03d" "$FHR" )

# Loop for forecast hours
while [ $FHR -le ${FHRE} ]; do

# Use gfs 0.25 degree grib2 files
grib2_file=${COMINgfs}/gfs.${ymd}/${cyc}/atmos/gfs.t${cyc}z.pgrb2.0p25.f${FHR3}

# Check and wait for input data
MAX_WAIT_TIME=${MAX_WAIT_TIME:-900}
n=0
while [ $n -le ${MAX_WAIT_TIME} ]; do
  if [ -s ${grib2_file} ]; then
	while [ $(( $(date +%s) - $(stat -c %Y ${grib2_file}) )) -lt 10  ]; do sleep 10; done
    echo "${grib2_file} ready, continue ..."
    break
  else
    echo "${grib2_file} not ready, sleep 10"
    sleep 10s
  fi
  n=$((n+10))
  if [ $n -gt ${MAX_WAIT_TIME} ]; then
    echo "FATAL ERROR: Waited ${grib2_file} too long $n > ${MAX_WAIT_TIME} seconds. Exiting"
    exit 1
  fi
done

${WGRIB2} ${grib2_file} -match "${PARMlist}" -netcdf gfs_global_${ymd}${cyc}_f${FHR3}.nc

FHR=$(($FHR + ${FHRI}))
FHR3=$(printf "%03d" "$FHR")

done
# End loop for forecast hours

${USHhafs}/hafs_mom6_gfs_forcings.py ${CDATE} -l ${NHRS} 2>&1 | tee ./mom6_gfs_forcings.log
export err=$?; err_chk

# Obtain net longwave and shortwave radiation file
echo 'Obtaining NETLW'
ncks -A gfs_global_${CDATE}_ULWRF.nc -o gfs_global_${CDATE}_LWRF.nc
ncks -A gfs_global_${CDATE}_DLWRF.nc -o gfs_global_${CDATE}_LWRF.nc
ncap2 -v -O -s "NETLW_surface=DLWRF_surface-ULWRF_surface" gfs_global_${CDATE}_LWRF.nc gfs_global_${CDATE}_NETLW.nc
ncatted -O -a long_name,NETLW_surface,o,c,"Net Long-Wave Radiation Flux" gfs_global_${CDATE}_NETLW.nc
ncatted -O -a short_name,NETLW_surface,o,c,"NETLW_surface" gfs_global_${CDATE}_NETLW.nc

echo 'Obtaining NETSW'
ncks -A gfs_global_${CDATE}_USWRF.nc -o gfs_global_${CDATE}_SWRF.nc
ncks -A gfs_global_${CDATE}_DSWRF.nc -o gfs_global_${CDATE}_SWRF.nc
ncap2 -v -O -s "NETSW_surface=DSWRF_surface-USWRF_surface" gfs_global_${CDATE}_SWRF.nc gfs_global_${CDATE}_NETSW.nc
ncatted -O -a long_name,NETSW_surface,o,c,"Net Short-Wave Radiation Flux" gfs_global_${CDATE}_NETSW.nc
ncatted -O -a short_name,NETSW_surface,o,c,"NETSW_surface" gfs_global_${CDATE}_NETSW.nc

# Add four components to the NETSW and DSWRF radiation files
# SWVDF=Visible Diffuse Downward Solar Flux. SWVDF=0.285*DSWRF_surface
# SWVDR=Visible Beam Downward Solar Flux. SWVDR=0.285*DSWRF_surface
# SWNDF=Near IR Diffuse Downward Solar Flux. SWNDF=0.215*DSWRF_surface
# SWNDR=Near IR Beam Downward Solar Flux. SWNDR=0.215*DSWRF_surface
echo 'Adding four components to the NETSW radiation file'
echo 'Adding SWVDF'
ncap2 -v -O -s "SWVDF_surface=float(0.285*DSWRF_surface)" gfs_global_${CDATE}_DSWRF.nc gfs_global_${CDATE}_SWVDF.nc
ncatted -O -a long_name,SWVDF_surface,o,c,"Visible Diffuse Downward Solar Flux" gfs_global_${CDATE}_SWVDF.nc
ncatted -O -a short_name,SWVDF_surface,o,c,"SWVDF_surface" gfs_global_${CDATE}_SWVDF.nc

echo 'Adding SWVDR'
ncap2 -v -O -s "SWVDR_surface=float(0.285*DSWRF_surface)" gfs_global_${CDATE}_DSWRF.nc gfs_global_${CDATE}_SWVDR.nc
ncatted -O -a long_name,SWVDR_surface,o,c,"Visible Beam Downward Solar Flux" gfs_global_${CDATE}_SWVDR.nc
ncatted -O -a short_name,SWVDR_surface,o,c,"SWVDR_surface" gfs_global_${CDATE}_SWVDR.nc

echo 'Adding SWNDF'
ncap2 -v -O -s "SWNDF_surface=float(0.215*DSWRF_surface)" gfs_global_${CDATE}_DSWRF.nc gfs_global_${CDATE}_SWNDF.nc
ncatted -O -a long_name,SWNDF_surface,o,c,"Near IR Diffuse Downward Solar Flux" gfs_global_${CDATE}_SWNDF.nc
ncatted -O -a short_name,SWNDF_surface,o,c,"SWNDF_surface" gfs_global_${CDATE}_SWNDF.nc

echo 'Adding SWNDR'
ncap2 -v -O -s "SWNDR_surface=float(0.215*DSWRF_surface)" gfs_global_${CDATE}_DSWRF.nc gfs_global_${CDATE}_SWNDR.nc
ncatted -O -a long_name,SWNDR_surface,o,c,"Near IR Beam Downward Solar Flux" gfs_global_${CDATE}_SWNDR.nc
ncatted -O -a short_name,SWNDR_surface,o,c,"SWVDR_surface" gfs_global_${CDATE}_SWNDR.nc

echo 'Changing sign to SHTFL, LHTFL, UFLX, VFLX'
ncap2 -v -O -s "SHTFL_surface=float(SHTFL_surface*-1.0)" gfs_global_${CDATE}_SHTFL.nc gfs_global_${CDATE}_SHTFL.nc
ncap2 -v -O -s "LHTFL_surface=float(LHTFL_surface*-1.0)" gfs_global_${CDATE}_LHTFL.nc gfs_global_${CDATE}_LHTFL.nc
ncap2 -v -O -s "UFLX_surface=float(UFLX_surface*-1.0)" gfs_global_${CDATE}_UFLX.nc gfs_global_${CDATE}_UFLX.nc
ncap2 -v -O -s "VFLX_surface=float(VFLX_surface*-1.0)" gfs_global_${CDATE}_VFLX.nc gfs_global_${CDATE}_VFLX.nc

echo 'Adding EVAP'
ncap2 -v -O -s "EVAP_surface=float(LHTFL_surface/(2.5*10^6))" gfs_global_${CDATE}_LHTFL.nc gfs_global_${CDATE}_EVAP.nc
ncatted -O -a long_name,EVAP_surface,o,c,"Evaporation Rate" gfs_global_${CDATE}_EVAP.nc
ncatted -O -a short_name,EVAP_surface,o,c,"EVAP_surface" gfs_global_${CDATE}_EVAP.nc
ncatted -O -a units,EVAP_surface,o,c,"Kg m-2 s-1" gfs_global_${CDATE}_EVAP.nc

# Concatenate all files
fileall="gfs_global_${CDATE}_NETLW.nc \
         gfs_global_${CDATE}_DSWRF.nc \
         gfs_global_${CDATE}_NETSW.nc \
         gfs_global_${CDATE}_SWVDF.nc \
         gfs_global_${CDATE}_SWVDR.nc \
         gfs_global_${CDATE}_SWNDF.nc \
         gfs_global_${CDATE}_SWNDR.nc \
         gfs_global_${CDATE}_LHTFL.nc \
         gfs_global_${CDATE}_EVAP.nc  \
         gfs_global_${CDATE}_SHTFL.nc \
         gfs_global_${CDATE}_UFLX.nc  \
         gfs_global_${CDATE}_VFLX.nc  \
         gfs_global_${CDATE}_UGRD.nc  \
         gfs_global_${CDATE}_VGRD.nc  \
         gfs_global_${CDATE}_PRES.nc  \
         gfs_global_${CDATE}_PRATE.nc \
         gfs_global_${CDATE}_TMP.nc"
# Use cdo merge, which is faster
cdo merge ${fileall} gfs_forcings.nc
# Alternatively, can use ncks, but slower
#for file in ${fileall}; do ncks -h -A ${file} gfs_forcings.nc; done

# Deliver to intercom
${NCP} -p gfs_forcings.nc ${WORKhafs}/intercom/ocn_prep/mom6/

#==============================================================================

# Set ecflow event if needed
if [ -n "${ECF_NAME}" ]; then
  ecflow_client --event Ocean
fi      

