;======================================================================
;   - Interpolating from one grid to another using ESMF software
;======================================================================
; This example uses the ESMF application "ESMF_RegridWeightGen" to
; generate the weights.
;
; For more information about ESMF:
;
;        http://www.earthsystemmodeling.org/
;
; This script uses built-in functions that are only available in
; NCL V6.1.0 and later.
;======================================================================
; This script regrids t and s from rtofs regional grid to ar2 regular grid
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
;     Generate the weights from the rtofs grid to  ar2 regular grid
;----------------------------------------------------------------------
;      srcGridName="rtofs_SCRIP.nc"
;      dstGridName="../AR2_regular_SCRIP.nc"
       wgtFile="map_rtofs_to_ar2_regular.nc"

;      Opt                = True
;      Opt@InterpMethod   = "neareststod"
;      Opt@SrcRegional    = False
;      Opt@DstRegional    = True
;      ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFile,Opt)

;      delete(Opt)
;----------------------------------------------------------------------
;     Regridding fields
;----------------------------------------------------------------------
    Opt = True
; rtofs file
    fname="tmp_ocean_ts_ic.nc"
    ff   = addfile(fname,"r")
; ar2 regular grid
    ff2  = addfile("lon_lat_ar2_regular_grid.nc","r")
    lonh = ff2->lonh
    lath = ff2->lath
    var12 = new((/55,875,1625/),"float")
    var13 = new((/55,875,1625/),"float")
    do k = 0,54
    var = ff->Temp(0,k,:,:)
    temp_regrid = ESMF_regrid_with_weights(var,wgtFile,Opt)
    var12(k,:,:)=temp_regrid
    end do
    delete(temp_regrid)

    do k = 0,54
    var = ff->Salt(0,k,:,:)
    temp_regrid = ESMF_regrid_with_weights(var,wgtFile,Opt)
    var13(k,:,:)=temp_regrid
    end do

    depth = ff->depth

;----------------------------------------------------------------------
;     Write the regridded data to a NetCDF file
;----------------------------------------------------------------------
; output file
      rgrdFileName ="ocean_ts_ic.nc"
      system("rm -f " + rgrdFileName)
      fout = addfile(rgrdFileName,"c")

      setfileoption(fout,"DefineMode",True)
      dimNames = (/"depth","latitude","longitude"/)
      dimSizes = (/55,875,1625/)
      dimUnlim = (/False,False,False/)
      filedimdef(fout,dimNames,dimSizes,dimUnlim)
      filevardef(fout,"depth",typeof(depth),(/"depth"/))
      filevardef(fout,"Temp",typeof(var12),(/"depth","latitude","longitude"/))
      filevardef(fout,"Salt",typeof(var13),(/"depth","latitude","longitude"/))
      filevardef(fout,"longitude",typeof(lonh),(/"longitude"/))
      filevardef(fout,"latitude", typeof(lath),(/"latitude"/))
      setfileoption(fout,"DefineMode",False)
      fout->longitude   = (/lonh/)
      fout->latitude   = (/lath/)
      fout->depth      = (/depth/)
      fout->Temp       = (/var12/)
      fout->Salt       = (/var13/)
end
