#########################################################################
# File Name: build_x264_android_clang.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 一  9/14 17:28:18 2020
#########################################################################
#!/bin/bash

ROOT=`pwd`

#当前目录下x264源文件目录
if [ ! -d "x264" ]
then
    echo "下载x264源文件"
    git clone https://code.videolan.org/videolan/x264.git
fi

#配置交叉编译链
export NDK_ROOT=~/android-ndk-r20

# 五种类型cpu编译链
android_toolchains=(
   # "armeabi"
   "armeabi-v7a"
   "arm64-v8a"
   # "x86"
   # "x86_64"
)

# 优化编译项
API=19
API_64=21
extra_cflags=(
   # "-march=armv5te -msoft-float -D__ANDROID__ -D__ANDROID_API__=$API -D__ARM_ARCH_5TE__ -D__ARM_ARCH_5TEJ__"
   "-march=armv7-a -mfloat-abi=softfp -mfpu=neon -mthumb -D__ANDROID__ -D__ANDROID_API__=$API -D__ARM_ARCH_7__ -D__ARM_ARCH_7A__ -D__ARM_ARCH_7R__ -D__ARM_ARCH_7M__ -D__ARM_ARCH_7S__"
   "-march=armv8-a -D__ANDROID__ -D__ANDROID_API__=$API_64 -D__ARM_ARCH_8__ -D__ARM_ARCH_8A__"
   "-march=i686 -mtune=i686 -m32 -mmmx -msse2 -msse3 -mssse3 -D__ANDROID__ -D__ANDROID_API__=$API -D__i686__"
   "-march=core-avx-i -mtune=core-avx-i -m64 -mmmx -msse2 -msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -D__ANDROID__ -D__ANDROID_API__=$API_64 -D__x86_64__"
)

# extra_ldflags="-nostdlib"

#针对各版本不同的编译项
   #"--disable-asm"
extra_configure=(
   # "--disable-asm"
   ""
   ""
   ""
   ""
)
#交叉编译后的运行环境
hosts=(
#   "arm-linux-androideabi"
  "arm-linux-androideabi"
  "aarch64-linux-android"
  "i686-linux-android"
  "x86_64-linux-android"
)
#交叉编译工具前缀
cross_prefix=(
#   "arm-linux-androideabi-"
  "arm-linux-androideabi"
  "aarch64-linux-android"
  "i686-linux-android"
  "x86_64-linux-android"
)

PROJECT=x264
SOURCE_PATH=$ROOT/x264

# 编译中间文件夹
OBJECT_DIR="$ROOT/build/android/$PROJECT/object"

#安装文件夹
INSTALL_DIR="$ROOT/build/android/$PROJECT/install"

# 缓存用户 PATH 变量
USER_PATH=$PATH

# 删除旧目录
rm -rf "$ROOT/build/android/$PROJECT"

HOST_TAG=darwin-x86_64
TOOLCHAIN=$NDK_ROOT/toolchains/llvm/prebuilt/$HOST_TAG

#共同配置项,可以额外增加相关配置，详情可查看源文件目录下configure
# --enable-shared
configure="--disable-cli \
           --enable-static \
           --enable-pic \
           --disable-opencl \
           --enable-strip \
           --disable-win32thread \
           --disable-avs \
           --disable-swscale \
           --disable-lavf \
           --disable-ffms \
           --disable-gpac \
           --bit-depth=all \
           --disable-lsmash"

num=${#android_toolchains[@]}
for((i=0; i<num; i++))
do
    echo "开始配置 ${android_toolchains[i]} 版本"

    MIN_API=19
    if [ "${android_toolchains[i]}" = "arm64-v8a" ]
    then
        MIN_API=21
        export CC=$TOOLCHAIN/bin/aarch64-linux-android$MIN_API-clang
        export CXX=$TOOLCHAIN/bin/aarch64-linux-android$MIN_API-clang++
    elif [ "${android_toolchains[i]}" = "armeabi-v7a" ]
    then
        export CC=$TOOLCHAIN/bin/armv7a-linux-androideabi$MIN_API-clang
        export CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi$MIN_API-clang++
    fi
    
    export AR=$TOOLCHAIN/bin/${cross_prefix[i]}-ar
    # export AS=$TOOLCHAIN/bin/${cross_prefix[i]}-as
    export LD=$TOOLCHAIN/bin/${cross_prefix[i]}-ld
    export NM=$TOOLCHAIN/bin/${cross_prefix[i]}-nm
    export RANLIB=$TOOLCHAIN/bin/${cross_prefix[i]}-ranlib
    export STRIP=$TOOLCHAIN/bin/${cross_prefix[i]}-strip
    echo "-----------------------------"
    echo "CC=$CC"
    echo "CXX=$CXX"


    mkdir -p $OBJECT_DIR/${android_toolchains[i]}
    cd $OBJECT_DIR/${android_toolchains[i]}

    #交叉编译最重要的是配置--host、--cross-prefix、sysroot、以及extra-cflags和extra-ldflags
    $SOURCE_PATH/configure --prefix=$INSTALL_DIR/${android_toolchains[i]} \
                            ${configure} \
                            ${extra_configure[i]} \
                            --host=${hosts[i]} \
                            --sysroot=$TOOLCHAIN/sysroot \
                            --extra-cflags="${extra_cflags[i]}" \
                            --extra-ldflags="$extra_ldflags" \
                            || exit 1
    make clean
    echo "开始编译并安装 ${android_toolchains[i]} 版本"
    make -j8 && make install #&& make distclean
done
