#! /usr/bin/env python3

# Usage: ./stagger_uv_from_ts_points.py uvfile_hycom uvfile_hycom_stagger

#uvfile = '/work/noaa/hwrf/save/maristiz/scripts_to_prep_MOM6/RTOFS_IC_ncl/2025062400_AR_domain/ocean_uv_rotated_no_stagger_ar2_regular_grid.nc'
#uvfile_stagger = '/work/noaa/hwrf/save/maristiz/scripts_to_prep_MOM6/RTOFS_IC_ncl/2025062400_AR_domain/ocean_uv_stagger_ar2_regular_grid.nc'

import argparse
import numpy as np
import netCDF4 as nc

if __name__ == "__main__":
    # get command line args
    parser = argparse.ArgumentParser(
        description="Stagger u and v velocities to a staggered MOM6 grid")
    parser.add_argument('grid_file_mom6', type=str, help="Name of the MOM6 grid file that contains lonq and latq information")
    parser.add_argument('uvfile_hycom', type=str, help="Name of the HYCOM file that contents the u and v velocities on the original HYCOM grid")
    parser.add_argument('uvfile_hycom_stagger', type=str, help="Name of the output file that will contained the staggered u and v velocities")

    args = parser.parse_args()

    grid_file_mom6 = args.grid_file_mom6
    uvfile_hycom = args.uvfile_hycom
    uvfile_hycom = args.uvfile_hycom
    uvfile_hycom_stagger = args.uvfile_hycom_stagger

    print(args)

    # Read velocity file on ts grid
    uvnc = nc.Dataset(uvfile_hycom,'r')
    u = np.asarray(uvnc['u'])
    v = np.asarray(uvnc['v'])
    lath = np.asarray(uvnc['latitude'])
    lonh = np.asarray(uvnc['longitude'])
    depth = np.asarray(uvnc['depth'])
    #fillvalue = uvnc['u'].get_fill_value()
    fillvalue = 0.0

    # Make fill values nan 
    u[u>1000] = np.nan
    v[v>1000] = np.nan


    # Read lonq and latq from MOM6 topography file
    gridnc = nc.Dataset(grid_file_mom6,'r')
    latq = np.asarray(gridnc['latq'])
    lonq = np.asarray(gridnc['lonq'])
    
    # Define u_stagger
    u_stagger = np.empty((u.shape[1],u.shape[2],u.shape[3]+1))
    u_stagger[:] = np.nan
    # Avering u on ts points to u points
    u_stagger[:,:,1:-1] = (u[0,:,:,:-1] + u[0,:,:,1:])/2
    # Filling the first cross section of u
    u_stagger[:,:,0] = u_stagger[:,:,1]
    # Filling the last cross section of u
    u_stagger[:,:,-1] = u_stagger[:,:,-2]
    # Fill nans with fillvalue
    u_stagger[np.isnan(u_stagger)] = fillvalue
    
    # Define v_stagger
    v_stagger = np.empty((v.shape[1],v.shape[2]+1,u.shape[3]))
    v_stagger[:] = np.nan
    # Avering u on ts points to u points
    v_stagger[:,1:-1,:] = (v[0,:,:-1,:] + v[0,:,1:,:])/2
    # Filling the first cross section of u
    v_stagger[:,0,:] = v_stagger[:,1,:]
    # Filling the last cross section of u
    v_stagger[:,-1,:] = v_stagger[:,-2,:]
    # Fill nans with fillvalue
    v_stagger[np.isnan(v_stagger)] = fillvalue
    
    # Save rotated velocities into netcdf file
    nc_file= nc.Dataset(uvfile_hycom_stagger, 'w', format='NETCDF4')
    
    # Add a global attribute
    nc_file.description = 'NetCDF file with the interpolated u and v field from RTOFS onto a MOM6 grid on staggered points'
    
    # Define dimensions
    #time_dim = nc_file.createDimension('time', None)  # Unlimited dimension
    depth_dim = nc_file.createDimension('depth',depth.shape[0])
    lath_dim = nc_file.createDimension('lath',lath.shape[0])
    lonh_dim = nc_file.createDimension('lonh',lonh.shape[0] )
    latq_dim = nc_file.createDimension('latq',latq.shape[0])
    lonq_dim = nc_file.createDimension('lonq',lonq.shape[0] )
    
    # Create variables
    #time_var = nc_file.createVariable('time', 'f8', ('time',))
    depth_var = nc_file.createVariable('depth', 'f4', ('depth',))
    lath_var = nc_file.createVariable('lath', 'f4', ('lath',))
    lonh_var = nc_file.createVariable('lonh', 'f4', ('lonh',))
    latq_var = nc_file.createVariable('latq', 'f4', ('latq',))
    lonq_var = nc_file.createVariable('lonq', 'f4', ('lonq',))
    u_var = nc_file.createVariable('u', 'f4', ('depth','lath','lonq',),fill_value=fillvalue)
    v_var = nc_file.createVariable('v', 'f4', ('depth','latq','lonh',),fill_value=fillvalue)
    
    # Add attributes to variables
    '''
    time_var.long_name = 'time'
    time_var.units = src_nc[timename].units
    
    date_var.long_name = 'date'
    date_var.units = 'day as %Y%m%d.%f'
    
    lat_var.long_name = 'latitude'
    lat_var.units = 'degrees_north'
    
    lon_var.long_name = 'longitude'
    lon_var.units = 'degrees_east'
    
    temp_var.long_name = 'sea_water_potential_temperature'
    temp_var.units = 'Celsius'
    
    '''
    
    # Write data to variables
    #time_var[:] = np.asarray(src_nc[timename])
    depth_var[:] = depth
    lath_var[:] = lath
    lonh_var[:] = lonh
    latq_var[:] = latq
    lonq_var[:] = lonq
    u_var[:] = u_stagger
    v_var[:] = v_stagger
    
    nc_file.close()
    
