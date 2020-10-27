#!/bin/sh

#Create by Kingxl 
#http://itjoy.org
#Builds versions of the VideoLAN x264 for armv7 ,armv7s and arm64
#Combines the three libraries into a single one
#Make sure you have installed: Xcode/Preferences/Downloads/Components/Command Line Tools
#

rm -rf x264/config.h
rm -rf x264/x264_config.h
#Lib install dir.
ROOT=`pwd`
PLATFORM=mac
PROJECT=x264

OUTPUT_OBJECT="$ROOT/build/$PLATFORM/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/build/$PLATFORM/$PROJECT/install"
X264_PATH="$ROOT/x264"
rm -rf $ROOT/build/$PLATFORM/$PROJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

#This is decided by your SDK version.
# SDK_VERSION="10.15"

#Archs
ARCHS="x86_64"

XCODEDIR=`xcode-select --print-path`
OSX_SDK=$(xcodebuild -showsdks | grep "macos 10" -i | sort | head -n 1 | awk '{print $NF}')
MACOSX_PLATFORM=${XCODEDIR}/Platforms/MacOSX.platform
MACOSX_SYSROOT=${MACOSX_PLATFORM}/Developer/SDKs/${OSX_SDK}.sdk
echo "MACOSX_SYSROOT=${MACOSX_SYSROOT}"
# DEVPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${SDK_VERSION}.sdk

export CC=`xcodebuild -find clang`


for ARCH in $ARCHS; do

    echo "Building $ARCH ......"

    mkdir -p $OUTPUT_OBJECT/$ARCH
	cd $OUTPUT_OBJECT/$ARCH
	
    $X264_PATH/configure \
    --host=$ARCH-apple-darwin \
    --sysroot=$MACOSX_SYSROOT \
    --prefix=$OUTPUT_INSTALL/$ARCH \
    --extra-cflags="-arch $ARCH" \
    --extra-ldflags="-L$MACOSX_SYSROOT/usr/lib/system -arch $ARCH" \
    --enable-static || exit 1

    make && make install && make clean

    echo "Installed: $OUTPUT_INSTALL/$ARCH"

done

echo "Combining library ......"

BUILD_LIBS="libx264.a"
OUTPUT_DIR="$OUTPUT_INSTALL/all"

cd $OUTPUT_INSTALL

mkdir -p $OUTPUT_DIR
mkdir -p $OUTPUT_DIR/lib
mkdir -p $OUTPUT_DIR/include


LIPO_CREATE=""

for ARCH in $ARCHS; do
    LIPO_CREATE="$LIPO_CREATE $OUTPUT_INSTALL/$ARCH/lib/$BUILD_LIBS "
done

lipo -create $LIPO_CREATE -output $OUTPUT_DIR/lib/$BUILD_LIBS
cp -rf $OUTPUT_INSTALL/$ARCH/include $OUTPUT_DIR/

echo "************************************************************"
lipo -i $OUTPUT_DIR/lib/$BUILD_LIBS
echo "************************************************************"

echo "OK, merge done!"

