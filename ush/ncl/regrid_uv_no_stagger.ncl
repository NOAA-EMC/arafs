;======================================================================
;
; For more information about ESMF:
;
;        http://www.earthsystemmodeling.org/
;
; This script uses built-in functions that are only available in 
; NCL V6.1.0 and later.
;======================================================================
; This script regrids u and v from rtofs regional grid to ar2 regular grid 
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
      wgtFile="map_rtofs_to_ar2_regular.nc"

;----------------------------------------------------------------------
;     Regridding fields
;----------------------------------------------------------------------
    Opt = True
; rtofs file
    fname="rtofs_ocean_uv_ic.nc"
    ff   = addfile(fname,"r")
; ar2 regular grid
    ff2  = addfile("lon_lat_ar2_regular_grid.nc","r")
    lonh = ff2->lonh
    lath = ff2->lath
    var12 = new((/1,55,875,1625/),"float")
    var13 = new((/1,55,875,1625/),"float")
    do k = 0,54
    var = ff->u(0,k,:,:)
    u_regrid = ESMF_regrid_with_weights(var,wgtFile,Opt)
    var12(0,k,:,:)=u_regrid
    end do
    delete(u_regrid)

    do k = 0,54
    var = ff->v(0,k,:,:)
    v_regrid = ESMF_regrid_with_weights(var,wgtFile,Opt)
    var13(0,k,:,:)=v_regrid
    end do

;    printVarSummary(u_regrid)
    time = ff->MT
    time_units = time@units
    depth = ff->Depth

;----------------------------------------------------------------------
;     Write the regridded data to a NetCDF file
;----------------------------------------------------------------------
; output file
      rgrdFileName ="ocean_uv_no_stagger.nc"
      system("rm -f " + rgrdFileName)
      fout = addfile(rgrdFileName,"c")

      setfileoption(fout,"DefineMode",True)
      dimNames = (/"time","depth","latitude","longitude"/)
      dimSizes = (/1,55,875,1625/)
      dimUnlim = (/True,False,False,False/)
      filedimdef(fout,dimNames,dimSizes,dimUnlim)
      filevardef(fout,"time",typeof(time),(/"time"/))
      filevardef(fout,"depth",typeof(depth),(/"depth"/))
      filevardef(fout,"u",typeof(var12),(/"time","depth","latitude","longitude"/))
      filevardef(fout,"v",typeof(var13),(/"time","depth","latitude","longitude"/))
      filevardef(fout,"longitude",typeof(lonh),(/"longitude"/))
      filevardef(fout,"latitude", typeof(lath),(/"latitude"/))
      setfileoption(fout,"DefineMode",False)
      fout->time      = (/time/)
      fout->time@units = time_units
      fout->time@calendar = "gregorian"
      fout->depth     = (/depth/)
      fout->longitude = (/lonh/)
      fout->latitude  = (/lath/)
      fout->u         = (/var12/)
      fout->v         = (/var13/)
end
