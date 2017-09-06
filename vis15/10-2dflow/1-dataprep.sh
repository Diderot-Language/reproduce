#!/bin/bash
source ../0-common.sh

# The turb2d.nrrd dataset is a resampling (by GLK) to a regular grid of
# flow data on a rectilinear grid (actually a slice of a cylindrical grid),
# courtesy of Wolfgang Kollmann
# <http://faculty.engineering.ucdavis.edu/kollmann/>, shared here with
# Dr. Kollmann's permission.

# Copy magenta/green colormap. This colormap is more principled
# (constructed as a smooth constant-speed path in LAB space, rather
# than simple RGB ramps) than the one used in the paper.  Given the
# way that color is incorporated into the result, it makes sense to do
# some gamma correction here.
unu gamma -g srgb -min 0 -max 1 -i ../00-cmap/mg-cmap.nrrd -o cmap.nrrd

RNG=43 # random number generator seed

# make seedpoints for streamlines; the unu hacking is on the geometry
# of the vector field, rather than on its values.  The script for
# making the figure in the paper paper used a much clumsier way to
# generate seedpoints (not based on unu grid), so these streamline
# locations differ than what was in paper.
unu slice -i turb2d.nrrd -a 0 -p 0 | # pick one of the vector coords
unu resample -s 27 a -c cell | # make it lo-res
unu grid -i - | # get a list of grid positions
unu 2op nrand -s $RNG - 0.09 -o seeds.txt # jitter them (reproducibly)

# make noise texture by upsampling the domain of the vector data
RUP=3 # upsampling factor from data to noise
unu slice -i turb2d.nrrd -a 0 -p 0 | # pick one of the vector coords
unu resample -s x$RUP x$RUP | # make it higher-res
# NOTE that if vector pixels are not isotropic, the resampling would
# have to be smarter, to make isotropic noise
unu 1op nrand -s $RNG -o rand.nrrd # make noise (reproducibly)
