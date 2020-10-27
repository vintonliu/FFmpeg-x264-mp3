#!/bin/bash

if [ $# -gt 0 -a "$1" != "x86" -a "$1" != "x86_64" ]
then
    echo "usage: build-lame-win.sh x86 | x86_64"
    exit 0
fi

ARCH=$1
if [ -z "$1" ]
then
    ARCH="x86"
fi

CWD=`pwd`
PLATFORM=win
# absolute path to x264 library
X264="$CWD/build/$PLATFORM/x264/install/$ARCH"
MP3_LAME="$CWD/build/$PLATFORM/mp3lame/install/$ARCH"
FDKAAC="$CWD/build/$PLATFORM/fdk-aac/install/$ARCH"

# check h264 lib 
has_x264=0
# if [ ! -f "$X264/lib/libx264.a" ]; 
# then
# echo "no x264 lib,start to build x264"
# ./build-x264-win.sh || exit 1
# fi
# has_x264=1

has_mp3lame=0
if [ ! -f "$MP3_LAME/lib/mp3lame.lib" ]; 
then
echo "no mp3lame lib, start to build mp3lame"
# ./build-lame-win.sh || exit 1
fi
has_mp3lame=1

# check fdk-aac lib 
has_fdkaac=0
if [ ! -f "$FDKAAC/lib/fdk-aac.lib" ]; 
then
echo "no fdk-aac lib,start to build fdk-aac"
# ./build-fdk-aac-win.sh || exit 1
fi
has_fdkaac=1

SOURCE="ffmpeg-4.2.4"
SOURCE_PATH="$CWD/$SOURCE"

OUTPUT_OBJECT="$CWD/build/$PLATFORM/ffmpeg/object"
OUTPUT_INSTALL="$CWD/build/$PLATFORM/ffmpeg/install"

rm -rf $OUTPUT_INSTALL

CONFIGURE_FLAGS="--disable-debug \
                --disable-programs \
                --disable-doc \
                --enable-pic \
                --enable-gpl \
                --enable-nonfree \
                --disable-zlib \
                --disable-bzlib \
                --disable-iconv \
                --disable-lzma \
                --disable-xlib \
                --disable-error-resilience \
                --disable-lzo \
                --disable-devices \
                --disable-avdevice \
                --disable-coreimage \
                --enable-x86asm \
                --disable-everything \
                --enable-filters \
                --enable-fft \
                --enable-rdft \
                --enable-hwaccels \
                --enable-decoder=vorbis,flac \
                --enable-decoder=pcm_u8,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le \
                --enable-decoder=pcm_s16be,pcm_s24be,pcm_mulaw,pcm_alaw \
                --enable-decoder=aac* \
                --enable-decoder=mp3* \
                --enable-protocol=rtmp* \
                --enable-protocol=file,crypto \
                --enable-demuxer=wav,mp3,aac,h264,mov \
                --enable-parser=aac,h264 \
                --enable-muxer=mp3,mp4,h264,mov,wav"

# if [ $has_x264 -eq 1 ]
# then
# 	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libx264 --enable-encoder=libx264"
# fi

if [ $has_fdkaac -eq 1 ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-encoder=libfdk_aac"
fi

if [ $has_mp3lame -eq 1 ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libmp3lame --enable-encoder=libmp3lame"
fi

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

build_ffmpeg() {
    echo "building $ARCH..."
    mkdir -p "$OUTPUT_OBJECT/$ARCH"
    cd "$OUTPUT_OBJECT/$ARCH"

    CFLAGS=""
    CXXFLAGS="$CFLAGS"
    LDFLAGS="$CFLAGS"
    
    # if [ $has_x264 -eq 1 ]
    # then
    # 	CFLAGS="$CFLAGS -I$X264/include"
    # 	LDFLAGS="$LDFLAGS -L$X264/lib"
    # fi

    if [ $has_fdkaac -eq 1 ]
    then
        CFLAGS="$CFLAGS -I$FDKAAC/include"
        LDFLAGS="$LDFLAGS -LIBPATH:$FDKAAC/lib"
    fi
    if [ $has_mp3lame -eq 1 ]
    then
        CFLAGS="$CFLAGS -I$MP3_LAME/include"
        LDFLAGS="$LDFLAGS -LIBPATH:$MP3_LAME/lib"
    fi

    echo "CFLAGS=$CFLAGS"
    echo "LDFLAGS=$LDFLAGS"
    $SOURCE_PATH/configure \
        --prefix="$OUTPUT_INSTALL/$ARCH" \
        $CONFIGURE_FLAGS \
        --toolchain=msvc \
        --arch=$ARCH \
        --disable-static \
        --enable-shared \
        --extra-cflags="$CFLAGS" \
        --extra-cxxflags="$CXXFLAGS" \
        --extra-ldflags="$LDFLAGS" \
    || exit 1

    make -j8 install || exit 1

    cd $CWD
}

copy_lib() {
	echo "*******************************************"
	echo "Copy ffmpeg lib ..."
	echo "*******************************************"
	DST=$CWD/../refs/pc/ffmpeg/lib/$ARCH
	if [ -d $DST ]
	then
		rm -rf $DST
	fi
	mkdir -p $DST

    for LIB in `find $OUTPUT_INSTALL/$ARCH -name "*.lib" -o -name "*.dll"`
	do
		cp -rvf $LIB $DST
	done
}

copy_config() {
	DST=$CWD/../refs/pc/ffmpeg
    echo "*******************************************"
    echo "Copy ffmpeg build config ..."
    echo "*******************************************"

    # Don't waste time on non-existent configs, if no config.h then skip.
    [ ! -e "$OUTPUT_OBJECT/$ARCH/config.h" ] && continue
    # for f in config.h config.asm libavutil/avconfig.h libavutil/ffversion.h libavcodec/bsf_list.c libavcodec/codec_list.c libavcodec/parser_list.c  libavformat/demuxer_list.c libavformat/muxer_list.c libavformat/protocol_list.c; do
    for f in config.h config.asm libavutil/avconfig.h libavutil/ffversion.h; do
        FROM="$OUTPUT_OBJECT/$ARCH/$f"
        TO="$DST/config/$ARCH/$f"
        if [ "$(dirname $f)" != "" ]; then mkdir -p $(dirname $TO); fi
        [ -e $FROM ] && cp -rfv $FROM $TO
    done
}

build_ffmpeg || exit 1
copy_lib || exit 1
copy_config || exit 1

echo Done