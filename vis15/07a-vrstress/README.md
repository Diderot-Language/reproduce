# Figure 7a: Volume rendering stress tensors

Running (in this order):

	./1-dataprep.sh
	./2-vr.sh
	# ./3-cleanup.sh (optional)

should produce:

* (from [`1-dataprep.sh`](1-dataprep.sh)) Downloads a 1.2 gig dataset `dpl-256-ten9.nrrd`
* (from [`2-vr.sh`](2-vr.sh)) Rendering [`Figure07a.png`](ref/Figure07a.png) and low-res preview
[`Figure07a-sm.png`](ref/Figure07a-sm.png):
![](ref/Figure07a-sm.png "Figure 7a image")

This rendering also takes a few minutes, in part because of the large datasize,
as well as the small step size needed to capture the thin features.


