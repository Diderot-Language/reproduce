#!/usr/bin/env bash
source ../0-common.sh

# This is a different camera than used for the paper because this
# is a different dataset (see 1-dataprep.sh)
CAM_PARM="-camEye 650.112 -11.3716 30.9776
-camAt -29.7095 0.415702 4.53978
-camUp -0.0390023 -0.00830387 0.999205
-camNear 649.5 -camFar 710
-camFOV 11
-iresU 780
-iresV 555
-phongKa 0.2
-phongKd 0.8
-lightVsp 2 3 -3"

STEP_PARM="-rayStep 0.04 -refStep 0.2 -thick 0.15"

########## begin code transformations described in Section 4.1 of paper
# (many copied from ../06-flow/2-vr-all.sh)

# working from 3D tensor field instead of 3D scalar field
oldData='field#4(3)[] V = bspln5 ⊛ image("vol.nrrd");'
newData='field#2(3)[3,3] V = bspln3 ⊛ image("brain-ten9.nrrd");'

# Not noted in paper: instead of making the only isosurface opaque (a
# surface), we make everything above the isovalue opaque (a region), so that
# we get opacity inside the white matter clipped by the near clip plane.
# This is handled by the *first* conditional expression in newAlpha.  Also,
# we have to handle the fact that in the constant "water" around the brain,
# FA will be constant, but its gradient can either be [inf,inf,inf] or
# [nan,nan,nan] due to unresolved numerical issues. Currently there is no
# good way of detecting non-finite values of scalars or tensors in Diderot,
# so we resort to setting opacity to 0 whenever the value is so low (below
# half the FA isovalue) that it can't possibly be part of the isosurface to
# show.  This is handled by the *second* conditional expression in newAlpha.
oldAlpha='  = clamp(0, 1, 1.3*(1 - |v|/(g*thick)));'
newAlpha='  = 1 if (v > 0) else (0 if v < -isoval/2 else clamp(0, 1, 1.3*(1 - |v|/(g*thick))));'

# Rendering the diffusion tensor FA
oldField='field#4(3)[] F = V - isoval; // isosurface is {x|F(x)=0}'
newField='field#2(3)[3,3] E = V - trace(V)*identity[3]/3;
field#2(3)[] F = sqrt(3.0/2.0)*|E|/|V| - isoval;'

# The colormap is of orientation of the principle eigenvector (and there is
# no need for the cmap.nrrd, so its use is removed with 'grep -v'). The color
# function in the paper neglected to include the bit of desaturation (via the
# lerp) that makes the result less garish.
oldCmap='function vec3 color(vec3 x) = cmap(V(x));'
newCmap='function vec3 color(vec3 x) {
  real{3} ev = evals(V(x));
  vec3 dir = evecs(V(x)){0};
  real CL = (ev{0} - ev{1})/ev{0};
//  return lerp([1,1,1], [|dir[0]|,|dir[1]|,|dir[2]|]*CL, 0.85);
  return [|dir[0]|,|dir[1]|,|dir[2]|]*CL;
}'

# adding basic progress indication
oldUpdate='  update {'
newUpdate='  update {
    if (ui==0 && rayN == camNear) print("row ", vi, "/", iresV, "\\n");'

# Not noted in paper: we want to turn off shading on the near clip plane in
# order to create a flat coloring (shading inside a fully opaque region
# doesn't make sense), and we also desaturate the RGB(evec) colorscheme away
# from the clip plane
oldShade='real shade = max(0, normalize(grad)•light);'
newShade='real shade = 0.4 if rayN-camNear < refStep else max(0, normalize(grad)•light);'
oldRGBincr='rgb += transp*a*depth*(phongKa + phongKd*shade)*color(x);'
newRGBincr='rgb += transp*a*depth*(phongKa + phongKd*shade)*lerp(color(x),[1,1,1],clerp(0,0.15,0,rayN-camNear,refStep));'

echo === creating vr-dti.diderot
cat ../volrend.diderot \
    | perl -pe "s!\Q$oldData\E!${newData}!g" \
    | perl -pe "s!\Q$oldField\E!${newField}!g" \
    | perl -pe "s!\Q$oldAlpha\E!${newAlpha}!g" \
    | grep -F -v 'field#0(1)[3] cmap = tent' \
    | perl -pe "s!\Q$oldCmap\E!${newCmap}!g" \
    | perl -pe "s!\Q$oldUpdate\E!${newUpdate}!g" \
    | perl -pe "s!\Q$oldShade\E!${newShade}!g" \
    | perl -pe "s!\Q$oldRGBincr\E!${newRGBincr}!g" \
    > vr-dti.diderot
# junk vr-dti.diderot

########## end code transformations
echo === diderotc vr-dti.diderot
diderotc --exec --target=pthread vr-dti.diderot
junk vr-dti{,.o,.cxx,}

echo === running vr-dti
# this is isosurfacing at FA=0.24 instead of 0.3 as noted in the Fig
# 7b caption because that looks better for this (different) dataset
./vr-dti $CAM_PARM $STEP_PARM -isoval 0.24
overrgb -i rgba.nrrd -b 1 1 1 -g srgb -srgb perc -o Figure07b.png
# junk rgba.nrrd

unu resample -i Figure07b.png -s = 400 a -o Figure07b-sm.png
