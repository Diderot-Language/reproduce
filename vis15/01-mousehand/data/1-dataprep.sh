#!/bin/bash
set -o errexit
set -o nounset
shopt -s expand_aliases
JUNK=""
function junk { JUNK="$JUNK $@"; }
function cleanup { rm -rf $JUNK; }
trap cleanup err exit int term

# Data came from http://www.sci.utah.edu/cibc-software/ctdata.html
# http://www.sci.utah.edu/cibc-software/ctdata.html
# http://www-rev.sci.utah.edu/cgi-bin/CTdatasets.pl?id=hox-wt-2005050903-hand
# Data acknowledgement: University of Utah SCI group, NIH NIGMS grant P41 GM103545-18

if [[ ! -f hox-wt-20050509-03-hand.vff ]]; then
    curl -O http://www-rev.sci.utah.edu/datasets/CTarchive/hox-wt-2005050903-hand/hox-wt-20050509-03-hand.vff
fi
if [[ ! -f hox-wt-20050509-03-hand.nhdr ]]; then
    curl -O http://www-rev.sci.utah.edu/datasets/CTarchive/hox-wt-2005050903-hand/hox-wt-20050509-03-hand.nhdr
fi

echo === making pre-mask.png
unu resample -i hox-wt-20050509-03-hand.nhdr -s /2 /2 30 -k box \
    | unu pad -min -20 -20 0 -max M+20 M+20 M -b pad -v 0 \
    | unu tile -a 2 0 1 -s 3 10 \
    | unu quantize -b 8 -min 1% -max 1% \
    | unu axinsert -a 0 -s 3 -o pre-mask.png
junk pre-mask.png # comment out if interested;
# GLK used GIMP to make post-mask.png out of pre-mask.png

echo === making lerp.nrrd
unu project -i post-mask.png -a 0 -m var \
    | unu quantize -b 8 \
    | unu unquantize -i - -min 0 -max 1 \
    | unu untile -a 2 0 1 -s 3 10 \
    | unu crop -min 20 20 0 -max M-20 M-20 M \
    | unu resample -s 460 175 460 -k tent \
    | unu 1op rup \
    | unu convert -t uchar -o lerp.nrrd
junk lerp.nrrd

echo === making muhand.nrrd
unu 2op min 9100 hox-wt-20050509-03-hand.nhdr \
    | unu 3op lerp lerp.nrrd hox-wt-20050509-03-hand.nhdr - -w 1 \
    | unu resample -s /2 /2 /2 \
    | unu dnorm -i - -o - \
    | unu axinfo -a 0 1 2 -c cell \
    | unu basinfo -spc LPS -o muhand.nrrd

## cleanup big files:
#rm -f hox-wt-20050509-03-hand.{vff,nhdr}
