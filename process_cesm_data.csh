#!/bin/csh -f
#set echo

###########
# Remember to load the cdo module before running this code
###########

# The code runs in one year sections. 
# To ensure that the NCL code is not memory intensive, the NCL part will run in three month sections.


if ( ${#argv} < 2 ) then
  echo "Must at least specify the the case to run and the year on the command line"
  echo "  Available command line options are:"
  echo "  -c CASE (eg, -c 20THC). (Options are: 20THC, RCP85, RCP60, or RCP45) - Required"
  echo "  -y YYYY (eg, -y 1980) - Required"
  echo "  -m XX  (number of years to process) - Optional"
  echo "  -f FILENAME (IM root name to use). The case used will be appending to the root name - Optional setting"
  echo "  -o DIRECTORY (output directory) - Optional"
  echo " "
  echo "  eg:  ./process_cesm_data.csh  -c 20THC -y 1980 -m 4"
  echo " "
  exit
endif


set CASE = "dummy"
set doYY = 0
set numYY = 0
set IM_root_name = "CESM_CMIP5_MOAR"
set outDIR = "OUTPUT"

while ( ${#argv} )
  set whichARG = ` echo $1 | cut -c2 `
  switch ($whichARG)
    case [c]:
      set CASE = $2
      breaksw
    case [y]:
      set doYY = $2
      breaksw
    case [m]:
      set numYY = $2
      breaksw
    case [f]:
      set IM_root_name = $2
      breaksw
    case [o]:
      set outDIR = $2
      breaksw
  endsw
  shift
  shift
end

if ( $CASE != "20THC" && $CASE != "RCP85" && $CASE != "RCP60" && $CASE != "RCP45" ) then
  echo "Must at least specify the the case to run and the year on the command line"
  echo "  Available command line options are:"
  echo "  -c CASE (eg, -c 20THC). (Options are: 20THC, RCP85, RCP60, or RCP45)"
  echo "  -y YYYY (eg, -y 1980)"
  echo "  -m XX  (number of years to process) "
  echo " "
  echo "  eg:  ./process_cesm_data.csh  -c 20THC -y 1980 -m 4"
  echo " "
  exit
endif

if ( $doYY == 0 ) then
  echo "Must at least specify the the case to run and the year on the command line"
  echo "  Available command line options are:"
  echo "  -c CASE (eg, -c 20THC). (Options are: 20THC, RCP85, RCP60, or RCP45)"
  echo "  -y YYYY (eg, -y 1980)"
  echo "  -m XX  (number of years to process) "
  echo " "
  echo "  eg:  ./process_cesm_data.csh  -c 20THC -y 1980 -m 4"
  echo " "
  exit
endif

if ( $numYY > 0 ) then   
  @ endYY = $doYY + $numYY - 1
else
  set endYY = $doYY
endif

echo " "
echo "   Processing CESM for $CASE for years $doYY to $endYY "
echo "   The output will have root names ${IM_root_name}_${CASE} and will be saved to the directory $outDIR"
echo " "
 
while ( $doYY <= $endYY ) 
  foreach mm (1 4 7 10)

    set yyyy   = $doYY
    set dd     = 1
    set hh     = 0
    set months = 3
  
    if ( $CASE == "20THC" ) then
      if ( $yyyy > 2005 ) then
        echo " For the 20THC the year must be less or equal to 2005"
        echo " " 
        exit
      endif
    else
      if ( $yyyy < 2006 ) then
        echo " For the climate projections the year must be greater or equal to 2006"
        echo " " 
        exit
      endif
    endif
    
    
    set eDDs = (31 28 31 30 31 30 31 31 30 31 30 31)
    
    set smm=`printf %02d $mm`
    set sdd=`printf %02d $dd`
    set shh=`printf %02d $hh`
    
    @ test_mm = $mm + $months - 1
    set emm=`printf %02d $test_mm`
    set edd = $eDDs[$test_mm] 
    set ehh = 18
    
    
    #get rid of old symlinks to CESM source files
    rm atmos_*.nc
    
    
    #symlink to constants (surface geopotential and land mask) ; note that these a specific to these CMIP5 CCSM4 runs
    ln -s ../Invariant_Data/USGS-gtopo30_0.9x1.25_remap_c051027.nc atmos_zsfc.nc
    ln -s ../Invariant_Data/fracdata_0.9x1.25_gx1v6_c090317.nc atmos_lmask.nc
    
    
    # Top directory for all files
    set topDIR_1 = "/glade/p/vetssg/data/CMIP5/output1/NCAR/CCSM4"
    set topDIR_2 = "/glade/p/rda/data/ds316.0"
    set member   = "r6i1p1"
    
    if ( $CASE == "20THC" ) then
      set clim_case  = "historical"
      set CASE_glade = "20thC"
      set date_start_ld = 1850
      set date_end_ld   = 1900
      while ( $yyyy >= ${date_end_ld} )
        @ date_start_ld  = $date_start_ld + 50          
        @ date_end_ld    = $date_end_ld + 50          
      end
      set date_start_oc = 1850
      set date_end_oc   = 1870
      while ( $yyyy >= ${date_end_oc} )
        @ date_start_oc  = $date_start_oc + 20          
        @ date_end_oc    = $date_end_oc + 20          
      end
    else
      set clim_case  = `echo $CASE | tr "[:upper:]" "[:lower:]"`
      set CASE_glade = ` echo $clim_case | cut -c1-4 `_` echo $clim_case | cut -c5 `
      set date_start_ld = 2000
      set date_end_ld   = 2050
      while ( $yyyy >= ${date_end_ld} )
        @ date_start_ld  = $date_start_ld + 50          
        @ date_end_ld    = $date_end_ld + 50          
      end
      set date_start_oc = 2000
      set date_end_oc   = 2020
      while ( $yyyy >= ${date_end_oc} )
        @ date_start_oc  = $date_start_oc + 20          
        @ date_end_oc    = $date_end_oc + 20          
      end
      if ( ${date_start_ld} == 2000 ) then
        set date_start_ld = 2006
        set date_start_oc = 2006
      endif
    endif
    
    
    #symlink to monthly variables that we will need to make into 6-hourly because 6-hourly variables are not available.
    # Note: Don't worry too much about these -- they are mainly just used to initialize
    # The variables are skintemp (ts), soil moisture (mrlsl in kg m-2), soil temperature (tsl), and liquid snow water equivalent (snw kg m-2)
    
     ln -s ${topDIR_1}/${clim_case}/mon/atmos/Amon/${member}/latest/ts/ts_Amon_CCSM4_*.nc                                              atmos_ts.nc
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} atmos_ts.nc                                                               atmos_ts_1.nc
    
     ln -s ${topDIR_1}/${clim_case}/mon/landIce/LImon/${member}/latest/snw/snw_LImon_CCSM4_*.nc                                        atmos_snw.nc
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} atmos_snw.nc                                                              atmos_snw_1.nc
    
     ln -s ${topDIR_1}/${clim_case}/mon/land/Lmon/${member}/latest/mrlsl/mrlsl_Lmon_CCSM4_${clim_case}_${member}_${date_start_ld}*.nc  atmos_mrlsl.nc
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} atmos_mrlsl.nc                                                            atmos_mrlsl_1.nc
    
     ln -s ${topDIR_1}/${clim_case}/mon/land/Lmon/${member}/latest/tsl/tsl_Lmon_CCSM4_${clim_case}_${member}_${date_start_ld}*.nc      atmos_tsl.nc
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} atmos_tsl.nc                                                              atmos_tsl_1.nc
    
     ln -s ${topDIR_1}/${clim_case}/day/ocean/day/${member}/latest/tos/tos_day_CCSM4_${clim_case}_${member}_${date_start_oc}*.nc       atmos_tos.nc 
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} atmos_tos.nc                                                              atmos_tos_1.nc
    

    # Unfortunately this data is not available on the glade directory - get from HPSS - run get_seaice.csh to downlowd data first
    #ln -s ${topDIR_1}/${clim_case}/mon/seaIce/OImon/${member}/latest/sic/sic_OImon_CCSM4_${clim_case}_${member}_${date_start_end}.nc  atmos_sic.nc
    #cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} atmos_sic.nc                                                              atmos_sic_1.nc
     set test_month = $months
     cp ./SEAICE/${CASE_glade}_sic_pct_${yyyy}-${smm}.nc   atmos_sic_1.nc
     set tmm = $mm
     while ( $test_month > 1 )
       @ tmm = $tmm + 1   
       set mmm=`printf %02d $tmm`
       cdo mergetime atmos_sic_1.nc ./SEAICE/${CASE_glade}_sic_pct_${yyyy}-${mmm}.nc tmp_sic.nc
       cp tmp_sic.nc atmos_sic_1.nc
       rm tmp_sic.nc
       @ test_month = $test_month - 1
     end
    

     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} ${topDIR_2}/${CASE_glade}/ts/T/${yyyy}.${CASE_glade}.T.nc                 atmos_ta.nc
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} ${topDIR_2}/${CASE_glade}/ts/Q/${yyyy}.${CASE_glade}.Q.nc                 atmos_hus.nc
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} ${topDIR_2}/${CASE_glade}/ts/U/${yyyy}.${CASE_glade}.U.nc                 atmos_ua.nc
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} ${topDIR_2}/${CASE_glade}/ts/V/${yyyy}.${CASE_glade}.V.nc                 atmos_va.nc
     cdo seldate,${yyyy}-${smm}-${sdd},${yyyy}-${emm}-${edd} ${topDIR_2}/${CASE_glade}/ts/PS/${yyyy}.${CASE_glade}.PS.nc               atmos_ps.nc
    
    
    #;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    # Finally, run the ncl script to convert these netcdf data to intermediate format
    ncl convert_cesm_hybrid_nc_to_pressure_int.ncl  'CASE="'${CASE}'"' 'IM_root_name="'${IM_root_name}'"' 'outDIR="'${outDIR}'"'
  
  
  end
  @ doYY = $doYY + 1
end

