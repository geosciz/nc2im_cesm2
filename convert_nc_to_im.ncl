load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"

begin

    data_path  = "/home/zhangc/scenariomip_cmip6/im_data/"
    file_time = "2015-01-01_00:00:00"

    ta  = addfile(data_path+"ta_"+file_time+".nc","r")
    hus = addfile(data_path+"hus_"+file_time+".nc","r")
    ua  = addfile(data_path+"ua_"+file_time+".nc","r")
    va  = addfile(data_path+"va_"+file_time+".nc","r")
    p   = addfile(data_path+"p_"+file_time+".nc","r")
    ps  = addfile(data_path+"ps_"+file_time+".nc","r")
    ts  = addfile(data_path+"ts_"+file_time+".nc","r")

    command = "rm " + data_path + "*" + file_time + "*"
    system(command)

    time = ta->time
    lon  = ta->lon
    lat  = ta->lat
    lev  = ta->lev

    T  = ta->ta
    Q  = hus->hus
    U  = ua->ua
    V  = va->va
    P  = p->p
    PS = ps->ps
    TS = ts->ts

    opt = True
    opt@map_source             = "CESM2"
    opt@projection             = 0
    opt@startloc               = "SWCORNER"
    opt@startlon               = doubletofloat(lon(0))
    opt@startlat               = doubletofloat(lat(0))
    opt@deltalon               = doubletofloat(lon(1)-lon(0))
    opt@deltalat               = doubletofloat(lat(1)-lat(0))
    opt@is_wind_earth_relative = False

    time_format1 = "%Y-%N-%D_%H:00:0000000"
    time_format2 = "%Y-%N-%D_%H"

    ; 3-d air temperature
    field_t = "TT"
    units_t = "K"
    descr_t = "3-D Air Temperature"

    ; 3-d specific humidity
    field_q = "SPECHUMD"
    units_q = "kg kg-1"
    descr_q = "3-D Specific Humidity"

    ; 3-d wind u-component
    field_u = "UU"
    units_u = "m s-1"
    descr_u = "3-D Wind U-Component"

    ; 3-d wind v-component
    field_v = "VV"
    units_v = "m s-1"
    descr_v = "3-D Wind V-Component"

    ; 3-d geopotential height
    field_z = "GHT"
    units_z = "m"
    descr_z = "3-D Geopotential Height"

    ; surface pressure
    field_ps = "PSFC"
    units_ps = "Pa"
    descr_ps = "Surface Pressure"

    ; skin temperature
    field_ts = "SKINTEMP"
    units_ts = "K"
    descr_ts = "Skin Temperature"

    HDATE = cd_string(time, time_format1)
    file_pref = "CESM2_SCENARIOMIP_SSP245"
    OFILE = file_pref + ":" + cd_string(time, time_format2)
    root_name = data_path + file_pref

    command = "rm " + data_path + OFILE
    system(command)

    opt@date = HDATE

    opt@level = 200100.
    wrf_wps_write_int(root_name,field_ts,units_ts,descr_ts,TS(:,:),opt)
    wrf_wps_write_int(root_name,field_ps,units_ps,descr_ps,PS(:,:),opt)

    do i=0,dimsizes(lev)-1
        opt@level = -doubletofloat(lev(i))*100.
        wrf_wps_write_int(root_name,field_t,units_t,descr_t,T(i,:,:),opt)
        wrf_wps_write_int(root_name,field_q,units_q,descr_q,Q(i,:,:),opt)
        wrf_wps_write_int(root_name,field_u,units_u,descr_u,U(i,:,:),opt)
        wrf_wps_write_int(root_name,field_v,units_v,descr_v,V(i,:,:),opt)
    end do

end
