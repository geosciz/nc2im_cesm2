#!/bin/bash

#BSUB -q cweg
#BSUB -J run_test
#BSUB -m cn16
#BSUB -n 1
#BSUB -o /home/zhangc/bsub_logs/out
#BSUB -e /home/zhangc/bsub_logs/err

cd /home/zhangc/repositories/nc2im_cesm2/

source activate python3

python run.py
