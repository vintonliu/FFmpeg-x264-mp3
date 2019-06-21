#!/bin/sh
if [ ! -d "${ANDROID_NDK_ROOT}" ];then
echo error,no ANDROID_NDK_ROOT,set ANDROID_NDK_ROOT to NDK path
exit 1
fi

ROOT=`pwd`
OUTPUT_INSTALL="$ROOT/android/x264/install"
rm -rf $ROOT/android/x264

if [ $# = 1 ]
then
	ARCHS="$1"
else
	ARCHS="arm arm64 mipsel x86 x86_64"
fi

echo "ARCHS = $ARCHS"

TARGET_API=android-21

# ARCHS="arm"
cd x264/
for ARCH in $ARCHS; do
	echo "Building x264 for $ARCH ......"
	HOST=$ARCH-linux	
	PLATFORM_ROOT=$ANDROID_NDK_ROOT/platforms/$TARGET_API/arch-$ARCH

	if [ "$ARCH" = "arm64" ]
	then
		HOST=aarch64-linux
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/$HOST-android-4.9/prebuilt
	elif [ "$ARCH" = "mipsel" ]
	then
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/$HOST-android-4.9/prebuilt
		PLATFORM_ROOT=$ANDROID_NDK_ROOT/platforms/$TARGET_API/arch-mips
		DISABLE_ASM=--disable-asm
	elif [ "$ARCH" = "x86" ]
	then
		HOST=i686-linux
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/x86-4.9/prebuilt
		DISABLE_ASM=--disable-asm
	elif [ "$ARCH" = "x86_64" ]
	then
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/x86_64-4.9/prebuilt
		DISABLE_ASM=--disable-asm
	fi

	if [ "$ARCH" = "arm" ]
	then
		PREBUILT=$ANDROID_NDK_ROOT/toolchains/$ARCH-linux-androideabi-4.9/prebuilt
		CROSS_PREFIX=$PREBUILT/darwin-x86_64/bin/$HOST-androideabi-
		DISABLE_ASM=
	else
		CROSS_PREFIX=$PREBUILT/darwin-x86_64/bin/$HOST-android-
	fi

    mkdir -p $OUTPUT_INSTALL/$ARCH
	./configure --prefix=$OUTPUT_INSTALL/$ARCH \
						 --enable-static \
						 --enable-pic \
						 --host=$HOST\
						 --cross-prefix=$CROSS_PREFIX \
						 --sysroot=$PLATFORM_ROOT \
						 --disable-opencl \
						 $DISABLE_ASM


    make && make install && make clean
    echo "Installed: $OUTPUT_INSTALL/$ARCH"
done

cd $ROOT
