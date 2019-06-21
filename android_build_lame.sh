#########################################################################
# File Name: android_build_lame.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 五  6/21 10:44:26 2019
#########################################################################
#!/bin/bash

ROOT=`pwd`

if [ ! -d "lame-3.100" ]
then
   # echo "解压 lame-3.100 源文件"
    wget https://nchc.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
    tar -xjvf lame-3.100.tar.gz
fi

#配置交叉编译链
export TOOL_ROOT=$ROOT/android-toolchain

# 五种类型cpu编译链
android_toolchains=(
    "armeabi"
    "armeabi-v7a"
    "arm64-v8a"
    "x86"
    "x86_64"
)

#优化编译项
API=23
extra_cflags=(
    "-march=armv5te -msoft-float -D__ANDROID__  -D__ANDROID_API__=$API -D__ARM_ARCH_5TE__ -D__ARM_ARCH_5TEJ__"
    "-march=armv7-a -mfloat-abi=softfp -mfpu=neon -mthumb -D__ANDROID__  -D__ANDROID_API__=$API -D__ARM_ARCH_7__ -D__ARM_ARCH_7A__ -D__ARM_ARCH_7R__ -D__ARM_ARCH_7M__ -D__ARM_ARCH_7S__"
    "-march=armv8-a -D__ANDROID__  -D__ANDROID_API__=$API -D__ARM_ARCH_8__ -D__ARM_ARCH_8A__"
    "-march=i686 -mtune=i686 -m32 -mmmx -msse2 -msse3 -mssse3 -D__ANDROID__  -D__ANDROID_API__=$API -D__i686__"
    "-march=core-avx-i -mtune=core-avx-i -m64 -mmmx -msse2 -msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -D__ANDROID__  -D__ANDROID_API__=$API -D__x86_64__"
)

# extra_ldflags="-nostdlib"

#共同配置项,可以额外增加相关配置，详情可查看源文件目录下configure
configure="--enable-static \
            --disable-shared \
            --disable-frontend"

#针对各版本不同的编译项
extra_configure=(
    "--disable-asm"
    ""
    ""
    "--disable-asm"
    "--disable-asm"
)
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

PROJECT=mp3lame
SOURCE_PATH="$ROOT/lame-3.100"

# 编译中间文件夹
OBJECT_DIR="$ROOT/build/android/$PROJECT/object"

#安装文件夹
INSTALL_DIR="$ROOT/build/android/$PROJECT/install"
PREFIX_DIR=$INSTALL_DIR

# 缓存用户 PATH 变量
USER_PATH=$PATH

# 删除旧目录
rm -rf "$ROOT/build/android/$PROJECT"

num=${#android_toolchains[@]}
for((i=0; i<num; i++))
do
    export PATH=$TOOL_ROOT/${android_toolchains[i]}/bin:$USER_PATH
    # echo "PATH=$PATH"
    
    mkdir -p $OBJECT_DIR/${android_toolchains[i]}
    cd $OBJECT_DIR/${android_toolchains[i]}

    echo "开始配置 ${android_toolchains[i]} 版本"
    export CFLAGS="${extra_cflags[i]} -O3 -fPIC"
	export LDFLAGS="$extra_ldflags -O3 -fPIC"	
	export CPPFLAGS="$CFLAGS"
	export CXXFLAGS="$CFLAGS"
	
	export AS="${cross_prefix[i]}as"
	export LD="${cross_prefix[i]}ld"
	export CXX="${cross_prefix[i]}g++"
	export CC="${cross_prefix[i]}gcc"
	export NM="${cross_prefix[i]}nm"
	export STRIP="${cross_prefix[i]}strip"
	export RANLIB="${cross_prefix[i]}ranlib"
	export AR="${cross_prefix[i]}ar"

    #交叉编译最重要的是配置--host、--cross-prefix、sysroot、以及extra-cflags和extra-ldflags
    $SOURCE_PATH/configure --prefix=$PREFIX_DIR/${android_toolchains[i]} \
                            ${configure} \
                            --host=${hosts[i]} \
                            --with-sysroot=$TOOL_ROOT/${android_toolchains[i]}/sysroot \
                            || exit 1
    make clean
    echo "开始编译并安装 ${android_toolchains[i]} 版本"
    make -j8 && make install && make distclean
done