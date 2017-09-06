# Figure 7b: Volume rendering diffusion tensors

The brain DTI data used in paper was from [FMRIB lab in Oxford
University](https://www.ndcn.ox.ac.uk/divisions/fmrib/fmrib-analysis-group)
but that data is not publicly available.  Here are the steps to create
a comparable image from publicly available data, from the [NAMIC
project](http://hdl.handle.net/1926/1687).

Running (in this order):

	./1-dataprep.sh
	./2-vr.sh
	# ./3-cleanup.sh (optional)

should produce:

* (from [`1-dataprep.sh`](1-dataprep.sh)): You have to read the first comments in the script to
download the `case01026` data directory; there isn't a single static URL for it.
Then this script documents the various steps to estimate a diffusion tensor field
from the DWMRI data, and simulate the brain floating in a tank of water (no skull),
to simplify later rendering.
* (from [`2-vr.sh`](2-vr.sh)) Rendering [`Figure07b.png`](ref/Figure07b.png) and low-res preview
[`Figure07b-sm.png`](ref/Figure07b-sm.png):
![](ref/Figure07b-sm.png "Figure 7b image")
