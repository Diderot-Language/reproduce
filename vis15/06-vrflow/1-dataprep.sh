#!/usr/bin/env bash
source ../0-common.sh

# figures looked better with some smoothing
unu resample -i $DDRO_EXAMPLES/data/sqflow-1608.nrrd -s = x1 x1 x1 -k gauss:1.3,4 -b wrap -o flow.nrrd


