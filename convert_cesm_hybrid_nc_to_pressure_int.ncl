;******************************************************************************
; NCL script to convert CESM1 (ds316.0) data to Intermediate file format
;
; This script does not look for specific dates in a file - simply convert
; all dates in the input file to IM format, so it is the users responsibility
; to ensure the input data is consistent
;******************************************************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"

begin


;******************************************************************************
; Which CASE are we doing. 
; CASE is only used for naming conventions, but make sure this is correct, 
; else you could clobber exisiting files.
;******************************************************************************

;CASE = "20THC"
;CASE = "RCP85"
;CASE = "RCP60"
;CASE = "RCP45"
if ( .not. isvar("CASE") ) then
  print("We need to know which case we are running")
  exit
end if
  
if ( .not. isvar("IM_root_name") ) then
  IM_root_name = "CESM_CMIP5_MOAR_"+CASE
else
  IM_root_name = IM_root_name+"_"+CASE
end if


if ( .not. isvar("outDIR") ) then
  outDIR = "OUTPUT"
end if


;******************************************************************************
; Don't change anything below this line
;******************************************************************************


;************************************************
; file handling
;************************************************
  print("opening files")
  in_ta    = addfile("atmos_ta.nc","r")      ; 6-hourly 3-d T              
  in_ua    = addfile("atmos_ua.nc","r")      ; 6-hourly 3-d U                
  in_va    = addfile("atmos_va.nc","r")      ; 6-hourly 3-d V                  
  in_hus   = addfile("atmos_hus.nc","r")     ; 6-hourly 3-d Q                   
  in_ps    = addfile("atmos_ps.nc","r")      ; 6-hourly surface pressure
  in_zsfc  = addfile("atmos_zsfc.nc","r")    ; static surface geopotential        
  in_lmask = addfile("atmos_lmask.nc","r")   ; static land mask
  in_snw   = addfile("atmos_snw_1.nc","r")   ; monthly SWE 
  in_mrlsl = addfile("atmos_mrlsl_1.nc","r") ; monthly soil moisture
  in_ts    = addfile("atmos_ts_1.nc","r")    ; monthly skin temp
  in_tsl   = addfile("atmos_tsl_1.nc","r")   ; monthly soil temp
  in_tos   = addfile("atmos_tos_1.nc","r")   ; daily SST on pop grid (gaussian)
  in_sic   = addfile("atmos_sic_1.nc","r")   ; daily SEAICE % on POP grid (guassian)


;************************************************
; read needed variables from file
;************************************************
  print("read variables in")

  time   = in_ta->time                            
  P0 = 1000.       ; value of P0 is 1000.(units=hPa); it is used in both Pa and hPa units below depending on function
  lon = in_ta->lon
  lat = in_ta->lat

  T = in_ta->T(:,::-1,:,:)                               
  U = in_ua->U(:,::-1,:,:)                          
  V = in_va->V(:,::-1,:,:)                     
  Q = in_hus->Q(:,::-1,:,:)                    
  LMASK= in_lmask->LANDMASK*1.0
  PHIS = in_zsfc->PHIS
  ZSFC = PHIS/9.81
  SST_DAY_POP   = in_tos->tos                  
  ICE_DAY_POP   = in_sic->aice_d*0.01 ; convert from % to fraction                        
  PS   = in_ps->PS                        
  LAT  = in_ta->lat                          
  hyam = in_ta->hyam(::-1)                            
  hybm = in_ta->hybm(::-1)                      
  hyai = in_ta->hyai(::-1)                            
  hybi = in_ta->hybi(::-1)                      
  ;print(hyai)
  ;print(hybi)

; get dimensions from dummy variable
  dsizes_x = dimsizes(T)
  ntim     = dsizes_x(0)
  nlev     = dsizes_x(1)
  nlat     = dsizes_x(2)
  nlon     = dsizes_x(3)

