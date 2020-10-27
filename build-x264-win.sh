#!/bin/bash

# before run this script, need fix the build script for x264
# follow below steps:
# cd <path>/x264
# curl "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD" > config.guess
# sed -i 's/host_os = mingw/host_os = msys/' configure

if [ $# -gt 0 -a "$1" != "x86" -a "$1" != "x86_64" ]
then
    echo "usage: build-lame-win.sh x86 | x86_64"
    exit 0
fi

CWD=`pwd`

SOURCE_PATH="$CWD/x264"
OUTPUT_OBJECT="$CWD/build/win/x264/object"
OUTPUT_INSTALL="$CWD/build/win/x264/install"

rm -rf $OUTPUT_INSTALL

ARCH=$1
if [ -z "$1" ]
then
    ARCH="x86"
fi

build_x264() {
    
    echo "Building $ARCH ......"
    mkdir -p $OUTPUT_OBJECT/$ARCH
	cd $OUTPUT_OBJECT/$ARCH
	
    CC=cl $SOURCE_PATH/configure \
                --prefix=$OUTPUT_INSTALL/$ARCH \
                --enable-static \
                --enable-shared || exit 1

    make && make install && make clean


    cd $CWD
}

copy_lib() {
	DST=$CWD/../refs/pc
	for LIB in `find $OUTPUT_INSTALL/$ARCH -name "*.lib" -o -name "*.dll"`
	do
		cp -rvf $LIB $DST
	done
}

build_x264 || exit 1
copy_lib || exit 1

echo Done