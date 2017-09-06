#!/usr/bin/env bash
source ../0-common.sh

# The NAMIC project https://na-mic.org has made a number of
# high-quality DWMRI datasets available, which are helpfully already
# in NRRD format. At this page:
# <http://hdl.handle.net/1926/1687> scroll down
# to "case01026", and click on the link in "Download this study: All
# the data" (there's no specific URL for this), which generates and
# downloads case01026.zip.  Then, unzip that file to create the
# directory case01026

CASE=01026
if [[ ! -d case$CASE ]]; then
    echo "$0: sorry, need to read steps at start of $0 to create case$CASE directory"
    exit 1
fi

cd case$CASE # this will fail if the steps above haven't been followed

export NRRD_STATE_DISABLE_CONTENT=true # otherwise "content:" gets crazy long

# This estimates diffusion tensors from DW-MRI, and creates a confidence mask
# by thresholding (at a value determined automatically) the mean of all
# diffusion-weighted images (so it is only high where the diffusion-weighted
# signal remains; i.e. inside parenchyma).
echo === tend estim
tend estim -i $CASE-dwi-filt-Ed.nhdr -B kvp -knownB0 true -o ten.nrrd
junk ten.nrrd

# There is a fair amount of space around the brain that can be cropped out to
# make a smaller dataset; we can use "unu acrop" to discover this automatically
# Cropping could be more aggressive but we need some space to help with later
# cleanup based on distance transforms
echo === cropping
unu slice -i ten.nrrd -a 0 -p 0 | # slice out the confidence mask
unu project -a 2 -m mean | # average along Z to get XY image
unu acrop -m stdv -f 0.01 -off 13 -b mm.txt -o /dev/null # want bounds, not output
junk mm.txt
XYMIN=$(unu slice -i mm.txt -a 1 -p 0 | unu save -f text)
XYMAX=$(unu slice -i mm.txt -a 1 -p 1 | unu save -f text)
unu crop -i ten.nrrd -min 0 $XYMIN 0 -max M $XYMAX M -o ten-crop.nrrd

echo === initial mask
# The confidence mask itself is not geometrically or anatomically ideal, so
# first we clean it up with a mix of connected-component (CC) analysis and
# morphological operations. The goal of this is not actually to get a mask
# that only contains parenchyma, but only the (higher anisotropy) white
# matter which is the target of the visualization
unu slice -i ten-crop.nrrd -a 0 -p 0 | # slice out mask
unu quantize -b 8 -o m0.nrrd  # don't need floating point representation
unu tile -i m0.nrrd -a 2 0 1 -s 17 5 -o m0.png

echo === morphological shrink a bit
IN=m0; OUT=m1
PAD=10
unu pad -i $IN.nrrd -min 0 0 -$PAD -max M M M+$PAD -b pad -v 0 | # pad
unu dist -th 0 -sgn | # distance transform
unu 2op lt - -1 | # shrink by a bit
unu crop -min 0 0 $PAD -max M M M-$PAD | # unpad
unu quantize -b 8 -o $OUT.nrrd
unu tile -i $OUT.nrrd -a 2 0 1 -s 17 5 -o $OUT.png

echo === connected-components
# make connected-components and remove small components
IN=m1; OUT=m2
unu ccfind -i $IN.nrrd -v vals.nrrd -c 1 | # find CCs
unu ccmerge -s 3000 -c 1 -revalue -v vals.nrrd -o $OUT.nrrd # drop small CCs
unu tile -i $OUT.nrrd -a 2 0 1 -s 17 5 -o $OUT.png
junk vals.nrrd

echo === morphological operations
# grow, shrink, grow. need padding so that top of bottom of brain handled
# correctly
IN=m2; OUT=m3
PAD=10
unu pad -i $IN.nrrd -min 0 0 -$PAD -max M M M+$PAD -b pad -v 0 | # pad
unu dist -th 0 -sgn | # distance transform
unu 2op lt - 3 | # grow
unu dist -th 0 -sgn | unu 2op lt - -6 | # shrink
unu dist -th 0 -sgn | unu 2op lt - 4 | # grow
unu crop -min 0 0 $PAD -max M M M-$PAD | # unpad
unu quantize -b 8 -o $OUT.nrrd
unu tile -i $OUT.nrrd -a 2 0 1 -s 17 5 -o $OUT.png

echo === connected-components again
IN=m3; OUT=m4
unu ccfind -i $IN.nrrd -v vals.nrrd -c 1 | # find CCs
unu ccmerge -s 3000 -c 1 -revalue -v vals.nrrd -o $OUT.nrrd # drop small CCs
unu tile -i $OUT.nrrd -a 2 0 1 -s 17 5 -o $OUT.png

echo === making mask
IN=m4; OUT=newmask
# turn binary mask into soft thresholding image
unu pad -i $IN.nrrd -min 0 0 -$PAD -max M M M+$PAD -b pad -v 0 | # pad
unu dist -th 0 -sgn |
unu resample -s x1 x1 x1 -k bspln3 | # try to blur out aliasing on surface
unu 2op x - -1. | # tighten edge a tiny bit, and fix sign
unu 1op erf | # soft threshold
unu crop -min 0 0 $PAD -max M M M-$PAD |
unu affine -1 - 1 0 1 -o $OUT.nrrd
unu tile -i $OUT.nrrd -a 2 0 1 -s 17 5 | unu quantize -b 8 -o $OUT.png

echo === lerping with water tank
# Diderot doesn't actually know anything about confidence masks, so we
# transform the tensor field to simulate the brain being out of a
# skull, and suspended in water.  This means there are valid tensors
# everywhere, but anisotropy only inside the brain.  First we create a
# tensor field simulating an empty tank of water.
SZ=($(unu head ten-crop.nrrd | grep sizes | cut -d' ' -f 3,4,5))
DD=0.0032
echo "1 $DD 0 0 $DD 0 $DD" | # isotropic diffusivity
unu reshape -s 7 1 1 1 |
unu pad -min 0 0 0 0 -max M $((${SZ[0]}-1)) $((${SZ[1]}-1)) $((${SZ[2]}-1)) -b bleed |
unu inset -i ten-crop.nrrd -s - -min 0 0 0 0 -o tank.nrrd
junk tank.nrrd

# do the lerp between brain and tank,
# also clamp eigenvalues to values plausible for parynchyma
unu axinsert -i newmask.nrrd -a 0 -s 7 |
unu 3op lerp - tank.nrrd ten-crop.nrrd -w 2 |
tend evalclamp -min 0.00019 -max $DD -o brain.nrrd

echo === final prepping
# ensure that the confidence mask is all 1's
# and convert to 9-component tensor
unu slice -i tank.nrrd -a 0 -p 0 |
unu splice -i brain.nrrd -s - -a 0 -p 0 |
tend expand -unmf -o - |
unu dnorm -o ../brain-ten9.nrrd