; Interpolate SST and SEA ICE fields to CESM Atmospheric domain from POP Ocean domain
  SST_DAY = PopLatLon(SST_DAY_POP,"gx1v6","fv0.9x1.25","bilin","da","090309")
  SST6 = new((/ntim,nlat,nlon/),float) ; create a 6 hourly variable and repeat 4x daily
  SST6(::4,:,:)=SST_DAY
  SST6(1::4,:,:)=SST_DAY
  SST6(2::4,:,:)=SST_DAY
  SST6(3::4,:,:)=SST_DAY
  SST6 = where (ismissing(SST6), -1.E30, SST6) ; set missing value to default for METGRID.TBL

  ICE_DAY = PopLatLon(ICE_DAY_POP,"gx1v6","fv0.9x1.25","bilin","da","090309")
  ICE6 = new((/ntim,nlat,nlon/),float) ; create a 6 hourly variable and repeat 4x daily
  ICE6(::4,:,:)=ICE_DAY
  ICE6(1::4,:,:)=ICE_DAY
  ICE6(2::4,:,:)=ICE_DAY
  ICE6(3::4,:,:)=ICE_DAY
  ICE6 = where (ismissing(ICE6), -1.E30, ICE6) ; set missing value to default for METGRID.TBL

; read in monthly variables and make into 6-hourly
  print("working on monthly variables")
  TSKIN = in_ts->ts
  SNOWW = in_snw->snw
  TSOIL = in_tsl->tsl
  MSOIL = in_mrlsl->mrlsl
  SOILD = in_mrlsl->depth
   
;convert MSOIL from kg m-2 to fraction
  MSOIL = doubletofloat(MSOIL/(1000.*conform(MSOIL,SOILD,1)))

; now make into 6 hourly variables that change every ~30 days
; note that a *key* assumption here is that we are working with
; data in 3 month chunks each time we run this script!!
; note that soil M & T have 15 layers.  We only need the 4 that
; most closely correspond to the NOAH LSM 0-10,10-40,40-100,100-200 cm layers.
; these were predetermined based on inspection of the layers
; they aren't very important because they get spun up anyway...
  TSKIN6   = PS ; dummy
  SNOWW6   = PS ; dummy
  TSOIL1_6 = PS ; dummy 
  TSOIL2_6 = PS ; dummy
  TSOIL3_6 = PS ; dummy
  TSOIL4_6 = PS ; dummy
  MSOIL1_6 = PS ; dummy
  MSOIL2_6 = PS ; dummy
  MSOIL3_6 = PS ; dummy
  MSOIL4_6 = PS ; dummy
   
  TSKIN6(0:119,:,:)     = conform(PS(0:119,:,:),  TSKIN(0,:,:),(/1,2/))
  TSKIN6(120:239,:,:)   = conform(PS(120:239,:,:),TSKIN(1,:,:),(/1,2/))
  TSKIN6(240::,:,:)     = conform(PS(240::,:,:),  TSKIN(2,:,:),(/1,2/))
   
  TAVGSFC6              = TSKIN6              ; This can be used for inland lakes
  
  SNOWW6(0:119,:,:)     = conform(PS(0:119,:,:),  SNOWW(0,:,:),(/1,2/))
  SNOWW6(120:239,:,:)   = conform(PS(120:239,:,:),SNOWW(1,:,:),(/1,2/))
  SNOWW6(240::,:,:)     = conform(PS(240::,:,:),  SNOWW(2,:,:),(/1,2/))
   
  TSOIL1_6(0:119,:,:)   = conform(PS(0:119,:,:),  TSOIL(0,2,:,:),(/1,2/))
  TSOIL1_6(120:239,:,:) = conform(PS(120:239,:,:),TSOIL(1,2,:,:),(/1,2/))
  TSOIL1_6(240::,:,:)   = conform(PS(240::,:,:),  TSOIL(2,2,:,:),(/1,2/))
   
  TSOIL2_6(0:119,:,:)   = conform(PS(0:119,:,:),  TSOIL(0,4,:,:),(/1,2/))
  TSOIL2_6(120:239,:,:) = conform(PS(120:239,:,:),TSOIL(1,4,:,:),(/1,2/))
  TSOIL2_6(240::,:,:)   = conform(PS(240::,:,:),  TSOIL(2,4,:,:),(/1,2/))
   
  TSOIL3_6(0:119,:,:)   = conform(PS(0:119,:,:),  TSOIL(0,6,:,:),(/1,2/))
  TSOIL3_6(120:239,:,:) = conform(PS(120:239,:,:),TSOIL(1,6,:,:),(/1,2/))
  TSOIL3_6(240::,:,:)   = conform(PS(240::,:,:),  TSOIL(2,6,:,:),(/1,2/))
   
  TSOIL4_6(0:119,:,:)   = conform(PS(0:119,:,:),  TSOIL(0,8,:,:),(/1,2/))
  TSOIL4_6(120:239,:,:) = conform(PS(120:239,:,:),TSOIL(1,8,:,:),(/1,2/))
  TSOIL4_6(240::,:,:)   = conform(PS(240::,:,:),  TSOIL(2,8,:,:),(/1,2/))
   
  MSOIL1_6(0:119,:,:)   = conform(PS(0:119,:,:),  MSOIL(0,2,:,:),(/1,2/))
  MSOIL1_6(120:239,:,:) = conform(PS(120:239,:,:),MSOIL(1,2,:,:),(/1,2/))
  MSOIL1_6(240::,:,:)   = conform(PS(240::,:,:),  MSOIL(2,2,:,:),(/1,2/))
   
  MSOIL2_6(0:119,:,:)   = conform(PS(0:119,:,:),  MSOIL(0,4,:,:),(/1,2/))
  MSOIL2_6(120:239,:,:) = conform(PS(120:239,:,:),MSOIL(1,4,:,:),(/1,2/))
  MSOIL2_6(240::,:,:)   = conform(PS(240::,:,:),  MSOIL(2,4,:,:),(/1,2/))
   
  MSOIL3_6(0:119,:,:)   = conform(PS(0:119,:,:),  MSOIL(0,6,:,:),(/1,2/))
  MSOIL3_6(120:239,:,:) = conform(PS(120:239,:,:),MSOIL(1,6,:,:),(/1,2/))
  MSOIL3_6(240::,:,:)   = conform(PS(240::,:,:),  MSOIL(2,6,:,:),(/1,2/))
   
  MSOIL4_6(0:119,:,:)   = conform(PS(0:119,:,:),  MSOIL(0,8,:,:),(/1,2/))
  MSOIL4_6(120:239,:,:) = conform(PS(120:239,:,:),MSOIL(1,8,:,:),(/1,2/))
  MSOIL4_6(240::,:,:)   = conform(PS(240::,:,:),  MSOIL(2,8,:,:),(/1,2/))

