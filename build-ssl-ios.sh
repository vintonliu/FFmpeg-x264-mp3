#!/bin/sh

CONFIGURE_FLAGS="no-shared no-threads no-zlib no-hw no-krb5"

# ARCHS="arm64 x86_64 armv7"
ARCHS="arm64"

# directories
# Lib install dir.
ROOT=`pwd`
SOURCE="openssl-1.0.2o"
PROJECT=openssl
SSL_PATH="$ROOT/$SOURCE"

OUTPUT_OBJECT="$ROOT/build/iOS/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/build/iOS/$PROJECT/install"

# Remove old build and installation files.
rm -rf $ROOT/build/iOS/$PROJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

FAT="$OUTPUT_INSTALL/all"
THIN="$OUTPUT_INSTALL"
BUILD_LIBS="libssl.a"

DEPLOYMENT_TARGET="8.0"


CWD=`pwd`
for ARCH in $ARCHS
do
	echo "building $ARCH..."
	mkdir -p "$OUTPUT_OBJECT/$ARCH"
	# cd "$OUTPUT_OBJECT/$ARCH"

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
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS iphoneos-cross"
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
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$CFLAGS"

    echo $SSL_PATH
    echo $CONFIGURE_FLAGS
    export CC=$CC
    cd $SSL_PATH
	./Configure --prefix="$THIN/$ARCH" \
		$CONFIGURE_FLAGS || exit 1 

    echo "making $ARCH ..."
	make -j3 && make install && make distclean
	cd $CWD
done

echo "building fat binaries..."
mkdir -p $FAT/lib
set - $ARCHS
CWD=`pwd`

cd $THIN/$1/lib
for LIB in *.a
do
	cd $CWD
	echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
	lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
    
    echo "************************************************************"
    lipo -i $FAT/lib/LIB
    echo "************************************************************"
done

cd $CWD
cp -rf $THIN/$1/include $FAT


echo Done
