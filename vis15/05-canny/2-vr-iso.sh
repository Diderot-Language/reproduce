#!/usr/bin/env bash
source ../0-common.sh
source 0-common.sh

# published program can be used as is for isosurfaces
echo === diderotc vr-iso.diderot
cp ../volrend.diderot vr-iso.diderot
diderotc --exec --target=pthread vr-iso.diderot
junk vr-iso{.diderot,.o,.cxx,}

NN=9
for ISOIDX in $(seq -w 0 1 $NN); do
    ISO=$(unu affine 0 $ISOIDX $NN -3.5 2.5)
    echo -n "running ./vr-iso -isoval $ISO ($ISOIDX/$NN) ... "
    ./vr-iso -isoval $ISO $CAM_PARM $STEP_PARM
    echo "done"
    overrgb -i rgba.nrrd -b $SPHERE_BKGD -g srgb -srgb perc -o C-vr-iso-$ISOIDX.png
done
junk rgba.nrrd
