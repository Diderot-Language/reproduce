#!/usr/bin/env bash
source ../0-common.sh

# The VIS'15 paper used a 256x256x66 sampling of a double-point load
# dataset. The poor sampling along the Z axis produced some visible
# artifacts near the load locations, and created big circular holes in
# the the features at the top of the field. Still, 256x256x66 is a
# large dataset; too big to put into this repository. For the purposes
# of figure reproduction we may as well use a better (and even larger:
# 256x256x256 1.2 gigabyte) dataset, which can be found here:

if [[ ! -f dpl-256-ten9.nrrd ]]; then
    curl -O http://people.cs.uchicago.edu/~glk/linked/dpl-256-ten9.nrrd
fi

# This dataset was computed by GLK using a modification of code provided by
# Xavier Tricoche. In the interest of maximal precision, the values are
# computed and saved in double precision, hence the large size. Also,
# unfortunately Diderot currently requires that 3x3 tensors be represented
# in memory as 9-vectors (of the tensor components), even when the tensor
# is known to be symmetric, and, Diderot requires that images be stored on
# disk the same as in memory, which means that we can't exploit the tensor
# symmetry to reduce disk space.
