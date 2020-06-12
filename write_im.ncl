load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin

    data_path = "/home/zhangc/cesm2_cmip6/im_data/"

    time = addfile(data_path+"time_"+file_time+".nc","r")
    lon = addfile(data_path+"lon_"+file_time+".nc","r")
    lat = addfile(data_path+"lat_"+file_time+".nc","r")

    ps = addfile(data_path+"ps_"+file_time+".nc","r")
    hyam = addfile(data_path+"hyam_"+file_time+".nc","r")
    hybm = addfile(data_path+"hybm_"+file_time+".nc","r")
    hyai = addfile(data_path+"hyai_"+file_time+".nc","r")
    hybi = addfile(data_path+"hybi_"+file_time+".nc","r")

    ls = addfile(data_path+"ls_"+file_time+".nc","r")
    phis = addfile(data_path+"phis_"+file_time+".nc","r")
    sh = addfile(data_path+"sh_"+file_time+".nc","r")

    p = addfile(data_path+"p_"+file_time+".nc","r")
    ta = addfile(data_path+"ta_"+file_time+".nc","r")
    hus = addfile(data_path+"hus_"+file_time+".nc","r")
    ua = addfile(data_path+"ua_"+file_time+".nc","r")
    va = addfile(data_path+"va_"+file_time+".nc","r")
    tv = addfile(data_path+"tv_"+file_time+".nc","r")
    ts = addfile(data_path+"ts_"+file_time+".nc","r")
    ;sst = addfile(data_path+"sst_"+file_time+".nc","r")
    ;sic = addfile(data_path+"sic_"+file_time+".nc","r")
    ;snw = addfile(data_path+"snw_"+file_time+".nc","r")

    sm1 = addfile(data_path+"swvl1_"+file_time+".nc","r")
    sm2 = addfile(data_path+"swvl2_"+file_time+".nc","r")
    sm3 = addfile(data_path+"swvl3_"+file_time+".nc","r")
    sm4 = addfile(data_path+"swvl4_"+file_time+".nc","r")
    st1 = addfile(data_path+"tsl0_"+file_time+".nc","r")
    st2 = addfile(data_path+"tsl1_"+file_time+".nc","r")
    st3 = addfile(data_path+"tsl2_"+file_time+".nc","r")
    st4 = addfile(data_path+"tsl3_"+file_time+".nc","r")

    command = "rm " + data_path + "*" + file_time + "*"
    system(command)

    TIME = time->time
    LON = lon->lon
    LAT = lat->lat
    AM = hyam->hyam
    BM = hybm->hybm
    AI = hyai->hyai
    BI = hybi->hybi

    PS = ps->ps
    LS = ls->ls
    PHIS = phis->phis
    SH = sh->sh

    P = p->p
    T = ta->ta
    Q = hus->hus
    U = ua->ua
    V = va->va
    TV = tv->tv
    TS = ts->ts
    ;SST = sst->sst
    ;SIC = sic->sic
    ;SNW = snw->snw

    SM1 = sm1->swvl1
    SM2 = sm2->swvl2
    SM3 = sm3->swvl3
    SM4 = sm4->swvl4
    ST1 = st1->tsl0
    ST2 = st2->tsl1
    ST3 = st3->tsl2
    ST4 = st4->tsl3

    R = relhum(T,Q,P)

    P0PA = 100000.
    Z = cz2ccm(PS,PHIS,TV(::-1,:,:),P0PA,AM,BM,AI,BI)
    Z = Z(::-1,:,:)

    TL0 = T(0,:,:)
    TL1 = T(1,:,:)
    PL0 = P(0,:,:)
    PL1 = P(1,:,:)
    T2 = TL1-(TL1-TL0)*((log(PS)-log(PL1))/(log(PL0)-log(PL1)))
    R2 = R(0,:,:)
    UL0 = U(0,:,:)
    VL0 = V(0,:,:)
    ZL0 = Z(0,:,:)
    UX = UL0*((10./(ZL0-SH))^0.145)
    VX = VL0*((10./(ZL0-SH))^0.145)

    PL0 = P(0,:,:)
    SLP = pslec(TL0,PHIS,PS,PL0)

    PLEV = (/ 1000., 975., 950., 925., 900., 850., 800., 750., 700., \
               650., 600., 550., 500., 450., 400., 350., 300., 250., \
               200., 150., 100.,  70.,  50.,  30.,  20.,  10. /)
    INTYP = 2
    P0MB = 1000.
    II = 1
    KXTRP = True
    TP = vinth2p_ecmwf(T(::-1,:,:),AM(::-1),BM(::-1),PLEV,PS,INTYP,P0MB,II,KXTRP,1,TL0,PHIS)
    RP = vinth2p_ecmwf(R(::-1,:,:),AM(::-1),BM(::-1),PLEV,PS,INTYP,P0MB,II,KXTRP,0,TL0,PHIS)
    UP = vinth2p_ecmwf(U(::-1,:,:),AM(::-1),BM(::-1),PLEV,PS,INTYP,P0MB,II,KXTRP,0,TL0,PHIS)
    VP = vinth2p_ecmwf(V(::-1,:,:),AM(::-1),BM(::-1),PLEV,PS,INTYP,P0MB,II,KXTRP,0,TL0,PHIS)
    ZP = vinth2p_ecmwf(Z(::-1,:,:),AM(::-1),BM(::-1),PLEV,PS,INTYP,P0MB,II,KXTRP,-1,TL0,PHIS)

    field_t3 = "TT"
    units_t3 = "K"
    descr_t3 = "3-d air temperature"

    field_r3 = "RH"
    units_r3 = "%"
    descr_r3 = "3-d relative humidity"

    field_u3 = "UU"
    units_u3 = "m s-1"
    descr_u3 = "3-d wind u-component"

    field_v3 = "VV"
    units_v3 = "m s-1"
    descr_v3 = "3-d wind v-component"

    field_z3 = "GHT"
    units_z3 = "m"
    descr_z3 = "3-d geopotential height"

    field_ps = "PSFC"
    units_ps = "Pa"
    descr_ps = "surface pressure"

    field_slp = "PMSL"
    units_slp = "Pa"
    descr_slp = "mean sea-level pressure"

    field_ts = "SKINTEMP"
    units_ts = "K"
    descr_ts = "skin temperature"

    field_sh = "SOILHGT"
    units_sh = "m"
    descr_sh = "soil height"

    field_t2 = "TT"
    units_t2 = "K"
    descr_t2 = "2-meter air temperature"

    field_r2 = "RH"
    units_r2 = "%"
    descr_r2 = "2-meter relative humidity"

    field_ux = "UU"
    units_ux = "m s-1"
    descr_ux = "10-meter wind u-component"

    field_vx = "VV"
    units_vx = "m s-1"
    descr_vx = "10-meter wind v-component"

    field_ls = "LANDSEA"
    units_ls = "fraction"
    descr_ls = "land-sea mask (0=water, 1=land)"

    field_sm1 = "SM000010"
    units_sm1 = "m3 m-3"
    descr_sm1 = "soil moisture"

    field_sm2 = "SM010040"
    units_sm2 = "m3 m-3"
    descr_sm2 = "soil moisture"

    field_sm3 = "SM040100"
    units_sm3 = "m3 m-3"
    descr_sm3 = "soil moisture"

    field_sm4 = "SM100200"
    units_sm4 = "m3 m-3"
    descr_sm4 = "soil moisture"

    field_st1 = "ST000010"
    units_st1 = "K"
    descr_st1 = "soil temperature"

    field_st2 = "ST010040"
    units_st2 = "K"
    descr_st2 = "soil temperature"

    field_st3 = "ST040100"
    units_st3 = "K"
    descr_st3 = "soil temperature"

    field_st4 = "ST100200"
    units_st4 = "K"
    descr_st4 = "soil temperature"

    field_sst = "SST"
    units_sst = "K"
    descr_sst = "sea surface temperature"

    field_sic = "SEAICE"
    units_sic = "fraction"
    descr_sic = "sea ice concentration"

    field_snw = "SNOW"
    units_snw = "kg m-2"
    descr_snw = "surface snow amount"

    field_tav = "TAVGSFC"
    units_tav = "K"
    descr_tav = "daily mean of surface air temperature"

    opt = True
    opt@map_source = "CESM2"
    opt@projection = 0
    opt@startloc = "SWCORNER"
    opt@startlon = doubletofloat(LON(0))
    opt@startlat = doubletofloat(LAT(0))
    opt@deltalon = doubletofloat(LON(1)-LON(0))
    opt@deltalat = doubletofloat(LAT(1)-LAT(0))
    opt@is_wind_earth_relative = False

    time_long = "%Y-%N-%D_%H:00:0000000"
    time_short = "%Y-%N-%D_%H"
    HDATE = cd_string(TIME,time_long)
    file_pref = "CESM2_CMIP6_HISTORICAL"
    OFILE = file_pref + ":" + cd_string(TIME,time_short)
    root_name = data_path + file_pref

    command = "rm " + data_path + OFILE
    system(command)

    opt@date = HDATE

    opt@level = 200100.
    wrf_wps_write_int(root_name,field_ls,units_ls,descr_ls,LS,opt)
    wrf_wps_write_int(root_name,field_sh,units_sh,descr_sh,SH,opt)
    wrf_wps_write_int(root_name,field_ts,units_ts,descr_ts,TS,opt)
    wrf_wps_write_int(root_name,field_tav,units_tav,descr_tav,TS,opt)
    ;wrf_wps_write_int(root_name,field_sst,units_sst,descr_sst,SST,opt)
    ;wrf_wps_write_int(root_name,field_sic,units_sic,descr_sic,SIC,opt)
    ;wrf_wps_write_int(root_name,field_snw,units_snw,descr_snw,SNW,opt)
    wrf_wps_write_int(root_name,field_st1,units_st1,descr_st1,ST1,opt)
    wrf_wps_write_int(root_name,field_st2,units_st2,descr_st2,ST2,opt)
    wrf_wps_write_int(root_name,field_st3,units_st3,descr_st3,ST3,opt)
    wrf_wps_write_int(root_name,field_st4,units_st4,descr_st4,ST4,opt)
    wrf_wps_write_int(root_name,field_sm1,units_sm1,descr_sm1,SM1,opt)
    wrf_wps_write_int(root_name,field_sm2,units_sm2,descr_sm2,SM2,opt)
    wrf_wps_write_int(root_name,field_sm3,units_sm3,descr_sm3,SM3,opt)
    wrf_wps_write_int(root_name,field_sm4,units_sm4,descr_sm4,SM4,opt)

    opt@level = 201300.
    wrf_wps_write_int(root_name,field_slp,units_slp,descr_slp,SLP,opt)

    opt@level = 200100.
    wrf_wps_write_int(root_name,field_ps,units_ps,descr_ps,PS,opt)
    wrf_wps_write_int(root_name,field_ux,units_ux,descr_ux,UX,opt)
    wrf_wps_write_int(root_name,field_vx,units_vx,descr_vx,VX,opt)
    wrf_wps_write_int(root_name,field_t2,units_t2,descr_t2,T2,opt)
    wrf_wps_write_int(root_name,field_r2,units_r2,descr_r2,R2,opt)

    do i=0,dimsizes(PLEV)-1
        opt@level = PLEV(i)*100.
        wrf_wps_write_int(root_name,field_u3,units_u3,descr_u3,UP(i,:,:),opt)
        wrf_wps_write_int(root_name,field_v3,units_v3,descr_v3,VP(i,:,:),opt)
        wrf_wps_write_int(root_name,field_t3,units_t3,descr_t3,TP(i,:,:),opt)
        wrf_wps_write_int(root_name,field_r3,units_r3,descr_r3,RP(i,:,:),opt)
        wrf_wps_write_int(root_name,field_z3,units_z3,descr_z3,ZP(i,:,:),opt)
    end do

end
