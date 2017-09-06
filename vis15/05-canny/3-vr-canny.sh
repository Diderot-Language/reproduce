#!/usr/bin/env bash
source ../0-common.sh
source 0-common.sh

########## begin code transformations described in Section 4.1 of paper

# For Canny edges, need gradient min gmin, not isoval
oldInput='input real isoval;  input real thick;'
newInput='input real gmin;  input real thick;'

# Isocontouring Canny edge function, not field itself
oldField='field#4(3)[] F = V - isoval; // isosurface is {x|F(x)=0}'
newField='field#2(3)[] F = -∇(|∇V|) • ∇V/|∇V|;'

# Masking function uses gmin
oldMask='function real mask(vec3 x) = 1.0;'
newMask='function real mask(vec3 x) = 1.0 if (|∇V(x)| > gmin) else 0.0;'

echo == creating vr-canny.diderot
cat ../volrend.diderot \
    | perl -pe "s!\Q$oldInput\E!${newInput}!g" \
    | perl -pe "s!\Q$oldField\E!${newField}!g" \
    | perl -pe "s!\Q$oldMask\E!${newMask}!g" > vr-canny.diderot

########## end code transformations

echo == diderotc vr-canny.diderot
diderotc --exec --target=pthread vr-canny.diderot
junk vr-canny{.diderot,.o,.cxx,}

echo == running vr-canny
./vr-canny $CAM_PARM $STEP_PARM -gmin 5
overrgb -i rgba.nrrd -b $SPHERE_BKGD -g srgb -srgb perc -o D-vr-canny.png
junk rgba.nrrd
