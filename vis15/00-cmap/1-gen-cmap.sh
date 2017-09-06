#!/bin/bash
source ../0-common.sh

echo ====== by: from blue to white to yellowish
echo "65 0 -42.5
93 0 0
65 0 42.5" > by.txt
junk by.txt
./go-labparab.sh by.txt by-cmap

echo ====== mg: from magenta to white to green
AB=$(echo 92 -72 | unu 2op x - 0.5 | unu save -f text)
NAB=$(echo $AB | unu 2op x - -1 | unu save -f text)
echo "65 $AB
95 0 0
65 $NAB" > mg.txt
junk mg.txt
./go-labparab.sh mg.txt mg-cmap

unu pad -i by-cmap.png -min 0 0 0 -max M M+10 M -b pad -v 255 | unu join -i - mg-cmap.png -a 1 -o cmaps.png
