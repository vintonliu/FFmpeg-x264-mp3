#!/bin/sh

CWD=`pwd`
PLATFORM=mac
PROJECT=fdk-aac
SOURCE="fdk-aac-0.1.5"
SOURCE_PATH="$CWD/$SOURCE"

OUTPUT_OBJECT="$CWD/build/$PLATFORM/fdk-aac/object"
OUTPUT_INSTALL="$CWD/build/$PLATFORM/fdk-aac/install"
FAT="$OUTPUT_INSTALL/all"
THIN=$OUTPUT_INSTALL
rm -rf $OUTPUT_INSTALL

#This is decided by your SDK version.
# XCODEDIR=`xcode-select --print-path`
# OSX_SDK=$(xcodebuild -showsdks | grep macosx | sort | head -n 1 | awk '{print $NF}')
# MACOSX_PLATFORM=${XCODEDIR}/Platforms/MacOSX.platform
# MACOSX_SYSCWD=${MACOSX_PLATFORM}/Developer/MacOSX.sdk
# SDK_VERSION="10.15"

#DEVPATH=$MACOSX_SYSCWD
#DEVPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${SDK_VERSION}.sdk
#DEVPATH=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk
# echo "DEVPATH=${DEVPATH}"

# CC=`xcodebuild -find clang`

#Archs
ARCHS="x86_64"
MIN_VERSION="10.10"

CONFIGURE_FLAGS="--enable-static \
				--disable-shared \
				--with-pic=yes"

build_fdkaac() {
    if [ ! -f $SOURCE_PATH/configure ]
	then
		cd $SOURCE
		./autogen.sh
		cd $CWD
	fi

    for ARCH in $ARCHS; do
        echo "Building $ARCH ......"
        mkdir -p $OUTPUT_OBJECT/$ARCH
        cd $OUTPUT_OBJECT/$ARCH

        CFLAGS="-arch $ARCH -mmacosx-version-min=$MIN_VERSION"
        CXXFLAGS="$CFLAGS -stdlib=libc++"
        LDFLAGS="$CFLAGS"
        export CFLAGS=$CFLAGS
        export CXXFLAGS=$CXXFLAGS
        export LDFLAGS=$LDFLAGS

        $SOURCE_PATH/configure $CONFIGURE_FLAGS\
            --prefix=$OUTPUT_INSTALL/$ARCH || exit 1

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

build_fdkaac || exit 1
combile_libs || exit 1
copy_lib || exit 1

echo Done


