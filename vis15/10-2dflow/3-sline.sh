#!/bin/bash
source ../0-common.sh

echo ==== diderotc sline
diderotc --exec --target=pthread sline.diderot
junk sline{,.o,.cxx}

echo ==== running sline
./sline -hh 0.01 -stepNum 60 -arrow 0.04 -img turb2d.nrrd
junk p-{data,len}.nrrd

ccompile ../epsdraw

echo "==== epsdraw paths --> Figure10.eps"
../epsdraw lic2d.png p-data.nrrd -len p-len.nrrd -s 100 -rs 0.03 0.6 > Figure10.eps
junk Figure10.eps

echo "==== epstopdf --> Figure10.pdf"
cat Figure10.eps | epstopdf --nocompress -f -o=Figure10.pdf

echo "==== convert --> Figure10-sm.png"
convert -density 100 Figure10.pdf PNG:- |
unu crop -min 0 0 0 -max 2 M M |
unu resample -s = 400 a -o Figure10-sm.png


