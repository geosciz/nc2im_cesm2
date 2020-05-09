from cftime import DatetimeNoLeap
from datetime import timedelta
from numpy import datetime64, empty, float32, full, repeat, stack
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
end_day = 2

nc_path = '/home/zhangc/cesm2_cmip6/nc_data/'
im_path = '/home/zhangc/cesm2_cmip6/im_data/'
os_path = '/home/zhangc/repositories/nc2im_cesm2/'

ncs = ['ta_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',     # 0
       'hus_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',    # 1
       'ua_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',     # 2
       'va_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',     # 3
       'tos_Oday_CESM2_ssp245_r2i1p1f1_gn_20150102-20650101.nc',              # 4
       'siconc_SIday_CESM2_ssp245_r2i1p1f1_gn_20150102-20650101.nc',          # 5
       'ts_Amon_CESM2_ssp245_r2i1p1f1_gn_201501-206412.nc',                   # 6
       'soil_mon_ERA5_2015.nc',                                               # 7
       'fracdata_0.9x1.25_gx1v6_c090317.nc',                                  # 8
       'USGS-gtopo30_0.9x1.25_remap_c051027.nc']                              # 9

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
    # Time
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
    # Land-Sea Mask
    v = dss[8].LANDMASK.values
    da = DataArray(name='ls', data=float32(v))
    file_name = 'ls_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # Surface Geopotential
    v = dss[9].PHIS.values
    da = DataArray(name='phis', data=float32(v))
    file_name = 'phis_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # Soil Height
    v = dss[10].PHIS.values/9.80655
    da = DataArray(name='sh', data=float32(v))
    file_name = 'sh_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # Basic Info
    ds = dss[0].sel(time=t6hr).sortby('lev')
    v = ds.time.values
    da = DataArray(name='time', data=v)
    file_name = 'time_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    ss = ['lev', 'lon', 'lat', 'p0', 'ps', 'a', 'b']
    for s in ss:
        v = ds[s].values
        da = DataArray(name=s, data=float32(v))
        file_name = s + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    ss = ['a_bnds', 'b_bnds']
    for s in ss:
        v = ds[s].values[:,1]
        da = DataArray(name=s, data=float32(v))
        file_name = s + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # 3D Temperature
    v = ds.ta.values
    da = DataArray(name='ta', data=float32(v))
    file_name = 'ta_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # 3D Humidity, Winds
    for i in range(1,4):
        ds = dss[i].sel(time=t6hr).sortby('lev')
        vi = ds.variable_id
        v = ds[vi].values
        da = DataArray(name=vi, data=float32(v))
        file_name = vi + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # 3D Virtual Temperature
    t = dss[0].ta.sel(time=t6hr).sortby('lev').values
    q = dss[1].hus.sel(time=t6hr).sortby('lev').values
    tv = t*(1.+q*0.61)
    da = DataArray(name='tv', data=float32(tv))
    file_name = 'tv_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # Skin Temperature
    v = dss[7].ts.sel(time=tmon).values
    da = DataArray(name='ts', data=float32(v))
    file_name = 'ts_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # Sea Surface Temperature
    ds = dss[4].tos.sel(time=tday)
    x = ds.lon.values.flatten()
    y = ds.lat.values.flatten()
    xy = stack((x, y), axis=-1)
    v = ds.values.flatten()
    lon1d = dss[0].lon.values
    lat1d = dss[0].lat.values
    nx = len(lon1d)
    ny = len(lat1d)
    lon2d = repeat(lon1d, ny).reshape(nx, ny).transpose()
    lat2d = repeat(lat1d, nx).reshape(ny, nx)
    vi = griddata(xy, v, (lon2d, lat2d), method='linear')
    da = DataArray(name='sst', data=float32(vi))
    file_name = 'sst_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # Sea Ice Concentration
    da = dss[5].siconc.sel(time=tday)
    v = da.values.flatten()
    vi = griddata(xy, v, (lon2d, lat2d), method='linear')
    da = DataArray(name='sic', data=float32(vi))
    file_name = 'sic_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)
    # Soil Moisture, Temperature
    ds = dss[7].sel(time=tera)
    ss = ['swvl1', 'swvl2', 'swvl3', 'swvl4', 'stl1', 'stl2', 'stl3', 'stl4']
    for s in ss:
        v = ds[s].interp(longitude=lon1d, latitude=lat1d).values
        da = DataArray(name=s, data=float32(v))
        file_name = s + '_' + file_time + '.nc'
        da.to_netcdf(im_path+file_name)
    # Run NCL
    chdir(os_path)
    command = 'ncl convert_nc_to_im.ncl ' + "'file_time=" + '"' + file_time + '"' + "'"
    system(command)
    # Flag
    print('The '+str(date)+' IM File Has Been Processed!')
