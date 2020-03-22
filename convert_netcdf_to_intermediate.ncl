load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"

begin

    data_dir  = "/home/zhangc/scenariomip_cmip6/"
    data_time = "2015-01-01_00:00:00"

    ta = addfile(data_dir+"ta_"+data_time+".nc","r")

    time = ta->time
    lon  = ta->lon
    lat  = ta->lat
    lev  = ta->lev

    T = ta->ta

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

    ODIR = "/home/zhangc/senariomip_cmip6/data"
    TIME = cd_string(time, time_format)
    ROOT = "CESM2"
    FILE = ROOT + "_" + cd_string(time, date_format)
    YEAR  = cd_string(time, year_format)

    print("TIME = "+TIME)

    system("mkdir -p "+ODIR+"/"+YEAR)
    system("rm "+FILE)
    system("rm "+ODIR+"/"+YEAR+"/"+FILE)

    opt@date = TIME

    do i=0,dimsizes(lev)-1
        opt@level = -doubletofloat(lev(i))*100.
        wrf_wps_write_int(ROOT,field_t,units_t,descr_t,T(i,:,:),opt)
    end do

    print ("mv "+FILE+" "+ODIR+"/"+YEAR+"/.")
    system("mv "+FILE+" "+ODIR+"/"+YEAR+"/.")

    delete(TIME)
    delete(FILE)

end
