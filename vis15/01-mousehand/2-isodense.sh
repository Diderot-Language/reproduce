#!/usr/bin/env bash
source ../0-common.sh
source 0-common.sh

echo ==== diderotc isodense
diderotc --target=pthread --exec isodense.diderot
junk isodense{,.o,.cxx}

echo ==== running isodense
unu resample -i data/hand.nrrd -s x3 x4 |
unu grid -i - |
./isodense -ipos -
junk x.nrrd

ccompile ../epsdraw

# the "epsdraw" utility program takes a RGB color image to draw dots on,
# even though for this figure only a gray-scale image was used.  So we
# turn the grayscale C-c4hexic.png into a color tmp.png
unu axinsert -i C-c4hexic.png -a 0 -s 3 -o tmp.png
junk tmp.png

echo ==== drawdots
../epsdraw tmp.png x.nrrd $DOT_PARM > D-isodense.eps
junk D-isodense.eps

echo "==== epstopdf --> D-isodense.pdf"
cat D-isodense.eps | epstopdf --nocompress -f -o=D-isodense.pdf
