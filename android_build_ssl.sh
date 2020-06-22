#########################################################################
# File Name: android_build_ssl.sh
# Author: liuwch
# mail: liuwenchang1234@gmail.com
# Created Time: 五  6/21 10:43:25 2019
#########################################################################
#!/bin/bash

BUILD_MODE=Release
LINK_MODE=static

while getopts ":ds" opt
do
   case $opt in
      d)
      BUILD_MODE=Debug
      ;;
      s)
      LINK_MODE=shared
      ;;
      *)
      echo "build release and static"      
      ;;
   esac
done

echo "BUILD_MODE=$BUILD_MODE"
echo "LINK_MODE=$LINK_MODE"

#配置交叉编译链
export ANDROID_NDK_HOME=~/android-ndk-r17c

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
   "-march=armv5te -msoft-float -D__ANDROID__ -D__ANDROID_API__=$API -D__ARM_ARCH_5TE__ -D__ARM_ARCH_5TEJ__"
   "-march=armv7-a -mfloat-abi=softfp -mfpu=neon -mthumb -D__ANDROID__ -D__ANDROID_API__=$API -D__ARM_ARCH_7__ -D__ARM_ARCH_7A__ -D__ARM_ARCH_7R__ -D__ARM_ARCH_7M__ -D__ARM_ARCH_7S__"
   "-march=armv8-a -D__ANDROID__ -D__ANDROID_API__=$API -D__ARM_ARCH_8__ -D__ARM_ARCH_8A__"
   "-march=i686 -mtune=i686 -m32 -mmmx -msse2 -msse3 -mssse3 -D__ANDROID__ -D__ANDROID_API__=$API -D__i686__"
   "-march=core-avx-i -mtune=core-avx-i -m64 -mmmx -msse2 -msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -D__ANDROID__ -D__ANDROID_API__=$API -D__x86_64__"
)

# extra_ldflags="-nostdlib"

#共同配置项,可以额外增加相关配置，详情可查看源文件目录下configure
configure="no-asm"
if [ "$LINK_MODE" = "static" ]
then
   configure="$configure no-shared" 
fi

if [ "$BUILD_MODE" = "Debug" ]
then
   debug_flag=debug-
fi

echo "debug_flag=$debug_flag"

#交叉编译工具前缀
cross_prefix=(
  "arm-linux-androideabi-"
  "arm-linux-androideabi-"
  "aarch64-linux-android-"
  "i686-linux-android-"
  "x86_64-linux-android-"
)

cross_toolchain=(
   "arm-linux-androideabi-4.9"
   "arm-linux-androideabi-4.9"
   "aarch64-linux-android-4.9"
   "x86-4.9"
   "x86_64-4.9"
)

cfg_target=(
    "android-arm"
    "android-arm"
    "android-arm64"
    "android-x86"
    "android-x86_64"
)

CWD=`pwd`
PROJECT=openssl
SOURCE_PATH=$CWD

# 编译中间文件夹
OBJECT_DIR="$CWD/build/android/$PROJECT/$BUILD_MODE/object"

#安装文件夹
INSTALL_DIR="$CWD/build/android/$PROJECT/$BUILD_MODE/install"

# 缓存用户 PATH 变量
USER_PATH=$PATH

# 删除旧目录
rm -rf "$CWD/build/android/$PROJECT"

num=${#android_toolchains[@]}
for((i=0; i<num; i++))
do
   export PATH=$ANDROID_NDK_HOME/toolchains/${cross_toolchain[i]}/prebuilt/darwin-x86_64/bin:$USER_PATH
   # echo "PATH=$PATH"
   
   # create build temp dir
   mkdir -p $OBJECT_DIR/${android_toolchains[i]}
   cd $OBJECT_DIR/${android_toolchains[i]}

   echo "开始配置 ${android_toolchains[i]} 版本"
   $SOURCE_PATH/Configure --prefix=$INSTALL_DIR/${android_toolchains[i]} \
                           ${configure} $debug_flag${cfg_target[i]} \
                           ${extra_cflags[i]} \
                           || exit 1
   
   if [ $LINK_MODE = "shared" ]
   then
      # patch SONAME
      perl -pi -e 's/SHLIB_EXT=\.so\.\$\(SHLIB_VERSION_NUMBER\)/SHLIB_EXT=\.so/g' Makefile
      perl -pi -e 's/SHARED_LIBS_LINK_EXTS=\.so\.\$\(SHLIB_MAJOR\)\.so//g' Makefile
      perl -pi -e 's/SHLIB_EXT_SIMPLE=\.so/SHLIB_EXT_SIMPLE=\.so\.\$\(SHLIB_VERSION_NUMBER\)/g' Makefile
      # quote injection for proper SONAME, fuck...
      # perl -pi -e 's/SHLIB_MAJOR=1/SHLIB_MAJOR=`/g' Makefile
      # perl -pi -e 's/SHLIB_MINOR=1/SHLIB_MINOR=`/g' Makefile
   fi

   make clean
   echo "开始编译并安装 ${android_toolchains[i]} 版本"
   make -j8 && make install_sw
done
