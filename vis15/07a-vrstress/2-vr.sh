#!/usr/bin/env bash
source ../0-common.sh

# copy colormap; this is a more principled (hence slightly different)
# version of what was used for the paper
cp ../00-cmap/by-cmap.nrrd cmap.nrrd
junk cmap.nrrd

# The lower-resolution dataset used for the VIS'15 paper was missing
# its original orientation meta-data (GLK's fault), so the camera
# set-up used for that figure (Figure 7a) is not valid for the newer
# dpl-256-ten9.nrrd data with correct orientation information.  The
# camera used here is a good approximation of was used in the paper.
CAM_PARM="-camEye -82.2766 97.3379 67.6803
-camAt 0 0 -5.5
-camUp 0 0 1
-camNear 120 -camFar 174
-camFOV 9
-iresU 900
-iresV 570
-phongKa 0.3
-phongKd 0.7
-lightVsp 2 -3.5 4"

STEP_PARM="-rayStep 0.01 -refStep 0.05 -thick 0.02"

########## begin code transformations described in Section 4.1 of paper
# (many copied from ../06-flow/2-vr-all.sh)

# (not explicitly mentioned in the paper text) Changing isoval to two
# values, and moving it from the field definition to the opacity function,
# so that two isosurfaces can be shown
oldIsoval='input real isoval;  input real thick;'
newIsoval='input vec2 isoval;  input real thick;'
oldAlpha='  = clamp(0, 1, 1.3*(1 - |v|/(g*thick)));'
newAlpha='  = max(clamp(0, 1, 1.0*(1 - |v-isoval[0]|/(g*thick))),
        clamp(0, 1, 1.0*(1 - |v-isoval[1]|/(g*thick))));'

# working from 3D tensor field instead of 3D scalar field
oldData='field#4(3)[] V = bspln5 ⊛ image("vol.nrrd");'
newData='field#4(3)[3,3] V = c4hexic ⊛ image("dpl-256-ten9.nrrd");'

# rendering the tensor mode
oldField='field#4(3)[] F = V - isoval; // isosurface is {x|F(x)=0}'
newField='field#4(3)[3,3] E = V - trace(V)*identity[3]/3;
field#4(3)[] F = 3*sqrt(6)*det(E/|E|);'

# the colormap is also of tensor mode.
oldCmap='function vec3 color(vec3 x) = cmap(V(x));'
newCmap='function vec3 color(vec3 x) = cmap(F(x));'

# two-sided lighting
oldShade='real shade = max(0, normalize(grad)•light);'
newShade='real shade = |normalize(grad)•light|;'

# adding basic progress indication
oldUpdate='  update {'
newUpdate='  update {
    if (ui==0 && rayN == camNear) print("row ", vi, "/", iresV, "\\n");'

echo === creating vr-mode.diderot
cat ../volrend.diderot \
    | perl -pe "s!\Q$oldIsoval\E!${newIsoval}!g" \
    | perl -pe "s!\Q$oldData\E!${newData}!g" \
    | perl -pe "s!\Q$oldField\E!${newField}!g" \
    | perl -pe "s!\Q$oldCmap\E!${newCmap}!g" \
    | perl -pe "s!\Q$oldAlpha\E!${newAlpha}!g" \
    | perl -pe "s!\Q$oldUpdate\E!${newUpdate}!g" \
    | perl -pe "s!\Q$oldShade\E!${newShade}!g" \
    > vr-mode.diderot
# junk vr-mode.diderot

########## end code transformations

echo === diderotc vr-mode.diderot
# Currently the magnitude of the difference in quality from compiling
# with --double may be surprising.  GLK is interested in improving
# the numerical accuracy of Diderot's floating-point code generation.
diderotc --exec --target=pthread --double vr-mode.diderot
junk vr-mode{,.o,.cxx,}

echo === running vr-mode
./vr-mode $CAM_PARM $STEP_PARM -isoval -1 1
overrgb -i rgba.nrrd -b 1 1 1 -g srgb -srgb perc -o Figure07a.png
# junk rgba.nrrd

unu resample -i Figure07a.png -s = 400 a -o Figure07a-sm.png
