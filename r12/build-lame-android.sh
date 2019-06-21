#!/bin/sh
if [ ! -d "${ANDROID_NDK_ROOT}" ];then
echo error,no ANDROID_NDK_ROOT,set ANDROID_NDK_ROOT to NDK path
exit 1
fi

ROOT=`pwd`
OUTPUT_INSTALL="$ROOT/android/mp3lame/install"
rm -rf $ROOT/android/mp3lame

if [ $# = 1 ]
then
	ARCHS="$1"
else
	ARCHS="arm arm64 mipsel x86 x86_64"
fi

echo "ARCHS = $ARCHS"

TARGET_API=android-21
ORIGIN_PATH=$PATH

cd lame-3.100/
for ARCH in $ARCHS; do
	echo "Building mp3lame for $ARCH ......"
	
	PLATFORM=$ANDROID_NDK_ROOT/platforms/$TARGET_API/arch-$ARCH
	MARCH=

	if [ "$ARCH" = "arm" ]
	then
		HOST=arm-linux
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
	
	export PATH=$ORIGIN_PATH:$PREBUILT/bin:$PLATFORM/usr/include:
	echo "========================"
	echo "PATH = $PATH"
	echo "========================"
	export LDFLAGS="-L$PLATFORM/usr/lib -O3 -fPIC $MARCH"
	export CFLAGS="-I$PLATFORM/usr/include -O3 -fPIC --sysroot=${PLATFORM} $MARCH"
	export CPPFLAGS="$CFLAGS"
	export CFLAGS="$CFLAGS"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$LDFLAGS"

	export AS="$CROSS_PREFIX-as"
	export LD="$CROSS_PREFIX-ld"
	export CXX="$CROSS_PREFIX-g++"
	export CC="$CROSS_PREFIX-gcc"
	export NM="$CROSS_PREFIX-nm"
	export STRIP="$CROSS_PREFIX-strip"
	export RANLIB="$CROSS_PREFIX-ranlib"
	export AR="$CROSS_PREFIX-ar"

	./configure --prefix=$OUTPUT_INSTALL/$ARCH \
						--enable-static \
						--disable-shared \
						--disable-frontend \
						--host=$HOST
	
	echo "CC = $CC"
	echo "CXX = $CXX"
	echo "AR = $AR"
	echo "CFLAGS = $CFLAGS"
	echo "LDFLAGS = $LDFLAGS"

    make && make install && make clean
    echo "Installed: $OUTPUT_INSTALL/$ARCH"
done

cd $ROOT