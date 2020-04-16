load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"

begin

    data_path = "/home/zhangc/scenariomip_cmip6/im_data/"
    file_time = "2015-01-01_00:00:00"

    ls = addfile(data_path+"ls_"+file_time+".nc","r")
    sh = addfile(data_path+"sh_"+file_time+".nc","r")

    ta  = addfile(data_path+"ta_"+file_time+".nc","r")
    hus = addfile(data_path+"hus_"+file_time+".nc","r")
    ua  = addfile(data_path+"ua_"+file_time+".nc","r")
    va  = addfile(data_path+"va_"+file_time+".nc","r")
    ps  = addfile(data_path+"ps_"+file_time+".nc","r")

    ts = addfile(data_path+"ts_"+file_time+".nc","r")

    t2 = addfile(data_path+"t2_"+file_time+".nc","r")
    q2 = addfile(data_path+"q2_"+file_time+".nc","r")
    u2 = addfile(data_path+"u2_"+file_time+".nc","r")
    v2 = addfile(data_path+"v2_"+file_time+".nc","r")
    p2 = addfile(data_path+"p2_"+file_time+".nc","r")

    command = "rm " + data_path + "*" + file_time + "*"
    ;system(command)

    time = ta->time
    lon  = ta->lon
    lat  = ta->lat
    lev  = ta->lev

    LS = ls->LANDMASK
    SH = sh->PHIS

    T3 = ta->ta
    Q3 = hus->hus
    U3 = ua->ua
    V3 = va->va
    PS = ps->ps

    TS = ts->ts

    T2 = t2->ta
    Q2 = q2->hus
    U2 = u2->ua
    V2 = v2->va
    P2 = p2->p2

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

    ; T3
    field_t3 = "TT"
    units_t3 = "K"
    descr_t3 = "3-D Air Temperature"

    ; Q3
    field_q3 = "SPECHUMD"
    units_q3 = "kg kg-1"
    descr_q3 = "3-D Specific Humidity"

    ; U3
    field_u3 = "UU"
    units_u3 = "m s-1"
    descr_u3 = "3-D Wind U-Component"

    ; V3
    field_v3 = "VV"
    units_v3 = "m s-1"
    descr_v3 = "3-D Wind V-Component"

    ; Z3
    field_z3 = "GHT"
    units_z3 = "m"
    descr_z3 = "3-D Geopotential Height"

    ; PS
    field_ps = "PSFC"
    units_ps = "Pa"
    descr_ps = "Surface Pressure"

    ; P2
    field_p2 = "PMSL"
    units_p2 = "Pa"
    descr_p2 = "Mean Sea-Level Pressure"

    ; TS
    field_ts = "SKINTEMP"
    units_ts = "K"
    descr_ts = "Skin Temperature"

    ; SH
    field_sh = "SOILHGT"
    units_sh = "m"
    descr_sh = "Soil Height"

    ; T2
    field_t2 = "TT"
    units_t2 = "K"
    descr_t2 = "2-Meter Air Temperature"

    ; Q2
    field_q2 = "SPECHUMD"
    units_q2 = "kg kg-1"
    descr_q2 = "2-Meter Specific Humidity"

    ; U2
    field_u2 = "UU"
    units_u2 = "m s-1"
    descr_u2 = "2-Meter Wind U-Component"

    ; V2
    field_v2 = "VV"
    units_v2 = "m s-1"
    descr_v2 = "2-Meter Wind V-Component"

    ; LS
    field_ls = "LANDSEA"
    units_ls = "fraction"
    descr_ls = "Land-Sea Mask (0=Water, 1=Land)"

    HDATE = cd_string(time, time_format1)
    file_pref = "CESM2_SCENARIOMIP_SSP245"
    OFILE = file_pref + ":" + cd_string(time, time_format2)
    root_name = data_path + file_pref

    command = "rm " + data_path + OFILE
    system(command)

    opt@date = HDATE

    opt@level = 200100.
    wrf_wps_write_int(root_name,field_ls,units_ls,descr_ls,LS(:,:),opt)
    wrf_wps_write_int(root_name,field_sh,units_sh,descr_sh,SH(:,:),opt)
    wrf_wps_write_int(root_name,field_ts,units_ts,descr_ts,TS(:,:),opt)

    opt@level = 201300.
    wrf_wps_write_int(root_name,field_p2,units_p2,descr_p2,P2(:,:),opt)

    opt@level = 200100.
    wrf_wps_write_int(root_name,field_ps,units_ps,descr_ps,PS(:,:),opt)
    wrf_wps_write_int(root_name,field_u2,units_u2,descr_u2,U2(:,:),opt)
    wrf_wps_write_int(root_name,field_v2,units_v2,descr_v2,V2(:,:),opt)
    wrf_wps_write_int(root_name,field_t2,units_t2,descr_t2,T2(:,:),opt)
    wrf_wps_write_int(root_name,field_q2,units_q2,descr_q2,Q2(:,:),opt)

    do i=0,dimsizes(lev)-1
        opt@level = -doubletofloat(lev(i))*100.
        wrf_wps_write_int(root_name,field_t3,units_t3,descr_t3,T3(i,:,:),opt)
        wrf_wps_write_int(root_name,field_q3,units_q3,descr_q3,Q3(i,:,:),opt)
        wrf_wps_write_int(root_name,field_u3,units_u3,descr_u3,U3(i,:,:),opt)
        wrf_wps_write_int(root_name,field_v3,units_v3,descr_v3,V3(i,:,:),opt)
        ;wrf_wps_write_int(root_name,field_z3,units_z3,descr_z3,Z3(i,:,:),opt)
    end do

end
