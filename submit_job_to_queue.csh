#!/bin/csh
#
## LSF script to run an OMP code
#
#BSUB -P P99999999                      # Project 99999999
#BSUB -a poe                            # select poe
#BSUB -n 1                              # number of total (MPI) tasks
#BSUB -R "span[ptile=1]"                # run a max of 32 tasks per node
#BSUB -J cesmjob                        # job name
#BSUB -o %J.out                         # output filename
#BSUB -e %J.err                         # error filename
#BSUB -W 24:00                          # wallclock time
#BSUB -q geyser                         # queue


#  Must at least specify the the case to run and the year on the command line
#    Available command line options are:
#    -c CASE (eg, -c 20THC). (Options are: 20THC, RCP85, RCP60, or RCP45) - Required
#    -y YYYY (eg, -y 1980) - Required
#    -m XX  (number of years to process) - Optional
#    -f FILENAME (IM root name to use). The case used will be appending to the root name - Optional setting
#    -o DIRECTORY (output directory) - Optional
#  
#    eg:  ./process_cesm_data.csh  -c 20THC -y1980 -m 4
#    eg:  ./process_cesm_data.csh  -c 20THC -y1980 -m 4 -f myROOTNAMES -o myOUTDIR
# 

./process_cesm_data.csh -c 20THC -y 1999 -m 1 -o /glade/scratch/UserX/CESM_OUTPUT

