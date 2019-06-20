#!/bin/bash

ANDROID_NDK_ROOT=/Users/51talk/android-ndk-r17c

if [ ! -d "${ANDROID_NDK_ROOT}" ];then
echo error,no ANDROID_NDK_ROOT,set ANDROID_NDK_ROOT to NDK path
exit 1
fi

ROOT=`pwd`
SOURCE="ffmpeg"

OUTPUT_OBJECT="$ROOT/android/FFmpeg/object"
OUTPUT_INSTALL="$ROOT/android/FFmpeg/install"
FFMPEG_PATH="$ROOT/$SOURCE"
rm -rf $ROOT/android/FFmpeg

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

if [ $# = 1 ]
then
	ARCHS="$1"
else
	ARCHS="arm arm64 mipsel x86 x86_64"
fi

echo "ARCHS = $ARCHS"

TARGET_API=android-23
ORIGIN_PATH=$PATH

CONFIGURE_FLAGS="--disable-everything \
                --target-os=linux \
                --enable-cross-compile \
                --enable-runtime-cpudetect \
                --disable-stripping \
                --enable-nonfree \
                --enable-version3 \
                --enable-static \
                --disable-shared \
                --enable-gpl \
                --disable-doc \
                --enable-avresample \
                --enable-protocol=rtmp \
                --enable-protocol=rtsp \
                --enable-protocol=tcp \
                --enable-protocol=hls \
                --enable-protocol=http \
                --enable-protocol=https \
                --enable-protocol=rtmpe \
                --enable-protocol=rtmps \
                --enable-protocol=rtmpte \
                --enable-protocol=rtmpts \
                --enable-protocol=sdp \
                --enable-protocol=rtmpt \
                --enable-protocol=udp \
                --enable-protocol=file \
                --enable-decoder=aac \
                --enable-decoder=h264 \
                --enable-decoder=flv \
                --enable-parser=aac \
                --enable-parser=h264 \
                --enable-decoder=mp3 \
                --enable-demuxer=h264 \
                --enable-demuxer=aac \
                --enable-demuxer=flv \
                --enable-demuxer=rtsp \
                --enable-demuxer=rtp \
                --enable-demuxer=sdp \
                --enable-demuxer=hls \
                --enable-demuxer=mp3 \
                --enable-muxer=rtsp \
                --disable-ffplay \
                --enable-ffmpeg \
                --disable-ffprobe \
                --enable-protocol=rtp \
                --enable-hwaccels \
                --enable-zlib \
                --disable-devices \
                --disable-avdevice \
                --enable-pic"

cd ffmpeg
for ARCH in $ARCHS; do
    echo "Building ffmpeg for $ARCH ......"
	# absolute path to x264 library
    X264="$ROOT/android/x264/install/$ARCH"
    MP3_LAME="$ROOT/android/mp3lame/install/$ARCH"

	PLATFORM=$ANDROID_NDK_ROOT/platforms/$TARGET_API/arch-$ARCH
	EXTRA_FLAGS=

    if [ ! -f "$X264/lib/libx264.a" ]; 
    then
        echo "no x264 lib,start to build x264 $ARCH"
        $X264/build-x264-android.sh $ARCH
    fi

    # check mp3lame lib 
    if [ ! -f "$MP3_LAME/lib/libmp3lame.a" ]; 
    then
        echo "no mp3lame lib,start to build mp3lame $ARCH"
        $MP3_LAME/build-lame-android.sh $ARCH
    fi

	if [ "$ARCH" = "arm" ]
	then
		HOST=arm-linux
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/arm-linux-androideabi
		EXTRA_FLAGS="-mthumb -Wno-deprecated -mfloat-abi=softfp -mfpu=vfpv3-d16 -marm -march=armv7-a"
	elif [ "$ARCH" = "arm64" ]
	then
		HOST=aarch64-linux-android
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/$HOST-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/aarch64-linux-android
	elif [ "$ARCH" = "mipsel" ]
	then
		HOST=mipsel-linux-android
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/$HOST-4.9/prebuilt/darwin-x86_64
		PLATFORM=$ANDROID_NDK_ROOT/platforms/$TARGET_API/arch-mips
		CROSS_PREFIX=$PREBUILT/bin/mipsel-linux-android
	elif [ "$ARCH" = "x86" ]
	then
		HOST=i686-linux-android
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/x86-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/i686-linux-android
	elif [ "$ARCH" = "x86_64" ]
	then
		HOST=x86_64-linux-android
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/x86_64-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/x86_64-linux-android
	fi

    mkdir -p $OUTPUT_INSTALL/$ARCH
    mkdir -p $OUTPUT_OBJECT/$ARCH

	CFLAGS="-I$PLATFORM/usr/include -DANDROID $EXTRA_FLAGS"
    CXXFLAGS="$CFLAGS"
    LDFLAGS="$CFLAGS"

    if [ "$X264" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
        CFLAGS="$CFLAGS -I$X264/include"
        LDFLAGS="$LDFLAGS -L$X264/lib"
    fi

    if [ "$MP3_LAME" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libmp3lame --enable-decoder=mp3 --enable-encoder=libmp3lame --enable-muxer=mp3"
        CFLAGS="$CFLAGS -I$MP3_LAME/include"
        LDFLAGS="$LDFLAGS -L$MP3_LAME/lib"
    fi

    
    ./configure --prefix=$OUTPUT_INSTALL/$ARCH \
                --arch=$ARCH \
                --cc=$CROSS_PREFIX-gcc \
                --cross-prefix=$CROSS_PREFIX- \
                --nm=$CROSS_PREFIX-nm \
                --sysroot=$PLATFORM \
                --extra-cflags="$CFLAGS" \
                --extra-cxxflags="$CXXFLAGS" \
		        --extra-ldflags="$LDFLAGS" \
                $CONFIGURE_FLAGS \
                || exit 1

    make -j8 && make install && make clean
done

cd $ROOT
