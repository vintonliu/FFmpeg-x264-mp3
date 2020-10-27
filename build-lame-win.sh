#!/bin/bash

if [ $# -gt 0 -a "$1" != "x86" -a "$1" != "x86_64" ]
then
    echo "usage: build-lame-win.sh x86 | x86_64"
    exit 0
fi

CWD=`pwd`

PLATFORM=win
SOURCE_PATH="$CWD/mp3lame"
OUTPUT_INSTALL="$CWD/build/$PLATFORM/mp3lame/install"

rm -rf $OUTPUT_INSTALL

ARCH=$1
if [ -z "$1" ]
then
    ARCH="x86"
fi

build_lame() {
    
    echo "Building $ARCH ......"
    cd $SOURCE_PATH

    nmake -f Makefile.MSVC rebuild
    nmake -f Makefile.MSVC prefix=$OUTPUT_INSTALL/$ARCH install
    nmake -f Makefile.MSVC clean

    cd $CWD
}

copy_lib() {
	DST=$CWD/../refs/pc
	for LIB in `find $OUTPUT_INSTALL/$ARCH -name "*.lib" -o -name "*.dll"`
	do
		cp -rvf $LIB $DST
	done
}

build_lame || exit 1
copy_lib || exit 1

echo Done
