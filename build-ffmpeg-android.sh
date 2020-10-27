#!/bin/bash

ANDROID_NDK_ROOT=~/android-ndk-r20
if [ ! -d "${ANDROID_NDK_ROOT}" ];then
echo error,no ANDROID_NDK_ROOT,set ANDROID_NDK_ROOT to NDK path
exit 1
fi

TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64

API_32=19
API_64=21
# 五种类型cpu编译链
android_abis=(
    # armeabi is no longer support build
#   "armeabi"
    "armeabi-v7a"
    "arm64-v8a"
    # "x86"
    # "x86_64"
)

platforms=(
	# "arm"
	"armv7a"
	"aarch64"
	"i686"
	"x86_64"
)

archs=(
	# "arm"
	"arm"
	"aarch64"
	"i686"
	"x86_64"
)

extra_cflags=(
    # "-march=armv5te -msoft-float -D__ANDROID__  -D__ANDROID_API__=$API -D__ARM_ARCH_5TE__ -D__ARM_ARCH_5TEJ__"
    "-march=armv7-a -mfloat-abi=softfp -mfpu=neon -mthumb -D__ANDROID__  -D__ANDROID_API__=$API_32 -D__ARM_ARCH_7__ -D__ARM_ARCH_7A__ -D__ARM_ARCH_7R__ -D__ARM_ARCH_7M__ -D__ARM_ARCH_7S__"
    "-march=armv8-a -D__ANDROID__ -D__ANDROID_API__=$API_64 -D__ARM_ARCH_8__ -D__ARM_ARCH_8A__"
    "-march=i686 -mtune=i686 -m32 -mmmx -msse2 -msse3 -mssse3 -D__ANDROID__  -D__ANDROID_API__=$API_32 -D__i686__"
    "-march=core-avx-i -mtune=core-avx-i -m64 -mmmx -msse2 -msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -D__ANDROID__ -D__ANDROID_API__=$API_64 -D__x86_64__"
)

CWD=`pwd`
SOURCE="ffmpeg-4.2.4"
SOURCE_PATH="$CWD/$SOURCE"

OUTPUT_OBJECT="$CWD/build/android/ffmpeg/object"
OUTPUT_INSTALL="$CWD/build/android/ffmpeg/install"
# rm -rf $OUTPUT_INSTALL

configure="--enable-cross-compile \
        --target-os=android \
        --disable-debug \
        --enable-runtime-cpudetect \
        --disable-programs \
        --disable-doc \
        --enable-static \
        --disable-shared \
        --disable-devices \
        --disable-avdevice \
        --disable-iconv \
        --disable-outdevs \
        --disable-indevs \
        --disable-zlib \
        --disable-bzlib \
        --enable-gpl \
        --enable-version3 \
        --enable-nonfree \
        --enable-pic \
        --disable-coreimage \
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

target_configure=(
    # ""
    "--enable-armv6 --enable-armv6t2 --enable-vfp --enable-thumb --enable-neon"
    "--enable-armv8"
    "--disable-x86asm --disable-asm"
    "--disable-asm"
)

extra_configure=""

