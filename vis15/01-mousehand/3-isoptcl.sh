#!/usr/bin/env bash
source ../0-common.sh
source 0-common.sh

# since published program used "hand.nrrd" without any other path
cp data/hand.nrrd .
junk hand.nrrd

echo ==== diderotc isoptcl
diderotc --exec isoptcl.diderot
junk isoptcl{,.o,.cxx}

# to get the array of positions covered by previous images
unu flip -i C-c4hexic.png -a 0 | unu swap -a 0 1 | unu grid -i - -o ipos.nrrd
junk ipos.nrrd
XYMIN=($(unu slice -i ipos.nrrd -a 1 -p 0 | unu save -f text))
XYMAX=($(unu slice -i ipos.nrrd -a 1 -p M | unu save -f text))
XYMM="-xmin ${XYMIN[0]} -ymin ${XYMIN[1]} -xmax ${XYMAX[0]} -ymax ${XYMAX[1]}"

echo ==== running particle system
./isoptcl -radius 1.45 -epsilon 0.001 -res 20 -isoval 0 $XYMM
junk pos.nrrd

## if the program was compiled with "--snapshot" and run with "-s 1",
## this could be used to make images of the computation progress
#for PIIN in pos-????.nrrd; do
#   IIN=${PIIN#*-}; II=${IIN%.*}
#   echo $PIIN $II
#   unu jhisto -i $PIIN -b 1010 590 -min ${XYMIN[0]} ${XYMIN[1]} -max ${XYMAX[0]} ${XYMAX[1]} |
#   unu quantize -b 8 -min 0 -max 2 -o pos-$II.png
#done

ccompile ../epsdraw

unu axinsert -i C-c4hexic.png -a 0 -s 3 -o tmp.png
junk tmp.png
echo ==== epsdraw dots
../epsdraw tmp.png pos.nrrd $DOT_PARM > E-isoptcl.eps
junk E-isoptcl.eps

echo "==== epstopdf --> E-isoptcl.pdf"
cat E-isoptcl.eps | epstopdf --nocompress -f -o=E-isoptcl.pdf
