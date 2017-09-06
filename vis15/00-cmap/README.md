# Univariate Colormap Generation

Running the [`1-gen-cmap.sh`](1-gen-cmap.sh) script with:

	./1-gen-cmap.sh

should produce:

* `by-cmap.nrrd`, `by-cmap.png`: blue-to-yellow colormap (`.nrrd`), and its image preview:  
![](ref/by-cmap.png "by-cmap.png")
* `mg-cmap.nrrd`, `mg-cmap.png`: magenta to green colormap and preview:  
![](ref/mg-cmap.png "mg-cmap.png")
* `cmaps.png`: image preview of both colormaps.

The VIS'15 paper used simple univariate colormaps that were
defined in RGB space, with no particular perceptual properties.
Similar colormaps are made here as smooth and constant-speed paths
through LAB color space. The Diderot program
[`labparab.ddro`](labparab.ddro) interpolates through (by parabola fitting)
three control points in LAB space, and converts RGB.  The program
also provides a way of recording the speed (in LAB) of the path, so
that (with unu hacking) the path can be reparameterized to be
constant-speed (this is an example of something mathematically relevant to scivis but
outside Diderot's current expressivity).  The [`go-labparab.sh`](go-labparab.sh) driver script
compiles and runs the underlying Diderot program, and does the
unu-based post-processing.
