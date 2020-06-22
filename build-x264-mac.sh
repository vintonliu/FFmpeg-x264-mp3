#########################################################################
# File Name: build-x264-mac.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 二  6/16 15:50:42 2020
#########################################################################
#!/bin/bash

ROOT=`pwd`
SOURCE="x264"
PROJECT=x264
X264_PATH="$ROOT/$SOURCE"

OUTPUT_OBJECT="$ROOT/build/mac/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/build/mac/$PROJECT/install"

# Remove old build and installation files.
rm -rf $OUTPUT_OBJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

BUILD_LIBS="libx264.a"

ARCH="x86_64"

XCODEDIR=`xcode-select --print-path`
OSX_SDK=$(xcodebuild -showsdks | grep macosx | sort | head -n 2 | awk '{print $NF}')
MACOSX_PLATFORM=${XCODEDIR}/Platforms/MacOSX.platform
MACOSX_SYSROOT=${MACOSX_PLATFORM}/Developer/SDKs/MacOSX.sdk
echo "OSX_SDK=${OSX_SDK}"
echo "MACOSX_SYSROOT=${MACOSX_SYSROOT}"
# DEVPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${SDK_VERSION}.sdk

export CC=`xcodebuild -find clang`

configure="--disable-cli \
           --enable-static \
           --enable-pic \
           --disable-opencl \
           --enable-strip \
           --disable-win32thread \
           --bit-depth=8 \
           --disable-avs \
           --disable-swscale \
           --disable-lavf \
           --disable-ffms \
           --disable-gpac \
           --disable-lsmash"

mkdir -p $OUTPUT_OBJECT/$ARCH
cd $OUTPUT_OBJECT/$ARCH

$X264_PATH/configure ${configure} \
                    --host=$ARCH-apple-darwin \
                    --sysroot=$MACOSX_SYSROOT \
                    --prefix=$OUTPUT_INSTALL/$ARCH \
                    --extra-cflags="-arch $ARCH" \
                    --extra-ldflags="-L$MACOSX_SYSROOT/usr/lib/system -arch $ARCH"  || exit 1

make && make install

echo "Installed: $OUTPUT_INSTALL/$ARCH"
cd $ROOT