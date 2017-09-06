#!/bin/bash
source ../0-common.sh

function usage {
    echo "Computes a C2 constant-speed colormap through LAB space." >&2
    echo "usage:" >&2
    echo "  $0 lab.txt out" >&2
    echo "where lab.txt is a 3-line text file, one LAB color per line" >&2
    echo "and program will generate out.nrrd colormap and out.png image." >&2
    exit 1
}

if [ "$#" -ne 2 ]; then
    echo "$0: wrong number of parameters" >&2
    usage
fi

LAB=$1
OUT=$2

# create initial trivial (constant-speed) "warp", with lots of
# padding to anticipate differencing for velocity computation
echo "-1 3" | unu reshape -s 2 | unu resample -s 100 -k tent -c node |
unu axinfo -a 0 -mm -1 3 | unu dnorm -o warp.nrrd
junk warp.nrrd

echo "=== initial compile"
diderotc --double --exec labparab.ddro
junk labparab{,.o,.cxx}

echo "=== measuring speed"
# record speed (without domain warping) of parabola between control
# points in LAB space
./labparab -LAB $LAB -velo true -dstep 1 -o velo.nrrd
junk velo.nrrd
SZ=$(unu head velo.nrrd | grep sizes | cut -d' ' -f 3)
unu project -i velo.nrrd -a 0 -m l2 -o speed.nrrd
junk speed.nrrd

# generate array of partial sums
echo 0 -1 1 0 | unu reshape -s 2 2 |
unu resample -s $SZ $SZ -k tent -c node |
unu 2op gte - 0 -o mask.nrrd
junk mask.nrrd

echo "=== finding constant-speed reparameterization"
# oversampling needed because this unu hacking recovers the inverse
# of a function by playing games with an image of its plot, a method
# that is surprisingly sensitive to the resolution of the image
OV=17  # oversampling factor
unu axinsert -i speed.nrrd -a 1 -s $SZ | # $SZ copies of speed along slow axis
unu 2op x - mask.nrrd | # multiply by partial sum mask
unu project -a 0 -m sum | # get array of partial sums
unu resample -s x$OV -k tent | # oversample
unu dhisto -h $((SZ*OV)) -nolog | # plot distance vs t
unu flip -a 1 | unu swap -a 0 1 | unu 2op - 255 - | # now (flipped) plot of t vs distance
unu project -a 1 -m histo-max | unu 2op exists - 0 | # recover t(distance)
unu 2op / - $((SZ*OV-1)) | unu 2op x - 2 | # now maps *to* [0,2]
unu axinfo -a 0 -mm 0 2 | # now maps *from* [0,2]
unu resample -s /$OV -k gauss:1.5,3  | # undo oversampling
unu pad -min -10 -max M+10 -b bleed | # add back some padding
unu dnorm -o warp.nrrd
# (the last resample is where we especially wish we had a proper
# boundary-value-preserving nrrdBoundary behavior)

echo "=== recompiling and running"
# recompile (due to new warp.nrrd size) and re-run
diderotc --double --exec labparab.ddro
./labparab -LAB $LAB
junk rgb.nrrd

## for debugging warping
#./labparab -LAB $LAB -velo true -o velo2.nrrd
#unu project -i velo2.nrrd -a 0 -m l2 -o speed2.nrrd

unu 3op clamp 0 rgb.nrrd 1 |
unu axinfo -a 1 -mm -1 1 |
unu pad -min 0 -5 -max M M+5 -b bleed |
unu dnorm -o $OUT.nrrd

echo "=== making image of colormap"
# make image of colormap
unu crop -i $OUT.nrrd -min 0 5 -max M M-5 |
unu axinsert -a 2 -s 40 |
unu gamma -g srgb -min 0 -max 1 |
unu quantize -b 8 -min 0 -max 1 -srgb abs -o $OUT.png
