#!/bin/sh


# see detail https://www.roxlu.com/2016/057/compiling-x264-on-windows-with-msvc

CONFIGURE_FLAGS="--disable-cli \
				--enable-static \
				--enable-pic \
				--disable-opencl \
				--bit-depth=8 \
                --enable-strip \
				--disable-avs \
				--disable-swscale \
				--disable-lavf \
				--disable-ffms \
				--disable-gpac \
				--disable-lsmash"

ROOT=`pwd`
SOURCE="x264"
PROJECT=x264
X264_PATH="$ROOT/$SOURCE"

OUTPUT_OBJECT="$ROOT/build/win/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/build/win/$PROJECT/install"

rm -rf $ROOT/build/win/$PROJECT
mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

cd $OUTPUT_OBJECT

CC=cl $X264_PATH/configure --prefix="$OUTPUT_INSTALL" \
    $CONFIGURE_FLAGS

make && make install

cd $ROOT