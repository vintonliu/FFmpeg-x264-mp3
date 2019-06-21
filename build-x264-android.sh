#!/bin/sh

ANDROID_NDK_ROOT=/Users/51talk/android-ndk-r17c
if [ ! -d "${ANDROID_NDK_ROOT}" ];then
echo error,no ANDROID_NDK_ROOT,set ANDROID_NDK_ROOT to NDK path
exit 1
fi

ROOT=`pwd`
SOURCE="x264"
PROJECT=x264
X264_PATH="$ROOT/$SOURCE"

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

# cd x264/
for ARCH in $ARCHS; do
	echo "Building x264 for $ARCH ......"
	mkdir -p "$OUTPUT_OBJECT/$ARCH"
	cd "$OUTPUT_OBJECT/$ARCH"

	SYSROOT=$ANDROID_NDK_ROOT/platforms/android-$API/arch-$ARCH
	ISYSROOT=$ANDROID_NDK_ROOT/sysroot
	MARCH=

	if [ "$ARCH" = "arm" ]
	then
		HOST=arm-linux-androideabi
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/arm-linux-androideabi-
		MARCH="-march=armv7-a"
	elif [ "$ARCH" = "arm64" ]
	then
		HOST=aarch64-linux-android
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/$HOST-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/aarch64-linux-android-
	elif [ "$ARCH" = "mipsel" ]
	then
		HOST=mipsel-linux-android
		DISABLE_ASM=--disable-asm
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/$HOST-4.9/prebuilt/darwin-x86_64
		SYSROOT=$ANDROID_NDK_ROOT/platforms/android-$API/arch-mips
		CROSS_PREFIX=$PREBUILT/bin/mipsel-linux-android-
	elif [ "$ARCH" = "x86" ]
	then
		HOST=i686-linux-android
		DISABLE_ASM=--disable-asm
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/x86-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/i686-linux-android-
	elif [ "$ARCH" = "x86_64" ]
	then
		HOST=x86_64-linux-android
		DISABLE_ASM=--disable-asm
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/x86_64-4.9/prebuilt/darwin-x86_64
		CROSS_PREFIX=$PREBUILT/bin/x86_64-linux-android-
	fi
	
	ECFLAGS="--sysroot=$ISYSROOT -isystem $ISYSROOT/usr/include/$HOST -D__ANDROID_API__=$API -D__ANDROID__ -DANDROID"
	ELDFLAGS="--sysroot=$SYSROOT -L$SYSROOT/usr/lib"

	$X264_PATH/configure --prefix="$OUTPUT_INSTALL/$ARCH" \
						 --enable-static \
						 --enable-pic \
						 --host=$HOST \
						 --cross-prefix=$CROSS_PREFIX \
						 --extra-cflags="$ECFLAGS" \
						 --extra-ldflags="$ELDFLAGS" \
						 --disable-opencl \
						 $DISABLE_ASM \
						 || exit 1


    make && make install && make distclean
    echo "Installed: $OUTPUT_INSTALL/$ARCH"
done

cd $ROOT