#!/usr/bin/env bash
source ../0-common.sh

# copy colormap; this is a more principled map (constructed as a smooth
# constant-speed path through LAB color space, instead of linear ramps
# in RGB space) than the one used in the paper, so the resulting image
# is slightly different
cp ../00-cmap/by-cmap.nrrd cmap.nrrd
junk cmap.nrrd

CAM_PARM="-camEye -7.14606 -15.8878 -71.891
-camAt 7.77474 0.202849 2.86306
-camUp -0.00575318 -0.977356 0.211522
-camNear 71.420493 -camFar 84.074673
-camFOV 6.89
-iresU 800
-iresV 300
-phongKa 0.1
-phongKd 0.8
-lightVsp -2 3.5 -1"

STEP_PARM="-rayStep 0.02 -refStep 0.01 -thick 0.05"

FLOW_BKGD="0.1 0.12 0.14"

########## begin code transformations described in Section 4.1 of paper

# (not explicitly mentioned in the paper text) Changing single isoval to two
# values, and moving it from the field definition to the opacity function, so
# that two isosurfaces can be shown
oldIsoval='input real isoval;  input real thick;'
newIsoval='input vec2 isoval;  input real thick;'
oldAlpha='  = clamp(0, 1, 1.3*(1 - |v|/(g*thick)));'
newAlpha='  = max(clamp(0, 1, 1.3*(1 - |v-isoval[0]|/(g*thick))),
        clamp(0, 1, 1.3*(1 - |v-isoval[1]|/(g*thick))));'

# working from 3D vector field instead of 3D scalar field
oldData='field#4(3)[] V = bspln5 ⊛ image("vol.nrrd");'
newData='field#4(3)[3] V = bspln5 ⊛ image("flow.nrrd");'

# colormap vector field jacobian discriminant
oldCmap='function vec3 color(vec3 x) = cmap(V(x));'
newCmap='field#3(3)[3,3] J = ∇⊗V;
field#3(3)[] cbA = -trace(J);
field#3(3)[] cbB = (trace(J)*trace(J) - trace(J•J))/2;
field#3(3)[] cbC = -det(J);
field#3(3)[] cbQ = (cbA*cbA/3.0 - cbB)/3.0;
field#3(3)[] cbR = (-2.0*cbA*cbA*cbA/27.0 + cbA*cbB/3.0 - cbC)/2.0;
field#3(3)[] cbD = cbR*cbR - cbQ*cbQ*cbQ;
function vec3 color(vec3 x) = cmap(lerp(-1,1,-0.25,cbD(x)^0.25 if cbD(x)>0 else -(-cbD(x))^0.25,0.25));'
# currently Diderot has no signed exponentiation, hence the conditional
# expression above. The paper used signed sqrt(), but by using ^0.25 here
# there is even more compression of the extremal values, so is slightly more
# informative.  The fact that the colormap is covering the range [-0.25,0.25]
# is a coincidence.

# two-sided lighting
oldShade='real shade = max(0, normalize(grad)•light);'
newShade='real shade = |normalize(grad)•light|;'

# Adding some basic progress indication. NOTE that with multi-threading, the
# per-pixel strands are load-balanced across threads, so these will probably
# be printed out of order. Currently, however, the image is still traversed
# from top to bottom, so this is still informative.
oldUpdate='  update {'
newUpdate='  update {
    if (ui==0 && rayN == camNear) print("row ", vi, "/", iresV, "\\n");'

echo === creating vr-tmp.diderot
cat ../volrend.diderot \
    | perl -pe "s!\Q$oldIsoval\E!${newIsoval}!g" \
    | perl -pe "s!\Q$oldData\E!${newData}!g" \
    | perl -pe "s!\Q$oldCmap\E!${newCmap}!g" \
    | perl -pe "s!\Q$oldAlpha\E!${newAlpha}!g" \
    | perl -pe "s!\Q$oldUpdate\E!${newUpdate}!g" \
    | perl -pe "s!\Q$oldShade\E!${newShade}!g" \
    > vr-flow-tmp.diderot

########## end code transformations (except for setting field)

# rendering various vector field properties; these are the different parts of
# Figure 6. Each one involves a definition of field F, isovalues, and a name
oldField='field#4(3)[] F = V - isoval; // isosurface is {x|F(x)=0}'
newField=(
  'field#4(3)[] F=|V|;'
  'field#3(3)[] F = (V/|V|) • (∇|V|/|(∇|V|)|);'
  'field#3(3)[] F = (V/|V|) • (∇×V/|∇×V|);'
)
ISOVAL=("0.4 0.8" "-0.99 0.99" "-0.99 0.99")
WUT=(MAG EXT NHL)
ABC=(A B C)
# Normalized helicity (sub-figure C) varies much more rapidly (within the
# spatial domain) than the other quantities, creating a challenge for
# volume-rendering-based approaches to showing these quantities. Making the
# last subfigure required a much smaller step-size, and higher "thickness",
# than the other two; these will over-ride the values supplied in
# $STEP_PARM. This causes the third rendering to be *more than 100 times*
# slower than the other images. Also, the renderings of normalized helicity
# in the paper were not actually of isosurfaces at isovalues +/-0.99 (as
# stated in the figure caption), but at +/-0.85, in a mis-guided effort to
# made the isosurfaces more visible. The rendering here is at +/-0.99.
# Opportunities for optimization are a subject of current and future Diderot
# research.
STEP=("" "" "-rayStep 0.0002")
THICK=("" "" "-thick 1")

for I in 0 1 2; do
    newF=${newField[$I]}
    wut=${WUT[$I]}
    cat vr-flow-tmp.diderot \
        | perl -pe "s!\Q$oldField\E!${newF}!g" \
        > vr-flow-$wut.diderot
    junk vr-flow-$wut.diderot
    echo "=== $I/3 diderotc vr-flow-$wut.diderot with \"$newF\""
    diderotc --exec --target=pthread vr-flow-$wut.diderot
    junk vr-flow-$wut{.diderot,.o,.cxx,}
    echo === running vr-flow-$wut
    ./vr-flow-$wut $CAM_PARM $STEP_PARM ${STEP[$I]} ${THICK[$I]} -isoval ${ISOVAL[$I]}
    # images in the paper were completely missing gamma correct (oops); slightly
    # different lighting and incomplete gamma correction does does an ok job at
    # recreating the published images.
    overrgb -i rgba.nrrd -b $FLOW_BKGD -g 1.5 -srgb perc -o ${ABC[$I]}-flow-$wut.png
    junk rgba.nrrd
done

junk vr-flow-tmp.diderot
