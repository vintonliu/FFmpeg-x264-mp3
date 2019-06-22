#########################################################################
# File Name: build-aac-android.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 六  6/22 22:13:15 2019
#########################################################################
#!/bin/bash

ANDROID_NDK_ROOT=/Users/vinton/android-ndk-r17c
if [ ! -d "${ANDROID_NDK_ROOT}" ];then
echo error,no ANDROID_NDK_ROOT,set ANDROID_NDK_ROOT to NDK path
exit 1
fi

ROOT=`pwd`
SOURCE="fdk-aac-2.0.0"
PROJECT=fdkaac
LAME_PATH="$ROOT/$SOURCE"

OUTPUT_OBJECT="$ROOT/build/android/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/build/android/$PROJECT/install"

# Remove old build and installation files.
rm -rf $ROOT/build/android/$PROJECT

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

for ARCH in $ARCHS; do
	echo "Building fdkaac for $ARCH ......"
	mkdir -p "$OUTPUT_OBJECT/$ARCH"
	cd "$OUTPUT_OBJECT/$ARCH"

	SYSROOT=$ANDROID_NDK_ROOT/platforms/android-$API/arch-$ARCH
	ISYSROOT=$ANDROID_NDK_ROOT/sysroot
	MARCH=

	if [ "$ARCH" = "arm" ]
	then
		HOST=arm-linux-androideabi
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/arm-linux-androideabi
		MARCH="-march=armv7-a"
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
	
	ECFLAGS="--sysroot=$ISYSROOT -isystem $ISYSROOT/usr/include/$HOST -D__ANDROID_API__=$API -D__ANDROID__ -DANDROID"
	ELDFLAGS="--sysroot=$SYSROOT -L$SYSROOT/usr/lib"

    mkdir -p $OUTPUT_INSTALL/$ARCH
	
	export PATH=$ORIGIN_PATH:$PREBUILT/bin
	echo "========================"
	echo "PATH = $PATH"
	echo "========================"
	export CFLAGS="$ECFLAGS -O3 -fPIC $MARCH"
	export LDFLAGS="$ELDFLAGS -O3 -fPIC $MARCH"	
	export CPPFLAGS="$CFLAGS"
	#export CFLAGS="$CFLAGS"
	export CXXFLAGS="$CFLAGS"
	#export LDFLAGS="$LDFLAGS"

	export AS="$CROSS_PREFIX-as"
	export LD="$CROSS_PREFIX-ld"
	export CXX="$CROSS_PREFIX-g++"
	export CC="$CROSS_PREFIX-gcc"
	export NM="$CROSS_PREFIX-nm"
	export STRIP="$CROSS_PREFIX-strip"
	export RANLIB="$CROSS_PREFIX-ranlib"
	export AR="$CROSS_PREFIX-ar"

	$LAME_PATH/configure --prefix=$OUTPUT_INSTALL/$ARCH \
						--enable-static \
                        --disable-shared \
                        --with-pic=yes \
						--host=$HOST \
						--with-sysroot=$SYSROOT \
						|| exit 1
	
	echo "CC = $CC"
	echo "CXX = $CXX"
	echo "AR = $AR"
	echo "CFLAGS = $CFLAGS"
	echo "LDFLAGS = $LDFLAGS"

    make && make install && make clean
    echo "Installed: $OUTPUT_INSTALL/$ARCH"
done

cd $ROOT