; Set missing values to default for METGRID.TBL
  TSOIL1_6 = where (ismissing(TSOIL1_6), -1.E30, TSOIL1_6)
  TSOIL2_6 = where (ismissing(TSOIL2_6), -1.E30, TSOIL2_6)
  TSOIL3_6 = where (ismissing(TSOIL3_6), -1.E30, TSOIL3_6)
  TSOIL4_6 = where (ismissing(TSOIL4_6), -1.E30, TSOIL4_6)

  MSOIL1_6 = where (ismissing(MSOIL1_6), -1.E30, MSOIL1_6)
  MSOIL2_6 = where (ismissing(MSOIL2_6), -1.E30, MSOIL2_6)
  MSOIL3_6 = where (ismissing(MSOIL3_6), -1.E30, MSOIL3_6)
  MSOIL4_6 = where (ismissing(MSOIL4_6), -1.E30, MSOIL4_6)

; Get bottom level temperature for vertical extrapolation
  TBOT = T(:,0,:,:) 

; Calculate geopotential height
  print ("calculate Z")
  TV = T
  TV = T*(1.+0.61*Q)
  Z = T
  Z = cz2ccm(PS,PHIS,TV(:,::-1,:,:),P0*100.,hyam,hybm,hyai,hybi)
  Z = Z(:,::-1,:,:) ;reorder vertical so consistent with T,U,V, and Q (bottom up)

; Calculate the pressures on each hybrid level (bottom up)
  print ("calculate P")
  P = T
  P = pres_hybrid_ccm(PS,P0*100.,hyam,hybm)

; Uses stock RH function in ncl
  print("calculate RH")
  R = T
  R = relhum(T,Q,P)
  R = where(R.gt.100.0, 100.0, R)

; Calculate near surface variables (do this instead of take from files do to greater availability of 3d)
; linearly extrapolate T2 in log(P) from 2 lowest hybrid levels)
; Assume RH at 2 m (R2) is same as RH at lowest hybrid level
; calculate Q2 from R2 and T2
; assume U10 and V10 follow a power law for a neutrally stable atmosphere and
; extrapolate them from the lowest hybrid level. Alpha = 0.143
; Hsu, S.A., et al, 1994,J. Appl. Meteor., Vol. 33, pp. 757-765
  print("calculate near surface variables")
  T2 = PS
  T2 = T(:,1,:,:)-(T(:,1,:,:)-T(:,0,:,:))*((log(PS)-log(P(:,1,:,:)))/(log(P(:,0,:,:))-log(P(:,1,:,:))))
  R2 = R(:,0,:,:)
  U10 = doubletofloat(U(:,0,:,:)*((10./(Z(:,0,:,:)-conform(PS,ZSFC,(/1,2/))))^0.145))
  V10 = doubletofloat(V(:,0,:,:)*((10./(Z(:,0,:,:)-conform(PS,ZSFC,(/1,2/))))^0.145))


