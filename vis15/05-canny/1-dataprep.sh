#!/usr/bin/env bash
source ../0-common.sh

echo === making canny.nrrd
if [[ ! -x $DDRO_EXAMPLES/fs3d/fs3d-scl ]]; then
  echo "$0: sorry have to first compile the \$DDRO_EXAMPLES/fs3d/fs3d-scl program;"
  echo "$0: it is used to generate the dataset to render"
fi
$DDRO_EXAMPLES/fs3d/fs3d-scl -which rsphere -sz0 60 -sz1 60 -sz2 60 &> out.nhdr
junk out.{nrrd,nhdr}
unu save -f nrrd -i out.nhdr -o vol.nrrd

echo === making A-canny-slice.png
unu slice -i vol.nrrd -a 1 -p 30 \
    | unu resample -s x8 x8 -k box \
    | unu quantize -b 8 -o A-canny-slice.png

echo === making cmap.nrrd and B-cmap.png
# For the paper talk, a different colormap (of unknown provenance) was used
# This uses different colors but the effect is the same
unu crop -i $DDRO_EXAMPLES/cmap/isobow.nrrd -min 0 50 -max M M | # avoid green at beginning
unu flip -a 1 | # change order
unu unorient -i - | # loose existing orientation
unu axinfo -a 1 -mm -3.6 2.6 | # isosurfaces taken from -3.5 to 2.5
unu dnorm -o cmap.nrrd

unu axinsert -i cmap.nrrd -a 2 -s 30 |
unu quantize -b 8 -min 0 -max 1 -g srgb -srgb perc -o B-cmap.png
