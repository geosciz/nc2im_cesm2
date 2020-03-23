load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"

begin

    data_dir  = "/home/zhangc/scenariomip_cmip6/"
    file_time = "2015-01-01_00:00:00"

    ta  = addfile(data_dir+"ta_"+file_time+".nc","r")
    hus = addfile(data_dir+"hus_"+file_time+".nc","r")
    ua  = addfile(data_dir+"ua_"+file_time+".nc","r")
    va  = addfile(data_dir+"va_"+file_time+".nc","r")

    system("rm "+data_dir+"*"+file_time+"*")

    time = ta->time
    lon  = ta->lon
    lat  = ta->lat
    lev  = ta->lev

    T = ta->ta
    Q = hus->hus
    U = ua->ua
    V = va->va

    opt = True
    opt@map_source             = " "
    opt@projection             = 0
    opt@startloc               = "SWCORNER"
    opt@startlon               = doubletofloat(lon(0))
    opt@startlat               = doubletofloat(lat(0))
    opt@deltalon               = doubletofloat(lon(1)-lon(0))
    opt@deltalat               = doubletofloat(lat(1)-lat(0))
    opt@is_wind_earth_relative = False

    time_format = "%Y-%N-%D_%H:00:0000000"
    date_format = "%Y-%N-%D_%H"
    year_format = "%Y"

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


    ODIR = "/home/zhangc/senariomip_cmip6/data"
    TIME = cd_string(time, time_format)
    ROOT = "CESM2"
    FILE = ROOT + "_" + cd_string(time, date_format)
    YEAR  = cd_string(time, year_format)

    print("TIME = "+TIME)

    opt@date = TIME

    do i=0,dimsizes(lev)-1
        opt@level = -doubletofloat(lev(i))*100.
        wrf_wps_write_int(ROOT,field_t,units_t,descr_t,T(i,:,:),opt)
        wrf_wps_write_int(ROOT,field_q,units_q,descr_q,Q(i,:,:),opt)
        wrf_wps_write_int(ROOT,field_u,units_u,descr_u,U(i,:,:),opt)
        wrf_wps_write_int(ROOT,field_v,units_v,descr_v,V(i,:,:),opt)
    end do

end