;************************************************
; define other arguments required by vinth2p
;************************************************
; type of interpolation: 1 = linear, 2 = log, 3 = loglog
  interp = 2 

; is extrapolation desired if data is outside the range of PS
  extrap = True
   
; create an array of desired pressure levels:
  pnew = (/ 1000.0, 975.0, 950.0, 925.0, 900.0, 850.0, 800.0, 750.0, 700.0, 650.0, 600.0, 550.0, 500.0, \
             450.0, 400.0, 350.0, 300.0, 250.0, 200.0, 150.0, 100.0, 70.0, 50.0, 30.0, 20.0, 10.0 /)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WRITE OUT DATA TO WRF INTERMEDIATE FORMAT (CALL FORTRAN SUBROUTINE VIA WRAPIT)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  print("write out data to WRF intermediate files")

; Set the IM header information
; These are all passed to the write script as resources

  opt = True
  opt@map_source             = "CESM 0.9 x 1.25"
  opt@projection             = 0
  opt@startloc               = "SWCORNER"
  opt@startlon               = doubletofloat(lon(0))
  opt@startlat               = doubletofloat(lat(0))
  opt@deltalon               = doubletofloat(lon(1) - lon(0))
  opt@deltalat               = doubletofloat(lat(1) - lat(0))
  opt@is_wind_earth_relative = False


; set the format to use for the date
  date_format  = "%Y-%N-%D_%H:00:0000000"        		; 24 chars exact for binary file
  date_format2 = "%Y-%N-%D_%H"                                  ; for filename
  yyyy_format  = "%Y" 						; for output directory


; Set up field specific header information
  FIELD_T       ="TT"
  UNITS_T       ="K"
  DESC_T        ="Temperature"

  FIELD_U       ="UU"
  UNITS_U       ="m s-1"
  DESC_U        ="Zonal Wind Speed"

  FIELD_V       ="VV"
  UNITS_V       ="m s-1"
  DESC_V        ="Meridional Wind Speed"

  FIELD_Q       ="SPECHUMD"
  UNITS_Q       ="kg kg-1"
  DESC_Q        ="Specific Humidity"

  FIELD_R       ="RH"
  UNITS_R       ="%"
  DESC_R        ="Relative Humidity"

  FIELD_Z       ="GHT"
  UNITS_Z       ="m"
  DESC_Z        ="Geopotential Height"

  FIELD_SLP     ="PMSL"
  UNITS_SLP     ="Pa"
  DESC_SLP      ="Sea level pressure"
  XLVL_SLP      = 201300.

  FIELD_PS      ="PSFC"
  UNITS_PS      ="Pa"
  DESC_PS       ="Surface pressure"

  FIELD_U10     ="UU"
  UNITS_U10     ="m s-1"
  DESC_U10      ="10 m Zonal Wind Speed"

  FIELD_V10     ="VV"
  UNITS_V10     ="m s-1"
  DESC_V10      ="10 m Meridional Wind Speed"

  FIELD_T2      ="TT"
  UNITS_T2      ="K"
  DESC_T2       ="2 m Temperature"

  FIELD_Q2      ="SPECHUMD"
  UNITS_Q2      ="kg kg-1"
  DESC_Q2       ="2 m Specific Humidity"

  FIELD_R2      ="RH"
  UNITS_R2      ="%"
  DESC_R2       ="2 m Relative Humidity"

  FIELD_SNOWW6  ="SNOW"
  UNITS_SNOWW6  ="kg m-2"
  DESC_SNOWW6   ="Water Equivalent of Accum Snow Depth"

  FIELD_TSKIN6  ="SKINTEMP"
  UNITS_TSKIN6  ="K"
  DESC_TSKIN6   ="Skin Temperature"

  FIELD_TAVGSFC6="TAVGSFC"
  UNITS_TAVGSFC6="K"
  DESC_TAVGSFC6 ="Daily mean of surface air temperature"

  FIELD_SST6    ="SST"
  UNITS_SST6    ="K"; 25 chars exact
  DESC_SST6     ="Sea Surface Temperature"

  FIELD_ICE6    ="SEAICE"
  UNITS_ICE6    ="fraction"
  DESC_ICE6     ="Sea-Ice-Fraction"

  FIELD_TSOIL1_6="ST000010"
  UNITS_TSOIL1_6="K"
  DESC_TSOIL1_6 ="Soil Temperature 0-10 cm layer"

  FIELD_TSOIL2_6="ST010040"
  UNITS_TSOIL2_6="K"
  DESC_TSOIL2_6 ="Soil Temperature 10-40 cm layer"

  FIELD_TSOIL3_6="ST040100"
  UNITS_TSOIL3_6="K"
  DESC_TSOIL3_6 ="Soil Temperature 40-100 cm layer"

  FIELD_TSOIL4_6="ST100200"
  UNITS_TSOIL4_6="K"
  DESC_TSOIL4_6 ="Soil Temperature 100-200 cm layer"

  FIELD_MSOIL1_6="SM000010"
  UNITS_MSOIL1_6="fraction"
  DESC_MSOIL1_6 ="Soil Moisture 0-10 cm layer"

  FIELD_MSOIL2_6="SM010040"
  UNITS_MSOIL2_6="fraction"
  DESC_MSOIL2_6 ="Soil Moisture 10-40 cm layer"

  FIELD_MSOIL3_6="SM040100"
  UNITS_MSOIL3_6="fraction"
  DESC_MSOIL3_6 ="Soil Moisture 40-100 cm layer"

  FIELD_MSOIL4_6="SM100200"
  UNITS_MSOIL4_6="fraction"
  DESC_MSOIL4_6 ="Soil Moisture 100-200 cm layer"

  FIELD_LMASK   ="LANDSEA"
  UNITS_LMASK   ="proprtn"
  DESC_LMASK    ="Land/Sea Flag; 0=Ocean; 1=Land"

  FIELD_ZSFC    ="SOILHGT"
  UNITS_ZSFC    ="m"
  DESC_ZSFC     ="Terrain Elevation"


