#!/usr/bin/env bash
source ../0-common.sh
source 0-common.sh

# assuming a square image
SZ=$(unu save -f nrrd -i D-vr-canny.png | unu head - | grep sizes: | cut -d' ' -f 3)

MARG=3
unu join -i C-vr-iso-{1,2,3,4,5,6,7,8,9}.png -a 3 |
unu pad -min 0 0 0 0 -max M M+$MARG M+$MARG M -b pad -v 255 |
unu tile -a 3 1 2 -s 3 3 |
unu pad -min 0 -$MARG -$MARG -b pad -v 255 -max M M M |
unu resample -s = $SZ $SZ -o iso.png
junk iso.png

unu resample -i A-canny-slice.png -s $SZ $SZ -k box |
unu axinsert -a 0 -s 3 -o slice.png
junk slice.png

unu join -i slice.png iso.png D-vr-canny.png -a 1 -o Figure05.png

unu resample -i Figure05.png -s = 800 a -o Figure05-sm.png


