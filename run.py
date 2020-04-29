from cftime import DatetimeNoLeap
from datetime import timedelta
from numpy import datetime64, empty, full, repeat, stack
from os import chdir, system
from scipy.interpolate import griddata
from warnings import simplefilter
from xarray import DataArray, open_dataset
simplefilter("ignore")

nc_path = '/home/zhangc/scenariomip_cmip6/nc_data/'
im_path = '/home/zhangc/scenariomip_cmip6/im_data/'
os_path = '/home/zhangc/repositories/nc2im_cesm2/'

nc_con = ['fracdata_0.9x1.25_gx1v6_c090317.nc',
          'USGS-gtopo30_0.9x1.25_remap_c051027.nc']

nc_lev = ['ta_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',
          'hus_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',
          'ua_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',
          'va_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc']

nc_6hr = ['ps_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc']

nc_day = ['tos_Oday_CESM2_ssp245_r2i1p1f1_gn_20150102-20650101.nc',
          'siconc_SIday_CESM2_ssp245_r2i1p1f1_gn_20150102-20650101.nc']

nc_mon = ['ts_Amon_CESM2_ssp245_r2i1p1f1_gn_201501-206412.nc']

nc_era = ['soil_mon_ERA5_2015.nc']

start_year = 2015
start_month = 1
start_day = 1

end_year = 2016
end_month = 1
end_day = 1

start_date = DatetimeNoLeap(start_year, start_month, start_day)
end_date = DatetimeNoLeap(end_year, end_month, end_day)

date_list = []
date = start_date
while date <  end_date:
    date_list.append(date)
    date += timedelta(hours=6)

for date in date_list:
    chdir(nc_path)
    # time
    tnum = date.year, date.month, date.day, date.hour
    t6hr = DatetimeNoLeap(tnum[0], tnum[1], tnum[2], tnum[3])
    tday =  DatetimeNoLeap(tnum[0], tnum[1], tnum[2]) + timedelta(days=1)
    tmon = DatetimeNoLeap(tnum[0], tnum[1], 15, 12)
    tera = datetime64('2015-'+str(tnum[1]).zfill(2)+'-01')
    file_time = str(t6hr).replace(' ', '_')
    # land-sea mask
    ds = open_dataset(nc_con[0])
    da = ds.LANDMASK*1.0
    file_name = 'ls_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # soil height
    ds = open_dataset(nc_con[1])
    da = ds.PHIS/9.81
    file_name = 'sh_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # lev
    das = []
    for nc in nc_lev:
        ds = open_dataset(nc).sel(time=t6hr).sortby('lev')
        vi = ds.variable_id
        da = ds[vi]
        das.append(da)
        file_name = vi + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # 6 hourly
    ds = open_dataset(nc_6hr[0]).sel(time=t6hr)
    da = ds['ps']
    file_name = 'ps_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # virtual temperature
    t = das[0].sortby('lev').values
    q = das[1].sortby('lev').values
    tv = t*(1.+q*0.61)
    lev = -das[0].sortby('lev').lev.values
    lat = das[0].lat.values
    lon = das[0].lon.values
    da = DataArray(name='tv', data=tv, coords=[lev, lat, lon], dims=['lev', 'lat', 'lon']).transpose('lat', 'lon', 'lev')
    file_name = 'tv_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # pressure
    shape = das[0].shape
    p3 = empty(shape)
    for i in range(len(lev)):
        p3[i] = full(shape[1:3], lev[i])
    da = DataArray(name='p3', data=p3, coords=[lev, lat, lon], dims=['lev', 'lat', 'lon']).transpose('lat', 'lon', 'lev')
    file_name = 'p3_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # surface variables
    vis = ['t2', 'q2', 'u2', 'v2']
    for i in range(4):
        da = das[i].isel(lev=-1)
        file_name = vis[i] + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    for nc in nc_mon:
        ds = open_dataset(nc).sel(time=tmon)
        vi = ds.variable_id
        da = ds[vi]
        file_name = vi + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    da = das[0].isel(lev=-1)
    lev = da.lev.values*-100
    lon = da.lon.values
    lat = da.lat.values
    values = full(da.shape, lev)
    da = DataArray(name='p2', data=values, coords=[lat, lon], dims=['lat', 'lon'])
    file_name = 'p2_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # sea surface temperature
    ds = open_dataset(nc_day[0])
    da = ds.tos.sel(time=tday)
    x = da.lon.values.flatten()
    y = da.lat.values.flatten()
    xy = stack((x, y), axis=-1)
    v = da.values.flatten()
    ds = open_dataset(nc_lev[0])
    lon1d = ds.lon.values
    lat1d = ds.lat.values
    nx = len(lon1d)
    ny = len(lat1d)
    lon2d = repeat(lon1d, ny).reshape(nx, ny).transpose()
    lat2d = repeat(lat1d, nx).reshape(ny, nx)
    vi = griddata(xy, v, (lon2d, lat2d), method='linear')
    da = DataArray(data=vi, coords=[lat1d, lon1d], dims=['lat', 'lon'])
    file_name = 'sst_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # sea ice concentration**
    ds = open_dataset(nc_day[1])
    da = ds.siconc.sel(time=tday)
    v = da.values.flatten()
    vi = griddata(xy, v, (lon2d, lat2d), method='linear')
    da = DataArray(data=vi, coords=[lat1d, lon1d], dims=['lat', 'lon'])
    file_name = 'sic_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # soil moisture**
    ds = open_dataset(nc_era[0]).sel(time=tera)
    vis = ['swvl1', 'swvl2', 'swvl3', 'swvl4']
    for vi in vis:
        da = ds[vi].interp(longitude=lon1d, latitude=lat1d)
        file_name = vi + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    vis = ['stl1', 'stl2', 'stl3', 'stl4']
    for vi in vis:
        da = ds[vi].interp(longitude=lon1d, latitude=lat1d)
        file_name = vi + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # run NCL
    chdir(os_path)
    command = 'ncl convert_nc_to_im.ncl ' + "'file_time=" + '"' + file_time + '"' + "'"
    system(command)
    # flag
    print('The '+str(date)+' IM File Has Been Processed!')