; Loop through each time period - do final calculations and write data to the IM format
  do TIM = 0,ntim-1 

    HDATE = cd_string(time(TIM), date_format)                          ; set dates
    OFILE = IM_root_name+":" + cd_string(time(TIM), date_format2)      ; figure the output file name so that we can clobber it
    yyyy  = cd_string(time(TIM), yyyy_format)                          ; figure out the year so that we can make directories
    print("HDATE= " + HDATE)
    system ("mkdir -p " + outDIR + "/" + yyyy)	               	       ; make the output directories
    system ("rm " + OFILE)                                             ; delete the file, so that we don't append to an existing file
    system ("rm " + outDIR + "/" +yyyy+ "/" + OFILE)                   ; delete the file, so that we don't append to an existing file


    ; calculate 3-d variables on pressure levels (need to do this here because ncl doesn't like multiple times)
    print("extrapolate variables to pressure levels")
    varflg = 1
    TonP = vinth2p_ecmwf(T(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
    varflg = -1
    ZonP = vinth2p_ecmwf(Z(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
    varflg = 0
    UonP = vinth2p_ecmwf(U(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
    VonP = vinth2p_ecmwf(V(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
    RonP = vinth2p_ecmwf(R(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
    RonP = where(RonP.gt.100.0, 100.0, RonP)
    RonP = where(RonP.lt.0.0, 0.0, RonP)


    ; calcualte slp using ecmwf formulation (no 6-hourly or 3-hourly slp output is otherwise available)
    SLP = doubletofloat(pslec(TBOT(TIM,:,:),PHIS,PS(TIM,:,:),P(TIM,0,:,:)))  


    opt@date = HDATE

    ; write any non-level variables (including treament of soil temp/moisture profiles as single levels each)
    ; Due to the fact that other programs will read these files, and there we assume the fields to in a in given order,
    ; these order of the writes below are import for this application

    opt@level = 200100.
    wrf_wps_write_int(IM_root_name,FIELD_LMASK,UNITS_LMASK,DESC_LMASK, LMASK(:,:),opt)
    wrf_wps_write_int(IM_root_name,FIELD_ZSFC,UNITS_ZSFC,DESC_ZSFC, doubletofloat(ZSFC(:,:)),opt)
    wrf_wps_write_int(IM_root_name,FIELD_TSKIN6,UNITS_TSKIN6,DESC_TSKIN6, TSKIN6(TIM,:,:),opt)        
    wrf_wps_write_int(IM_root_name,FIELD_TAVGSFC6,UNITS_TAVGSFC6,DESC_TAVGSFC6, TAVGSFC6(TIM,:,:),opt) 
    wrf_wps_write_int(IM_root_name,FIELD_SST6,UNITS_SST6,DESC_SST6, SST6(TIM,:,:),opt)    
    wrf_wps_write_int(IM_root_name,FIELD_ICE6,UNITS_ICE6,DESC_ICE6, ICE6(TIM,:,:),opt)   
    wrf_wps_write_int(IM_root_name,FIELD_SNOWW6,UNITS_SNOWW6,DESC_SNOWW6, SNOWW6(TIM,:,:),opt)  
    wrf_wps_write_int(IM_root_name,FIELD_TSOIL1_6,UNITS_TSOIL1_6,DESC_TSOIL1_6, TSOIL1_6(TIM,:,:),opt) 
    wrf_wps_write_int(IM_root_name,FIELD_TSOIL2_6,UNITS_TSOIL2_6,DESC_TSOIL2_6, TSOIL2_6(TIM,:,:),opt) 
    wrf_wps_write_int(IM_root_name,FIELD_TSOIL3_6,UNITS_TSOIL3_6,DESC_TSOIL3_6, TSOIL3_6(TIM,:,:),opt) 
    wrf_wps_write_int(IM_root_name,FIELD_TSOIL4_6,UNITS_TSOIL4_6,DESC_TSOIL4_6, TSOIL4_6(TIM,:,:),opt) 
    wrf_wps_write_int(IM_root_name,FIELD_MSOIL1_6,UNITS_MSOIL1_6,DESC_MSOIL1_6, MSOIL1_6(TIM,:,:),opt) 
    wrf_wps_write_int(IM_root_name,FIELD_MSOIL2_6,UNITS_MSOIL2_6,DESC_MSOIL2_6, MSOIL2_6(TIM,:,:),opt) 
    wrf_wps_write_int(IM_root_name,FIELD_MSOIL3_6,UNITS_MSOIL3_6,DESC_MSOIL3_6, MSOIL3_6(TIM,:,:),opt) 
    wrf_wps_write_int(IM_root_name,FIELD_MSOIL4_6,UNITS_MSOIL4_6,DESC_MSOIL4_6, MSOIL4_6(TIM,:,:),opt) 

    opt@level = XLVL_SLP	; Need a different level for SLP
    wrf_wps_write_int(IM_root_name,FIELD_SLP,UNITS_SLP,DESC_SLP, SLP(:,:),opt)                      

    opt@level = 200100.		; Reset level back to regular surface value
    wrf_wps_write_int(IM_root_name,FIELD_PS,UNITS_PS,DESC_PS, PS(TIM,:,:),opt) 	            
    wrf_wps_write_int(IM_root_name,FIELD_U10,UNITS_U10,DESC_U10, U10(TIM,:,:),opt) 	           
    wrf_wps_write_int(IM_root_name,FIELD_V10,UNITS_V10,DESC_V10, V10(TIM,:,:),opt) 	          
    wrf_wps_write_int(IM_root_name,FIELD_T2,UNITS_T2,DESC_T2, T2(TIM,:,:),opt) 	         
    wrf_wps_write_int(IM_root_name,FIELD_R2,UNITS_R2,DESC_R2, R2(TIM,:,:),opt) 	       


    ; Write each level of the 3D fields out separately
    do LEV=0,dimsizes(pnew)-1

      opt@level = pnew(LEV)*100.
      wrf_wps_write_int(IM_root_name,FIELD_U,UNITS_U,DESC_U, UonP(LEV,:,:),opt)
      wrf_wps_write_int(IM_root_name,FIELD_V,UNITS_V,DESC_V, VonP(LEV,:,:),opt)
      wrf_wps_write_int(IM_root_name,FIELD_T,UNITS_T,DESC_T, TonP(LEV,:,:),opt)
      wrf_wps_write_int(IM_root_name,FIELD_R,UNITS_R,DESC_R, RonP(LEV,:,:),opt)
      wrf_wps_write_int(IM_root_name,FIELD_Z,UNITS_Z,DESC_Z, ZonP(LEV,:,:),opt)

    end do 

    ; move the file to the outDIR directory
      print ("mv " + OFILE + "   " + outDIR + "/" +yyyy+ "/.")
      system ("mv " + OFILE + "   " + outDIR + "/" +yyyy+ "/.")
      print("  ")

     delete(HDATE)
     delete(OFILE)
  end do 

end

