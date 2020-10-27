#!/bin/bash

if [ $# -gt 0 -a "$1" != "x86" -a "$1" != "x86_64" ]
then
    echo "usage: build-fdk-aac-win.sh x86 | x86_64"
    exit 0
fi

CWD=`pwd`
PLATFORM=win
PROJECT=fdk-aac
SOURCE="fdk-aac-0.1.5"
SOURCE_PATH="$CWD/$SOURCE"

OUTPUT_OBJECT="$CWD/build/$PLATFORM/fdk-aac/object"
OUTPUT_INSTALL="$CWD/build/$PLATFORM/fdk-aac/install"
rm -rf $OUTPUT_INSTALL

#Archs
ARCH=$1
if [ -z "$1" ]
then
    ARCH="x86"
fi

build_fdkaac() {
    if [ ! -f $SOURCE_PATH/configure ]
	then
		cd $SOURCE
		./autogen.sh
		cd $CWD
	fi

    echo "Building $ARCH ......"
    cd $SOURCE_PATH

    nmake -f $SOURCE_PATH/Makefile.vc
    nmake -f $SOURCE_PATH/Makefile.vc prefix=$OUTPUT_INSTALL/$ARCH install
    nmake -f Makefile.vc clean

    cd $CWD
}

copy_lib() {
    echo "Begin copy libs for $ARCH ......"
	DST=$CWD/../refs/pc/
	for LIB in `find $OUTPUT_INSTALL/$ARCH -name "*.lib" -o -name "*.dll"`
	do
		cp -rvf $LIB $DST
	done
}

build_fdkaac || exit 1
copy_lib || exit 1

echo Done


