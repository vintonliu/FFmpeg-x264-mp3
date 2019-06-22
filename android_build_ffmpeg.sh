#########################################################################
# File Name: android_build_ffmpeg.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 五  6/21 10:44:14 2019
#########################################################################
#!/bin/bash

ROOT=`pwd`

if [ ! -d "ffmpeg" ]
then
    echo "下载 ffmpeg-4.1 源文件"
    git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
    cd ffmpeg
    git checkout release/4.1
fi

# 配置交叉编译链，未生成交叉编译链请执行 ./make_android_toolchain.sh
export TOOL_ROOT=$ROOT/android-toolchain

# 五种类型cpu编译链
android_toolchains=(
    "armeabi"
    "armeabi-v7a"
    "arm64-v8a"
    "x86"
    "x86_64"
)

# 优化编译项
API=23
extra_cflags=(
    "-std=gnu11 -march=armv5te -msoft-float -D__ANDROID__ -D__ANDROID_API__=$API -D__ARM_ARCH_5TE__ -D__ARM_ARCH_5TEJ__"
    "-std=gnu11 -march=armv7-a -mfloat-abi=softfp -mfpu=neon -mthumb -D__ANDROID__ -D__ANDROID_API__=$API -D__ARM_ARCH_7__ -D__ARM_ARCH_7A__ -D__ARM_ARCH_7R__ -D__ARM_ARCH_7M__ -D__ARM_ARCH_7S__"
    "-std=gnu11 -march=armv8-a -D__ANDROID__ -D__ANDROID_API__=$API -D__ARM_ARCH_8__ -D__ARM_ARCH_8A__"
    "-std=gnu11 -march=i686 -mtune=i686 -m32 -mmmx -msse2 -msse3 -mssse3 -D__ANDROID__ -D__ANDROID_API__=$API -D__i686__"
    "-std=gnu11 -march=core-avx-i -mtune=core-avx-i -m64 -mmmx -msse2 -msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -D__ANDROID__ -D__ANDROID_API__=$API -D__x86_64__"
)

# extra_ldflags="-nostdlib"

# 共同配置项,可以额外增加相关配置，详情可查看源文件目录下configure
#--disable-indev=v4l2  #解决libavdevice/v4l2.c:135:9: error: assigning to 'int (*)(int, unsigned long, ...)'
configure="--disable-everything \
            --enable-runtime-cpudetect \
            --disable-stripping \
            --enable-nonfree \
            --enable-version3 \
            --enable-static \
            --enable-shared \
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
            --enable-protocol=rtp \
            --enable-protocol=rtmpt \
            --enable-protocol=udp \
            --enable-protocol=file \
            --enable-decoder=aac \
            --enable-decoder=h264 \
            --enable-decoder=flv \
            --enable-decoder=mp3 \
            --enable-parser=aac \
            --enable-parser=h264 \
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
            --enable-hwaccels \
            --enable-zlib \
            --disable-devices \
            --disable-avdevice \
            --enable-pic"

#针对各版本不同的编译项
extra_configure=(
    "--disable-asm"
    ""
    ""
    "--disable-asm"
    "--disable-asm"
)

x264_configure="--enable-gpl --enable-libx264"
mp3lame_configure="--enable-libmp3lame --enable-encoder=libmp3lame --enable-muxer=mp3"
fdkaac_configure="--enable-libfdk-aac"

#交叉编译后的运行环境
hosts=(
    "arm-linux-androideabi"
    "arm-linux-androideabi"
    "aarch64-linux-android"
    "i686-linux-android"
    "x86_64-linux-android"
)

#交叉编译工具前缀
cross_prefix=(
    "arm-linux-androideabi-"
    "arm-linux-androideabi-"
    "aarch64-linux-android-"
    "i686-linux-android-"
    "x86_64-linux-android-"
)

# 支持以下5种cpu框架
archs=(
    "arm"
    "arm"
    "arm64"
    "x86"
    "x86_64"
)

# 当前目录下 ffmpeg 源文件目录
PROJECT=ffmpeg
SOURCE_PATH=$ROOT/ffmpeg

# 编译中间文件夹
OBJECT_DIR="$ROOT/build/android/$PROJECT/object"

#安装文件夹
INSTALL_DIR="$ROOT/build/android/$PROJECT/install"

#安装路径，默认安装在当前执行目录下的${INSTALL_DIR}
PREFIX=$INSTALL_DIR

#x264安装目录
X264_INSTALL_DIR=$ROOT/build/android/x264/install

#libmp3lame安装目录
LAME_INSTALL_DIR=$ROOT/build/android/mp3lame/install

# fdk-aac 安装目录
FDK_AAC_INSTALL_DIR=$ROOT/build/android/fdkaac/install

# 缓存用户 PATH 变量
USER_PATH=$PATH

# 删除旧目录
rm -rf "$ROOT/build/android/$PROJECT"

num=${#android_toolchains[@]}
for((i=0; i<num; i++))
do
    export PATH=$TOOL_ROOT/${android_toolchains[i]}/bin:$USER_PATH

    mkdir -p $OBJECT_DIR/${android_toolchains[i]}
    cd $OBJECT_DIR/${android_toolchains[i]}

    echo "开始配置 ${android_toolchains[i]} 版本"
   
    #配置额外库头文件和库文件路径
    extra_include="-I$X264_INSTALL_DIR/${android_toolchains[i]}/include \
                    -I$LAME_INSTALL_DIR/${android_toolchains[i]}/include \
                    -I$FDK_AAC_INSTALL_DIR/${android_toolchains[i]}/include"

    extra_lib="-L$X264_INSTALL_DIR/${android_toolchains[i]}/lib \
                -L$LAME_INSTALL_DIR/${android_toolchains[i]}/lib \
                -L$FDK_AAC_INSTALL_DIR/${android_toolchains[i]}/lib"
    
    #交叉编译最重要的是配置--host、--cross-prefix、sysroot、以及extra-cflags和extra-ldflags
    $SOURCE_PATH/configure --prefix=$PREFIX/${android_toolchains[i]} \
                            ${configure} \
                            ${extra_configure[i]} \
                            $x264_configure $mp3lame_configure $fdkaac_configure \
                            --enable-cross-compile \
                            --target-os=linux \
                            --arch=${archs[i]} \
                            --cross-prefix=${cross_prefix[i]} \
                            --sysroot=$TOOL_ROOT/${android_toolchains[i]}/sysroot \
                            --extra-cflags="${extra_cflags[i]} $extra_include" \
                            --extra-ldflags="$extra_lib $extra_ldflags" \
                            || exit 1
    make clean
    echo "开始编译并安装${android_toolchains[i]}版本"
    make -j8 && make install && make clean
done