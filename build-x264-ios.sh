#!/bin/sh

CONFIGURE_FLAGS="--disable-cli \
				--enable-static \
				--enable-pic \
				--disable-opencl \
				--enable-strip \
				--disable-win32thread \
				--bit-depth=8 \
				--disable-avs \
				--disable-swscale \
				--disable-lavf \
				--disable-ffms \
				--disable-gpac \
				--disable-lsmash"

ARCHS="arm64 armv7 x86_64"

# directories
# Lib install dir.
ROOT=`pwd`
SOURCE="x264"
PROJECT=x264
X264_PATH="$ROOT/$SOURCE"

OUTPUT_OBJECT="$ROOT/build/iOS/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/build/iOS/$PROJECT/install"

# Remove old build and installation files.
rm -rf $ROOT/build/iOS/$PROJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

FAT="$OUTPUT_INSTALL/all"
THIN="$OUTPUT_INSTALL"
BUILD_LIBS="libx264.a"

DEPLOYMENT_TARGET="9.0"

XCODEDIR=`xcode-select --print-path`

CWD=`pwd`
for ARCH in $ARCHS
do
	echo "building $ARCH..."
	mkdir -p "$OUTPUT_OBJECT/$ARCH"
	cd "$OUTPUT_OBJECT/$ARCH"
	
	MIN_VERSION=
	if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
	then
		PLATFORM="iPhoneSimulator"
		CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-asm"

		if [ "$ARCH" = "x86_64" ]
		then
			MIN_VERSION="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
			HOST="x86_64-apple-darwin"
		else
			MIN_VERSION="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
			HOST="i386-apple-darwin"
		fi
	else
		PLATFORM="iPhoneOS"
		MIN_VERSION="-mios-version-min=$DEPLOYMENT_TARGET"
		if [ $ARCH = "arm64" ]
		then
			HOST="aarch64-apple-darwin"
		else
			HOST="arm-apple-darwin"
		fi
	fi

	SYSROOT=${XCODEDIR}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk

	XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`	
	CC="xcrun -sdk $XCRUN_SDK clang"
	CFLAGS="-arch $ARCH $MIN_VERSION"
	CXXFLAGS="$CFLAGS"
	ASFLAGS="$CFLAGS"
	LDFLAGS="$CFLAGS"
	
	CC=$CC $X264_PATH/configure --prefix="$THIN/$ARCH" \
		$CONFIGURE_FLAGS \
		--sysroot=$SYSROOT \
		--host=$HOST \
		--extra-cflags="$CFLAGS" \
		--extra-asflags="$ASFLAGS"

	make -j3 && make install #&& make distclean
	cd $CWD
done

echo "building fat binaries..."
mkdir -p $FAT/lib
set - $ARCHS
CWD=`pwd`

for ARCH in $ARCHS
do
	LIPO_CREATE="$LIPO_CREATE $THIN/$ARCH/lib/$BUILD_LIBS"
done

lipo -create $LIPO_CREATE -output $FAT/lib/$BUILD_LIBS

cd $CWD
cp -rf $THIN/$1/include $FAT

echo "************************************************************"
lipo -i $FAT/lib/$BUILD_LIBS
echo "************************************************************"

echo Done
