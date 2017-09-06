#!/usr/bin/env bash
source ../0-common.sh

# For some of these image we want to use Diderot to view the
# field created by convolution, which is the purpose of bkgimg.diderot
# For comparison we also want to see the underlying image,
# with the same field of view, but since currently Diderot doesn't have any odd-support kernels
# (including nearest-neighbor), we have to upsample a bunch
# and then convolve with tent
echo '=== upsampling to approximate "box" kernel'
unu resample -i data/hand.nrrd -s x1 x1 -k c4hexic |
unu resample -s x234 x234 -k box -o hand-upbox.nrrd
junk hand-upbox.nrrd

echo === diderotc bkgimg
diderotc --exec bkgimg.diderot
junk bkgimg{,.o,.cxx}

PARM="-cent 61 40.7 -hght 53 -size0 1010 -size1 590"
GAM=1.4


echo === bkgimg c4hexic
./bkgimg -what c4hexic -img data/hand.nrrd $PARM -o vv.nrrd &> vv.nhdr
unu quantize -i vv.nhdr -b 8 -min 4% -max 0.1% | unu gamma -g $GAM | unu swap -a 0 1 | unu flip -a 0 -o C-c4hexic.png
# so next image can be quantize to 8-big gray in the same way
MIN=$(unu save -f nrrd -i C-c4hexic.png | unu head - | grep "old min:" | cut -d' ' -f 3)
MAX=$(unu save -f nrrd -i C-c4hexic.png | unu head - | grep "old max:" | cut -d' ' -f 3)

echo === bkgimg tent
./bkgimg -what tent -img hand-upbox.nrrd $PARM -o vv.nrrd &> vv.nhdr
unu quantize -i vv.nhdr -b 8 -min $MIN -max $MAX | unu gamma -g $GAM | unu swap -a 0 1 | unu flip -a 0 -o A-upbox.png

echo === bkgimg thresh
./bkgimg -what thresh -img hand-upbox.nrrd $PARM -o vv.nrrd &> vv.nhdr
unu quantize -i vv.nhdr -b 8 | unu gamma -g $GAM | unu swap -a 0 1 | unu flip -a 0 -o B-thresh.png

junk vv.{nhdr,nrrd}
