#!/bin/bash

ANDROID_NDK_ROOT=/Users/vinton/android-ndk-r17c

if [ ! -d "${ANDROID_NDK_ROOT}" ];then
echo error,no ANDROID_NDK_ROOT,set ANDROID_NDK_ROOT to NDK path
exit 1
fi

ROOT=`pwd`
SOURCE="ffmpeg"

OUTPUT_OBJECT="$ROOT/build/android/FFmpeg/object"
OUTPUT_INSTALL="$ROOT/build/android/FFmpeg/install"
FFMPEG_PATH="$ROOT/$SOURCE"
rm -rf $ROOT/build/android/FFmpeg

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

if [ $# = 1 ]
then
	ARCHS="$1"
else
	ARCHS="arm arm64 x86 x86_64"
fi

echo "ARCHS = $ARCHS"

API=23
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

for ARCH in $ARCHS; do
    
    # absolute path to x264 library
    X264="$ROOT/build/android/x264/install/$ARCH"
    MP3_LAME="$ROOT/build/android/mp3lame/install/$ARCH"
    FDK_AAC="$ROOT/build/android/fdkaac/install/$ARCH"

    if [ ! -f "$X264/lib/libx264.a" ]; 
    then
        echo "no x264 lib,start to build x264 $ARCH"
        $ROOT/build-x264-android.sh $ARCH
    fi

    # check mp3lame lib 
    if [ ! -f "$MP3_LAME/lib/libmp3lame.a" ]; 
    then
        echo "no mp3lame lib,start to build mp3lame $ARCH"
        $ROOT/build-lame-android.sh $ARCH
    fi

    # check fdk aac lib 
    if [ ! -f "$FDK_AAC/lib/libfdk-aac.a" ]; 
    then
        echo "no fdk-aac lib,start to build fdk-aac $ARCH"
        $ROOT/build-aac-android.sh $ARCH
    fi

    echo "Building ffmpeg for $ARCH ......"
    mkdir -p "$OUTPUT_OBJECT/$ARCH"
	cd "$OUTPUT_OBJECT/$ARCH"

	SYSROOT=$ANDROID_NDK_ROOT/platforms/android-$API/arch-$ARCH
	ISYSROOT=$ANDROID_NDK_ROOT/sysroot
	EXTRA_FLAGS=

    if [ "$ARCH" = "arm" ]
	then
		HOST=arm-linux-androideabi
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
		DISABLE_ASM=--disable-asm
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/$HOST-4.9/prebuilt/darwin-x86_64
		SYSROOT=$ANDROID_NDK_ROOT/platforms/android-$API/arch-mips
		CROSS_PREFIX=$PREBUILT/bin/mipsel-linux-android
	elif [ "$ARCH" = "x86" ]
	then
		HOST=i686-linux-android
		DISABLE_ASM=--disable-asm
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/x86-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/i686-linux-android
	elif [ "$ARCH" = "x86_64" ]
	then
		HOST=x86_64-linux-android
		DISABLE_ASM=--disable-asm
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/x86_64-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/x86_64-linux-android
	fi

    mkdir -p $OUTPUT_INSTALL/$ARCH
    mkdir -p $OUTPUT_OBJECT/$ARCH

    ECFLAGS="--sysroot=$ISYSROOT -isystem $ISYSROOT/usr/include/$HOST -D__ANDROID_API__=$API -D__ANDROID__ -DANDROID"
	ELDFLAGS="--sysroot=$SYSROOT -L$SYSROOT/usr/lib -lm"	

    if [ "$X264" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264 --enable-encoder=libx264"
        ECFLAGS="$ECFLAGS -I$X264/include"
        ELDFLAGS="$ELDFLAGS -L$X264/lib"
    fi

    if [ "$MP3_LAME" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libmp3lame --enable-decoder=mp3 --enable-encoder=libmp3lame --enable-muxer=mp3"
        ECFLAGS="$ECFLAGS -I$MP3_LAME/include"
        ELDFLAGS="$ELDFLAGS -L$MP3_LAME/lib"
    fi

    if [ "$FDK_AAC" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-encoder=libfdk_aac"
        ECFLAGS="$ECFLAGS -I$FDK_AAC/include"
        ELDFLAGS="$ELDFLAGS -L$FDK_AAC/lib"
    fi

    ECXXFLAGS="$ECFLAGS"
    LDFLAGS="$ELDFLAGS"
    
    mkdir -p $OUTPUT_INSTALL/$ARCH

    $FFMPEG_PATH/configure --prefix=$OUTPUT_INSTALL/$ARCH \
                --arch=$ARCH \
                --cc=$CROSS_PREFIX-gcc \
                --cross-prefix=$CROSS_PREFIX- \
                --nm=$CROSS_PREFIX-nm \
                --sysroot=$PLATFORM \
                --extra-cflags="$ECFLAGS" \
                --extra-cxxflags="$ECXXFLAGS" \
		        --extra-ldflags="$ELDFLAGS" \
                $CONFIGURE_FLAGS \
                || exit 1

    make -j8 && make install && make clean
done

cd $ROOT