build_ffmpeg() {
    num=${#android_abis[@]}
	for((i=0; i<num; i++))
    do
        # absolute path to x264 library
        X264="$CWD/build/android/x264/install/${android_abis[i]}"
        MP3_LAME="$CWD/build/android/mp3lame/install/${android_abis[i]}"
        FDKAAC="$CWD/build/android/fdkaac/install/${android_abis[i]}"
        SSL="$CWD/3rd/openssl/android/${android_abis[i]}"

        # has_x264=0
        # if [ ! -f "$X264/${android_abis[i]}/lib/libx264.a" ]; 
        # then
        #     echo "no x264 lib,start to build x264"
        #     $CWD/build-x264-android.sh
        # fi
        # has_x264=1

        # check mp3lame lib 
        has_mp3lame=0
        if [ ! -f "$MP3_LAME/lib/libmp3lame.a" ]; 
        then
            echo "no mp3lame lib,start to build mp3lame"
            $CWD/build-lame-android.sh
        fi
        has_mp3lame=1

        # check fdk-aac lib
        has_fdkaac=0
        if [ ! -f "$FDKAAC/lib/libfdk-aac.a" ]; 
        then
            echo "no fdk-aac lib, start to build fdk-aac"
            $CWD/build-fdk-aac-android.sh
        fi
        has_fdkaac=1

        echo "*******************************************"
		echo "Building ffmpeg for ${android_abis[i]} ..."
		echo "*******************************************"

        if [ "${android_abis[i]}" = "armeabi-v7a" ]
		then
			HOST=arm-linux
			CLANG_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-androideabi$API_32
		elif [ "${android_abis[i]}" = "arm64-v8a" ]
		then
			HOST=aarch64-linux-android
			CLANG_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-android$API_64
		elif [ "${android_abis[i]}" = "x86" ]
		then
			HOST=i686-linux-android
			CLANG_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-android$API_32
		elif [ "${android_abis[i]}" = "x86_64" ]
		then
			HOST=x86_64-linux-android
			CLANG_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-android$API_64
		fi

		SYSROOT=$TOOLCHAIN/sysroot
		if [ "${android_abis[i]}" = "armeabi-v7a" -o "${android_abis[i]}" = "armeabi" ]
		then
            CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi
		else
            CROSS_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-android
		fi

        CFLAGS="${extra_cflags[i]} -fpic"
        # CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"

        # if [ $has_x264 -eq 1 ]
        # then
        #     CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
        #     CFLAGS="$CFLAGS -I$X264/${android_abis[i]}/include"
        #     LDFLAGS="$LDFLAGS -L$X264/${android_abis[i]}/lib"
        # fi

        if [ $has_mp3lame -eq 1 ]
        then
            extra_configure="$extra_configure --enable-libmp3lame --enable-encoder=libmp3lame"
            CFLAGS="$CFLAGS -I$MP3_LAME/include"
            LDFLAGS="$LDFLAGS -L$MP3_LAME/lib"
        fi

        if [ $has_fdkaac -eq 1 ]
        then
            extra_configure="$extra_configure --enable-libfdk-aac --enable-encoder=libfdk_aac"
            CFLAGS="$CFLAGS -I$FDKAAC/include"
            # add -lm for ffmpeg configure to check fdk-aac lib would link error cause math functions
            LDFLAGS="$LDFLAGS -L$FDKAAC/lib -lm"
        fi

        if [ -f "$SSL/lib/libssl.a" ]; 
        then
            extra_configure="$extra_configure --enable-openssl"
            CFLAGS="$CFLAGS -I$SSL/include"
            LDFLAGS="$LDFLAGS -L$SSL/lib"
        fi
    
        mkdir -p $OUTPUT_INSTALL/${android_abis[i]}
        mkdir -p $OUTPUT_OBJECT/${android_abis[i]}
        cd $OUTPUT_OBJECT/${android_abis[i]}

        echo "CFLAGS=$CFLAGS"
        echo "LDFLAGS=$LDFLAGS"

        $SOURCE_PATH/configure --prefix=$OUTPUT_INSTALL/${android_abis[i]} \
                                $configure \
                                $extra_configure \
                                ${target_configure[i]} \
                                --arch=${archs[i]} \
                                --cc=$CLANG_PREFIX-clang \
                                --cxx=$CLANG_PREFIX-clang++ \
                                --ld=$CLANG_PREFIX-clang \
                                --ranlib=$CROSS_PREFIX-ranlib \
                                --cross-prefix=$CROSS_PREFIX- \
                                --nm=$CROSS_PREFIX-nm \
                                --sysroot=$SYSROOT \
                                --extra-cflags="$CFLAGS" \
                                --extra-cxxflags="$CXXFLAGS" \
                                --extra-ldflags="$LDFLAGS" || exit 1

        make -j8 && make install || exit 1
    done

    cd $CWD
}

# copy libs
copy_lib() {
    echo "*******************************************"
	echo "Copy ffmpeg lib ..."
	echo "*******************************************"
    num=${#android_abis[@]}
	for((i=0; i<num; i++))
    do
        DST_LIB=$CWD/../refs/android/lib/${android_abis[i]}
        if [ ! -d $DST_LIB ]
        then
            mkdir -p $DST_LIB
        fi

        # copy lib
        cp -rf $OUTPUT_INSTALL/${android_abis[i]}/lib/*.a $DST_LIB/
    done

    # copy header
    # DST_INCLUDE=$CWD/../refs/android/include/ffmpeg
    # if [ ! -d $DST_INCLUDE ]
    # then
    #     mkdir -p $DST_INCLUDE
    # fi

    # all abi has same include files, so we only need copy one
    # cp -rf $OUTPUT_INSTALL/armeabi-v7a/include/* $DST_INCLUDE/
}

copy_config() {
    DST=$CWD/../refs/android/ffmpeg
    num=${#android_abis[@]}
	for((i=0; i<num; i++))
    do
        echo "copy config for ${android_abis[i]} ..."
        # Don't waste time on non-existent configs, if no config.h then skip.
        [ ! -e "$OUTPUT_OBJECT/${android_abis[i]}/config.h" ] && continue
        # for f in config.h config.asm libavutil/avconfig.h libavutil/ffversion.h libavcodec/bsf_list.c libavcodec/codec_list.c libavcodec/parser_list.c  libavformat/demuxer_list.c libavformat/muxer_list.c libavformat/protocol_list.c; do
        for f in config.h config.asm libavutil/avconfig.h libavutil/ffversion.h; do
            FROM="$OUTPUT_OBJECT/${android_abis[i]}/$f"
            TO="$DST/config/${android_abis[i]}/$f"
            if [ "$(dirname $f)" != "" ]; then mkdir -p $(dirname $TO); fi
            [ -e $FROM ] && cp -v $FROM $TO
        done
    done
}

build_ffmpeg || exit 1
copy_lib || exit 1
copy_config || exit 1

echo Done