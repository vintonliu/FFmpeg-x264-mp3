#########################################################################
# File Name: build-aac-ios.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 六  6/22 19:59:18 2019
#########################################################################
#!/bin/bash


if [ $# = 1 ]
then
	ARCHS="$1"
else
	ARCHS="armv7 arm64 x86_64"
fi

echo "ARCHS = $ARCHS"

# ARCHS="arm64 x86_64 armv7"

# directories
ROOT=`pwd`

SOURCE="fdk-aac-2.0.0"
PROJECT=fdkaac
LAME_PATH="$ROOT/$SOURCE"

OUTPUT_OBJECT="$ROOT/build/iOS/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/build/iOS/$PROJECT/install"

rm -rf $ROOT/build/iOS/$PROJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

FAT="$OUTPUT_INSTALL/all"
THIN="$OUTPUT_INSTALL"
BUILD_LIBS="libfdk-aac.a"

CONFIGURE_FLAGS="--enable-static --with-pic=yes --disable-shared"

DEPLOYMENT_TARGET="8.0"

CWD=`pwd`
cd $SOURCE
./autogen.sh
cd $CWD

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
			HOST=x86_64-apple-darwin
		else
			SIMULATOR="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
			HOST=i386-apple-darwin
		fi
	else
		PLATFORM="iPhoneOS"
		SIMULATOR="-mios-version-min=$DEPLOYMENT_TARGET"
		HOST=arm-apple-darwin
	fi

	XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
	CC="xcrun -sdk $XCRUN_SDK clang -arch $ARCH"
    CXX=$CC
	CFLAGS="-arch $ARCH $SIMULATOR"
	#if ! xcodebuild -version | grep "Xcode [1-6]\."
	#then
	#	CFLAGS="$CFLAGS -fembed-bitcode"
	#fi
	CXXFLAGS="$CFLAGS"
	LDFLAGS="$CFLAGS"

	CC=$CC CXX=$CC $LAME_PATH/configure --prefix="$THIN/$ARCH" \
								$CONFIGURE_FLAGS \
								--host=$HOST \
								|| exit 1
		
	# CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"

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
