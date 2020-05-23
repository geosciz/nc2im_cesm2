#!/bin/bash

#BSUB -q cweg
#BSUB -J nc2im
#BSUB -m cn16
#BSUB -n 1
#BSUB -o /home/zhangc/bsub_logs/out
#BSUB -e /home/zhangc/bsub_logs/err

source activate python3
cd /home/zhangc/repositories/nc2im_cesm2/
python run.py
