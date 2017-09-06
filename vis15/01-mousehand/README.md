# Figure 1: 2D image data, field, and isocontours

Running (in this order):

	./1-bkgimg.sh
	./2-isodense.sh
	./3-isoptcl.sh
	./4-arrange.sh

should produce:

* (from [`1-bkgimg.sh`](1-bkgimg.sh)) [`A-upbox.png`](ref/A-upbox.png),
[`B-thresh.png`](ref/B-thresh.png),
[`C-c4hexic.png`](ref/C-c4hexic.png): grayscale images
representing (respectively) an dataset, a per-pixel operation on it
(the sort of thing Diderot is not best at), and the field that Diderot
can reconstruct from the data.
* (from [`2-isodense.sh`](2-isodense.sh)): [`D-isodense.pdf`](ref/D-isodense.pdf), showing a dense sampling of an isocontour.
This uses the stand-alone [`../epsdraw`](../epsdraw.c) utility for drawing dots over an image.
* (from [`3-isoptcl.sh`](3-isoptcl.sh)): [`E-isoptcl.pdf`](ref/E-isoptcl.pdf), showing a uniform sampling of an isocontour
produced by an interacting particle system
* (from [`4-arrange.sh`](4-arrange.sh)): Hi-res summary image [`Figure01.png`](ref/Figure01.png) and low-res
preview [`Figure01-sm.png`](ref/Figure01-sm.png), which puts the previous results together in a row:
![](ref/Figure01-sm.png "Figure 1 image")

The data in the figure is actually a summation projection of a CT scan of a mouse hand.
The underlying data is public; it was downloaded from
[University of Utah SCI group's CIBC CT Dataset Archive](http://www.sci.utah.edu/cibc-software/ctdata.html),
supported by NIH NIGMS grant P41 GM103545-18.
The original CT data is much higher-resolution, but since the point of the figure was to illustrate
the value of convolution-based reconstruction, the 2D projection was low-resolution. Within the `data`
subdirectory: the scripts `1-dataprep.sh`, `2-project.sh`, and `3-cleanup.sh` document all the steps
required to make the `data/hand.nrrd` image used in the figure.


