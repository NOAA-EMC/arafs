;======================================================================
;   - Interpolating from one grid to another using ESMF software
;======================================================================
; For more information about ESMF:
;
;        http://www.earthsystemmodeling.org/
;
; This script uses built-in functions that are only available in
; NCL V6.1.0 and later.
;======================================================================
; This script regrids ssh from rtofs regional grid to ar2 regular grid
;======================================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
;----------------------------------------------------------------------
    wgtFile="map_rtofs_to_ar2_regular.nc"
;----------------------------------------------------------------------
    Opt = True
; rtofs file
    fname="tmp_ocean_ssh_ic.nc"
    ff   = addfile(fname,"r")
; ar2 regular grid
    ff2  = addfile("lon_lat_ar2_regular_grid.nc","r")
    lonh = ff2->lonh
    lath = ff2->lath
    var12 = new((/875,1625/),"double")
    var = ff->ave_ssh(0,:,:)
    var12 = ESMF_regrid_with_weights(var,wgtFile,Opt)

;----------------------------------------------------------------------
;     Write the regridded data to a NetCDF file
;----------------------------------------------------------------------
; output file
      rgrdFileName ="ocean_ssh_ic.nc"
      system("rm -f " + rgrdFileName)
      fout = addfile(rgrdFileName,"c")

      setfileoption(fout,"DefineMode",True)
      dimNames = (/"latitude","longitude"/)
      dimSizes = (/875,1625/)
      dimUnlim = (/False,False/)
      filedimdef(fout,dimNames,dimSizes,dimUnlim)
      filevardef(fout,"ave_ssh",typeof(var12),(/"latitude","longitude"/))
      filevardef(fout,"longitude",typeof(lonh),(/"longitude"/))
      filevardef(fout,"latitude", typeof(lath),(/"latitude"/))
      setfileoption(fout,"DefineMode",False)
      fout->longitude   = (/lonh/)
      fout->latitude   = (/lath/)
      fout->ave_ssh    = (/var12/)
end
