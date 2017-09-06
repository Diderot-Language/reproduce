#!/usr/bin/env bash

MARG=8
unu join -i A-flow-MAG.png B-flow-EXT.png C-flow-NHL.png -a 3 |
unu pad -min 0 0 0 0 -max M M+$MARG M+$MARG M -b pad -v 255 |
unu tile -a 3 1 2 -s 3 1 |
unu pad -min 0 -$MARG -$MARG -max M M M -b pad -v 255 -o Figure06.png

unu resample -i Figure06.png -s = 800 a -o Figure06-sm.png

