#!/usr/bin/env python
# coding: utf-8

# In[ ]:


from cftime import DatetimeNoLeap
from os import chdir, system
from numpy import float64, multiply
from xarray import open_dataset


# In[ ]:


nc_path = '/home/zhangc/scenariomip_cmip6/nc_data/'
im_path = '/home/zhangc/scenariomip_cmip6/im_data/'
os_path = '/home/zhangc/repositories/nc2im_cesm2/'


# In[ ]:


dt = 2015, 1, 1, 0
data_time = DatetimeNoLeap(dt[0], dt[1], dt[2], dt[3])
file_time = str(data_time).replace(' ', '_')


# In[ ]:


plev = [1000, 975, 950, 925, 900, 850, 800, 750, 700, 650, 600, 550, 500,
         450, 400, 350, 300, 250, 200, 150, 100,  70,  50,  30,  20,  10]


# In[ ]:


nlev = multiply(plev, -1)
data_lev = float64(nlev)


# In[ ]:


chdir(nc_path)


# In[ ]:


ncs = ['ta_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',
       'hus_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',
       'ua_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc',
       'va_6hrLev_CESM2_ssp245_r2i1p1f1_gn_201501010000-202412311800.nc']


# In[ ]:


for nc in ncs:
    ds = open_dataset(nc).sel(time=data_time)
    vi = ds.variable_id
    da = ds[vi].interp(lev=data_lev, kwargs={'fill_value': 'extrapolate'})
    file_name = vi + '_' + file_time + '.nc'
    da.to_netcdf(im_path+file_name)


# In[ ]:


chdir(os_path)


# In[ ]:


command = 'ncl convert_nc_to_im.ncl ' + "'file_time=" + '"' + file_time + '"' + "'"


# In[ ]:


system(command)

