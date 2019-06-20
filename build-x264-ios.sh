#!/bin/sh

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli --disable-asm"

ARCHS="arm64 x86_64 armv7"

# directories
#Lib install dir.
ROOT=`pwd`
PLATFORM=iOS
SOURCE="x264"
PROJECT=x264
X264_PATH="$ROOT/$SOURCE"

OUTPUT_OBJECT="$ROOT/$PLATFORM/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/$PLATFORM/$PROJECT/install"

# Remove old build and installation files.
rm -rf $ROOT/$PLATFORM/$PROJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

FAT="$OUTPUT_INSTALL/all"
THIN="$OUTPUT_INSTALL"
BUILD_LIBS="libx264.a"

DEPLOYMENT_TARGET="8.0"


CWD=`pwd`
for ARCH in $ARCHS
do
	echo "building $ARCH..."
	mkdir -p "$OUTPUT_OBJECT/$ARCH"
	cd "$OUTPUT_OBJECT/$ARCH"

	if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
	then
		PLATFORM="iPhoneSimulator"
		if [ "$ARCH" = "x86_64" ]
		then
			SIMULATOR="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
			HOST="--host=x86_64-apple-darwin"
		else
			SIMULATOR="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
			HOST="--host=i386-apple-darwin"
		fi
	else
		PLATFORM="iPhoneOS"
		SIMULATOR="-mios-version-min=$DEPLOYMENT_TARGET"
		if [ $ARCH = "arm64" ]
		then
			HOST="--host=aarch64-apple-darwin"
		else
			HOST="--host=arm-apple-darwin"
		fi
	fi

	XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
	CC="xcrun -sdk $XCRUN_SDK clang -Wno-error=unused-command-line-argument -arch $ARCH"
	CFLAGS="-arch $ARCH $SIMULATOR"
	CXXFLAGS="$CFLAGS"
	LDFLAGS="$CFLAGS"

	CC=$CC $X264_PATH/configure --prefix="$THIN/$ARCH" \
		$CONFIGURE_FLAGS \
		--extra-cflags="$CFLAGS"

	make -j3 && make install && make distclean
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
