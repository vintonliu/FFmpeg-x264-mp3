#!/bin/sh

CWD=`pwd`

PLATFORM=mac
MP3_PATH="$CWD/mp3lame"
OUTPUT_OBJECT="$CWD/build/$PLATFORM/mp3lame/object"
OUTPUT_INSTALL="$CWD/build/$PLATFORM/mp3lame/install"
FAT="$OUTPUT_INSTALL/all"
THIN=$OUTPUT_INSTALL

rm -rf $OUTPUT_INSTALL


#This is decided by your SDK version.
# XCODEDIR=`xcode-select --print-path`
# OSX_SDK=$(xcodebuild -showsdks | grep macosx | sort | head -n 1 | awk '{print $NF}')
# MACOSX_PLATFORM=${XCODEDIR}/Platforms/MacOSX.platform
# MACOSX_SYSCWD=${MACOSX_PLATFORM}/Developer/${OSX_SDK}.sdk
# SDK_VERSION="10.15"

#DEVPATH=$MACOSX_SYSCWD
#DEVPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${SDK_VERSION}.sdk
#DEVPATH=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk
# echo "DEVPATH=${DEVPATH}"

# CC=`xcodebuild -find clang`

ARCHS="x86_64"
MIN_VERSION="10.10"

build_lame() {
    for ARCH in $ARCHS; do
        CFLAGS="-arch $ARCH -mmacosx-version-min=$MIN_VERSION"
        CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"
        echo "Building $ARCH ......"

        mkdir -p $OUTPUT_OBJECT/$ARCH
        cd $OUTPUT_OBJECT/$ARCH

        export CFLAGS=$CFLAGS
        export CXXFLAGS=$CXXFLAGS
        export LDFLAGS=$LDFLAGS
        $MP3_PATH/configure \
            --prefix=$OUTPUT_INSTALL/$ARCH \
            --enable-static || exit 1

        make && make install && make clean
    done

    cd $CWD
}

combile_libs() {
    echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	cd $THIN/$1/lib
	for LIB in *.a
	do
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
        lipo -info $FAT/lib/$LIB
	done
	cp -rf $THIN/$1/include $FAT

    cd $CWD
}

copy_lib() {
	DST=$CWD/../refs/mac
	for LIB in `find $FAT/lib -name "*.a"`
	do
		cp -rvf $LIB $DST
	done
}

build_lame || exit 1
combile_libs || exit 1
copy_lib || exit 1

echo Done
