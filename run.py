from cftime import DatetimeNoLeap
from datetime import timedelta
from numpy import datetime64, empty, float64, full, repeat, stack
from os import chdir, system
from scipy.interpolate import griddata
from warnings import simplefilter
from xarray import DataArray, open_dataset
simplefilter("ignore")

start_year = 2015
start_month = 1
start_day = 1

end_year = 2015
end_month = 1
end_day = 8

nc_path = '/home/zhangc/scenariomip_cmip6/nc_data/'
im_path = '/home/zhangc/scenariomip_cmip6/im_data/'
os_path = '/home/zhangc/repositories/nc2im_cesm2/'

ncs = ['ta_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',     #  0
       'hus_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',    #  1
       'ua_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',     #  2
       'va_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',     #  3
       'ps_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',     #  4
       'tos_Oday_CESM2_ssp245_r2i1p1f1_gn_20150102-20650101.nc',              #  5
       'siconc_SIday_CESM2_ssp245_r2i1p1f1_gn_20150102-20650101.nc',          #  6
       'ts_Amon_CESM2_ssp245_r2i1p1f1_gn_201501-206412.nc',                   #  7
       'soil_mon_ERA5_2015.nc',                                               #  8
       'fracdata_0.9x1.25_gx1v6_c090317.nc',                                  #  9
       'USGS-gtopo30_0.9x1.25_remap_c051027.nc']                              # 10

chdir(nc_path)
dss = []
for nc in ncs:
    ds = open_dataset(nc)
    dss.append(ds)

start_date = DatetimeNoLeap(start_year, start_month, start_day)
end_date = DatetimeNoLeap(end_year, end_month, end_day)

dates = []
date = start_date
while date <= end_date:
    dates.append(date)
    date += timedelta(hours=6)

for date in dates:
    # time
    tnum = date.year, date.month, date.day, date.hour
    t6hr = DatetimeNoLeap(tnum[0], tnum[1], tnum[2], tnum[3])
    tday =  DatetimeNoLeap(tnum[0], tnum[1], tnum[2]) + timedelta(days=1)
    if tnum[1] is 2:
        mid_day = 14
    else:
        mid_day = 15
    if tnum[1] in [1, 3, 5, 7, 8, 10, 12]:
        mid_hour = 12
    else:
        mid_hour = 0
    tmon = DatetimeNoLeap(tnum[0], tnum[1], mid_day, mid_hour)
    tera = datetime64('2015-'+str(tnum[1]).zfill(2)+'-01')
    file_time = str(t6hr).replace(' ', '_')
    # land-sea mask
    v = dss[9].LANDMASK.values*1.0
    da = DataArray(name='ls', data=float64(v))
    file_name = 'ls_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # soil height
    v = dss[10].PHIS.values/9.81
    da = DataArray(name='sh', data=float64(v))
    file_name = 'sh_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # lev
    das = []
    for i in [0, 1, 2, 3]:
        ds = dss[i].sel(time=t6hr).sortby('lev')
        vi = ds.variable_id
        das.append(ds[vi])
        v = ds[vi]
        v.attrs = {}
        v.values = float64(v.values)
        da = DataArray(name=vi, data=v)
        file_name = vi + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # 6 hourly
    ds = dss[4].sel(time=t6hr)
    v = ds['ps'].values
    da = DataArray(name='ps', data=float64(v))
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
    v = da.values
    da = DataArray(name='tv', data=float64(v))
    file_name = 'tv_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # pressure
    shape = das[0].shape
    p3 = empty(shape)
    for i in range(len(lev)):
        p3[i] = full(shape[1:3], lev[i])
    da = DataArray(name='p3', data=p3, coords=[lev, lat, lon], dims=['lev', 'lat', 'lon']).transpose('lat', 'lon', 'lev')
    v = da.values
    da = DataArray(name='p3', data=float64(v))
    file_name = 'p3_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # surface variables
    vis = ['t2', 'q2', 'u2', 'v2']
    for i in range(4):
        v = das[i].isel(lev=-1).values
        da = DataArray(name=vis[i], data=float64(v))
        file_name = vis[i] + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # skin temperature
    ds = dss[7].sel(time=tmon)
    vi = ds.variable_id
    v = ds[vi].values
    da = DataArray(name=vi, data=float64(v))
    file_name = vi + '_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # sea level pressure
    da = das[0].isel(lev=-1)
    lev = da.lev.values*-100
    v = full(da.shape, lev)
    da = DataArray(name='p2', data=float64(v))
    file_name = 'p2_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # sea surface temperature
    da = dss[5].tos.sel(time=tday)
    x = da.lon.values.flatten()
    y = da.lat.values.flatten()
    xy = stack((x, y), axis=-1)
    v = da.values.flatten()
    ds = dss[0]
    lon1d = ds.lon.values
    lat1d = ds.lat.values
    nx = len(lon1d)
    ny = len(lat1d)
    lon2d = repeat(lon1d, ny).reshape(nx, ny).transpose()
    lat2d = repeat(lat1d, nx).reshape(ny, nx)
    vi = griddata(xy, v, (lon2d, lat2d), method='linear')
    da = DataArray(name='sst', data=float64(vi))
    file_name = 'sst_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # sea ice concentration
    da = dss[6].siconc.sel(time=tday)
    v = da.values.flatten()
    vi = griddata(xy, v, (lon2d, lat2d), method='linear')
    da = DataArray(name='sic', data=float64(vi))
    file_name = 'sic_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # soil moisture
    ds = dss[8].sel(time=tera)
    vis = ['swvl1', 'swvl2', 'swvl3', 'swvl4']
    for vi in vis:
        da = ds[vi].interp(longitude=lon1d, latitude=lat1d)
        v = da.values
        da = DataArray(name=vi, data=float64(v))
        file_name = vi + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # soil temperature
    vis = ['stl1', 'stl2', 'stl3', 'stl4']
    for vi in vis:
        da = ds[vi].interp(longitude=lon1d, latitude=lat1d)
        v = da.values
        da = DataArray(name=vi, data=float64(v))
        file_name = vi + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # run NCL
    chdir(os_path)
    command = 'ncl convert_nc_to_im.ncl ' + "'file_time=" + '"' + file_time + '"' + "'"
    system(command)
    # flag
    print('The '+str(date)+' IM File Has Been Processed!')
