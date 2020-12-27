#!/bin/bash

REDUCTION=$1
if [ -z "$1" ] ; then
    REDUCTION=0
fi

make clean
make $(echo REDUCTION=$REDUCTION)
sbatch submit-cuda.sh
