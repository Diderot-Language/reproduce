#!/bin/bash
set -o errexit
set -o nounset
shopt -s expand_aliases
JUNK=""
function junk { JUNK="$JUNK $@"; }
function cleanup { rm -rf $JUNK; }
trap cleanup err exit int term

export NRRD_STATE_DISABLE_CONTENT=true

# This projection of the muhand.nrrd volume is not exactly the same as
# what was used in the paper; that projection was done with some older
# (non-Diderot) code, which was found to have a bug in how it set up
# the view transform.  The camera parameters below are pretty good at
# replicating the view created by the buggy code.

SZ0=665
SZ1=423
CAM="-camEye 621.556 706.266 -1.98783 -camAt 291.986 137.546 192.702 -camUp -0.647513 0.554265 0.522989 -camNear -59.3282 -camFar 70 -camFOV 28 -iresU 665 -iresV 423"

diderotc --exec --target=pthread sumproj.diderot
junk sumproj{,.o,.cxx}

THR=8000

# summation projection of original data
./sumproj $CAM -o sum.nrrd
# clamp values threshold above bone, then sum project
unu 2op min muhand.nrrd $THR \
    | ./sumproj -vol - $CAM -o sum-th.nrrd
junk sum.nrrd sum-th.nrrd
# so now the difference between the projections is the
# projection of difference (the bone)

# remap intensities into (inside) a predictable range [-1,1]
zero=270000
marg=950000
unu 2op - sum.nrrd sum-th.nrrd \
    | unu axdelete -a -1 \
    | unu affine $[$zero-$marg] - $[$zero+$marg] -1 1 -clamp true \
    | unu unorient -i - \
    | unu axinfo -a 0 1 -sp 0.2 \
    | unu dnorm -o sum-hand.nrrd
junk sum-hand.nrrd

# downsample a lot, to make lower resolution that helps demonstrate
# the value of convolution-based field reconstruction
unu resample -i sum-hand.nrrd -s /8.5 /8.5  -k ctmr -o sumhnd.nrrd
junk sumhnd.nrrd

# add a very slight ramp to image, to help isocontours do a better job
# of uniformly showing fingers (originally darker) and wrist (brighter)
NN=$(unu head sumhnd.nrrd | grep sizes | cut -d\  -f 2)
echo "0.1 -0.08" | unu reshape -s 2 | unu resample -s $NN -k tent -c node |
unu gamma -g 0.7 |
unu 2op + sumhnd.nrrd - -o sumhnd.nrrd

# pad out the image borders, which was more important for an earlier
# version of compiler with less robust border control.  Also tweak
# intensity so that isosurface 0.0 looks better.
PAD=10
unu 2op + sumhnd.nrrd -0.07 | unu pad -min -$PAD -$PAD -max M+$PAD M+$PAD -b pad -v -1 -o hand.nrrd
