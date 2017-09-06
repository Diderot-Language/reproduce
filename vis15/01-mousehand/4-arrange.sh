#!/usr/bin/env bash
source ../0-common.sh
source 0-common.sh

for PDF in D-isodense E-isoptcl; do
     # should make image same size as other
    echo "==== convert $PDF.pdf --> $PDF-rast.png"
    convert -density 100 $PDF.pdf PNG:- | unu crop -min 0 2 0 -max 2 M M -o $PDF-rast.png
    junk $PDF-rast.png
done

for GRAY in A-upbox B-thresh C-c4hexic; do
    echo "==== $GRAY.png --> $GRAY-rgb.png"
    unu axinsert -i $GRAY.png -a 0 -s 3 -o $GRAY-rgb.png
    junk $GRAY-rgb.png
done

# arranging results side-by-side; This was done by LaTeX in the paper; this is
# just a self-contained visual approximation
MARG=10
unu join -i {A-upbox,B-thresh,C-c4hexic}-rgb.png {D-isodense,E-isoptcl}-rast.png -a 3 |
unu pad -min 0 0 0 0 -max M M+$MARG M+$MARG M -b pad -v 255 |
unu tile -a 3 1 2 -s 5 1 |
unu pad -min 0 -$MARG -$MARG -max M M M -b pad -v 255 -o Figure01.png

unu resample -i Figure01.png -s = 800 a -o Figure01-sm.png
