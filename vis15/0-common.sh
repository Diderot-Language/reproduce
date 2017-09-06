set -o errexit
set -o nounset
shopt -s expand_aliases
JUNK=""
function junk { JUNK="$JUNK $@"; }
function cleanup { rm -rf $JUNK; }
trap cleanup err exit int term

if ! hash unu 2>/dev/null; then
    echo "$0: sorry, need to have \"unu\" in your path" >&2
    exit 1
fi
if ! hash diderotc 2>/dev/null; then
    echo "$0: sorry, need to have \"diderotc\" in your path" >&2
    exit 1
fi
if ! hash epstopdf 2>/dev/null; then
    echo "$0: sorry, need to have \"epstopdf\" in your path; see https://www.ctan.org/pkg/epstopdf" >&2
    exit 1
fi
if ! hash convert 2>/dev/null; then
    echo "$0: sorry, need to have ImageMagick \"convert\" in your path; see http://www.imagemagick.org" >&2
    exit 1
fi
unufmt=$(unu about | grep "Formats available")
if [[ ! $unufmt == *png* ]]; then
    echo "$0: sorry, your unu needs to be built with PNG support (\"unu about\" said: $unufmt)" >&2
    exit 1
fi
ddVfull=$(diderotc --version)
ddV=$(echo $ddVfull | cut -d: -f 1)
if [[ "$ddV" != "vis15" ]]; then
    echo "$0: sorry, need \"vis15\" diderotc in your path (not $ddVfull)" >&2
    exit 1
fi

if [ -z ${DDRO_EXAMPLES+x} ]; then
    echo "$0: sorry, need environment variable DDRO_EXAMPLES set to checkout of https://github.com/Diderot-Language/examples" >&2
    exit 1
fi
if [ ! -d $DDRO_EXAMPLES/fs3d ]; then
    echo "$0: sorry; need environment variable DDRO_EXAMPLES set to checkout of https://github.com/Diderot-Language/examples" >&2
    exit 1
fi

if [ -z ${TEEM_INSTALL+x} ]; then
    echo "$0: sorry, need environment variable TEEM_INSTALL set to Teem build (with lib, include subdirs);" >&2
    echo "$0: see http://teem.sourceforge.net/build.html" >&2
    exit 1
fi
if [ ! -d $TEEM_INSTALL/lib ]; then
    echo "$0: sorry; need environment variable TEEM_INSTALL set to Teem build (with lib, include subdirs);" >&2
    echo "$0: see http://teem.sourceforge.net/build.html" >&2
    exit 1
fi

function ccompile {
  base=$1
  if [[ ! -x $base ]]; then
    echo ==== gcc $base
    gcc -W -I$TEEM_INSTALL/include -L$TEEM_INSTALL/lib/ $base.c -o $base -lteem -lpng -lz -lbz2 -lm
    # don't junk it; may be used for other figures
  fi
}
