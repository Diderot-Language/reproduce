#!/bin/bash
source ../0-common.sh

diderotc --exec --target=pthread lic2d.diderot
junk lic2d{,.o,.cxx}

# Set up sampling of a 2-sample cropping of the vector image (cropping
# to stay within locations where field reconstruction with bspln3 is
# always possible). There is unfortunately no simple way to tell
# Diderot "sample the whole domain of this image", so for now we do
# some unu hacking to set that up.

unu crop -i turb2d.nrrd -min 0 2 2 -max M M-2 M-2 -o crop.nrrd
junk crop.nrrd
# size along X and Y
SZXY=($(unu head crop.nrrd | grep sizes: | cut -d' ' -f 3,4))
SZX=${SZXY[0]}
SZY=${SZXY[1]}
# spacings along X and Y
SPXY=($(unu unorient -i crop.nrrd | unu head - | grep spacings: | cut -d' ' -f 3,4))
SPX=${SPXY[0]}
SPY=${SPXY[1]}
# lower bounds on X and Y
MINXY=($(unu unorient -i crop.nrrd -smfo | unu head - | grep "axis mins:" | cut -d' ' -f 4,5))
MINX=$(echo ${MINXY[0]} - $SPX/2 | bc -l)
MINY=$(echo ${MINXY[1]} - $SPY/2 | bc -l)
# upper bounds on X and Y
MAXXY=($(unu flip -i crop.nrrd -a 1 | unu flip -a 2 | unu unorient -i - -smfo | unu head - | grep "axis mins:" | cut -d' ' -f 4,5))
MAXX=$(echo ${MAXXY[0]} + $SPX/2 | bc -l)
MAXY=$(echo ${MAXXY[1]} + $SPY/2 | bc -l)
# NOTE that the Y bounds are given as "-ymm $MAXY $MINY" below so that
# the resulting image, with normal raster display, will be shown with
# Y increasing upwards

# The top TOPV percent of velocities have maximal contrast
TOPV=12
VMAX=$(unu project -i turb2d.nrrd -a 0 -m l2 | unu quantize -b 8 -min 0 -max ${TOPV}% | unu head - | grep "old max:" | cut -d' ' -f 3)

MAGN=3  # magnification of vector image size to LIC image size
OV=2    # oversampling (for anti-aliasing)
RSS=($(unu unorient -i rand.nrrd | unu head - | grep spacings: | cut -d' ' -f 2))
./lic2d -img turb2d.nrrd -sizeX $((SZX*MAGN*OV)) -sizeY $((SZY*MAGN*OV)) \
  -xmm $MINX $MAXX -ymm $MAXY $MINY \
  -h0 0.008 -stepNum 50 -velomax $VMAX -vortmax 30 -rss $RSS
#junk rgb.nrrd
unu project -i rgb.nrrd -a 1 -m mean | # combine up,downstream path results
unu resample -s = /$OV /$OV |
unu 3op clamp 0 - 1 |
unu quantize -b 8 -min 0 -max 1 -g 1.2 |
unu axinfo -a 1 -c cell -mm $MINX $MAXX | # re-assert orientation
unu axinfo -a 2 -c cell -mm $MAXY $MINY |
unu dnorm -o lic2d.png
