#!/bin/csh -f 
#set echo

###########
# Remember to load the cdo module before running this code
###########

# We need daily sea ice and it is the only variabile not availalbe on glade at less than monthly timescale. So we have to download it from hpss.
# Note that these are all from ensemble member 6, but some have different numbers (012, 007, 006)


if ( ${#argv} < 2 ) then
  echo "Must at least specify the the case to run and the year on the command line"
  echo "  Available command line options are:"
  echo "  -c CASE (eg, -c 20THC). (Options are: 20THC, RCP85, RCP60, or RCP45)"
  echo "  -y YYYY (eg, -y 1980)"
  echo "  -m XX  (number of years to process) " 
  echo " "
  echo "  eg:  ./get_seaice.csh  -c 20THC -y 1980 -m 4"
  echo " "
  exit
endif


set CASE = "dummy"
set YYs = 0
set numYY = 0

while ( ${#argv} )
  set whichARG = ` echo $1 | cut -c2 `
  switch ($whichARG)
    case [c]:
      set CASE = $2
      breaksw
    case [y]:
      set YYs = $2
      breaksw
    case [m]:
      set numYY = $2 
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
  echo "  eg:  ./get_seaice.csh  -c 20THC -y 1980 -m 4"
  echo " "
  exit
endif

if ( $YYs == 0 ) then
  echo "Must at least specify the the case to run and the year on the command line"
  echo "  Available command line options are:"
  echo "  -c CASE (eg, -c 20THC). (Options are: 20THC, RCP85, RCP60, or RCP45)"
  echo "  -y YYYY (eg, -y 1980)"
  echo "  -m XX  (number of years to process) " 
  echo " "
  echo "  eg:  ./get_seaice.csh  -c 20THC -y 1980 -m 4"
  echo " "
  exit
endif

if ( $numYY > 0 ) then
  @ YYe = $YYs + $numYY - 1
else
  set YYe = $YYs
endif

echo "Processing SEAICE for $CASE for years $YYs to $YYe "

if ( $CASE == "20THC" ) then
  set period = "20thC"
  if ( $YYs > 2005 ) then
    echo " For the 20THC the start year must be less or equal to 2005"
    exit
  endif
  if ( $YYe > 2005 ) then
    echo " For the 20THC the end year must be less or equal to 2005"
    echo "   Resetting end year to 2005"
    echo " " 
    set YYe = 2005
  endif
else
  set clim_case = `echo $CASE | tr "[:upper:]" "[:lower:]"`
  set period = ` echo $clim_case | cut -c1-4 `_` echo $clim_case | cut -c5 `
  if ( $YYs < 2006 ) then
    echo " For the climate projections the start year must be greater or equal to 2006"
    echo "   Resetting start year to 2006"
    echo " " 
    set YYs = 2006
  endif
  if ( $YYe > 2100 ) then
    echo " For the climate projects the end year must be less or equal to 2100"
    echo "   Resetting end year to 2100"
    echo " " 
    set YYe = 2100
  endif
endif

set yyyy = $YYs
while ($yyyy <= $YYe)
  foreach mm (01 02 03 04 05 06 07 08 09 10 11 12) 

  echo " Working on " $yyyy $mm

  if (! -e ./${period}_sic_pct_${yyyy}-${mm}.nc ) then

    if ($period == "20thC") then
      hsi get /CCSM/csm/b40.20th.track1.1deg.012/ice/hist/b40.20th.track1.1deg.012.cice.h1.${yyyy}-${mm}.nc
      cdo selvar,aice_d b40.20th.track1.1deg.012.cice.h1.${yyyy}-${mm}.nc ./${period}_sic_pct_${yyyy}-${mm}.nc
      rm b40.20th.track1.1deg.012.cice.h1.${yyyy}-${mm}.nc
    endif
    
    if ($period == "rcp8_5") then
      hsi get /CCSM/csm/b40.${period}.1deg.007/ice/hist/b40.${period}.1deg.007.cice.h1.${yyyy}-${mm}.nc
      cdo selvar,aice_d b40.${period}.1deg.007.cice.h1.${yyyy}-${mm}.nc ./${period}_sic_pct_${yyyy}-${mm}.nc
      rm b40.${period}.1deg.007.cice.h1.${yyyy}-${mm}.nc
    endif
    
    if ($period == "rcp6_0") then
      hsi get /CCSM/csm/b40.${period}.1deg.006/ice/hist/b40.${period}.1deg.006.cice.h1.${yyyy}-${mm}.nc
      cdo selvar,aice_d b40.${period}.1deg.006.cice.h1.${yyyy}-${mm}.nc ./${period}_sic_pct_${yyyy}-${mm}.nc
      rm b40.${period}.1deg.006.cice.h1.${yyyy}-${mm}.nc
    endif
    
    if ($period == "rcp4_5") then
      hsi get /CCSM/csm/b40.${period}.1deg.006/ice/hist/b40.${period}.1deg.006.cice.h1.${yyyy}-${mm}.nc
      cdo selvar,aice_d b40.${period}.1deg.006.cice.h1.${yyyy}-${mm}.nc ./${period}_sic_pct_${yyyy}-${mm}.nc
      rm b40.${period}.1deg.006.cice.h1.${yyyy}-${mm}.nc
    endif
   
  endif
 
  end
  set yyyy = `expr $yyyy + 1`
 
end
