#!/bin/bash
set -o errexit
set -o nounset
shopt -s expand_aliases
JUNK=""
function junk { JUNK="$JUNK $@"; }
function cleanup { rm -rf $JUNK; }
trap cleanup err exit int term

rm -f muhand.nrrd

rm -f hox-wt-20050509-03-hand.{vff,nhdr}

