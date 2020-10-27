#!/bin/sh

CWD=`pwd`

ARCHS="arm64 armv7 x86_64"
# ARCHS="arm64"

# directories
# Lib install dir.
CWD=`pwd`
SOURCE_PATH="$CWD/openssl-1.1.0l"

OUTPUT_OBJECT="$CWD/build/iOS/openssl/object"
OUTPUT_INSTALL="$CWD/build/iOS/openssl/install"

# Remove old build and installation files.
rm -rf $CWD/build/iOS/openssl

FAT="$OUTPUT_INSTALL/all"
THIN="$OUTPUT_INSTALL"

MIN_VERSION="9.0"
CONFIGURE_FLAGS="no-shared no-threads no-zlib no-hw no-engine"

XCODEDIR=`xcode-select --print-path`

build_ssl() {
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$OUTPUT_OBJECT/$ARCH"
		cd "$OUTPUT_OBJECT/$ARCH"

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
			PLATFORM="iPhoneSimulator"
			CONFIGURE_FLAGS += " no-asm"
			if [ "$ARCH" = "x86_64" ]
			then
				SIMULATOR="-mios-simulator-version-min=$MIN_VERSION"
			else
				SIMULATOR="-mios-simulator-version-min=$MIN_VERSION"
			fi
		else
			PLATFORM="iPhoneOS"
			SIMULATOR="-mios-version-min=$MIN_VERSION"
		fi

		echo $CONFIGURE_FLAGS

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		IPHONE_OS_SDK_PATH=$(xcrun -sdk $XCRUN_SDK --show-sdk-path)
		IPHONE_OS_CROSS_TOP=${IPHONE_OS_SDK_PATH//\/SDKs*/}
		IPHONE_OS_CROSS_SDK=${IPHONE_OS_SDK_PATH##*/}

		CC="xcrun -sdk $XCRUN_SDK clang -arch $ARCH -miphoneos-version-min=$MIN_VERSION -Wno-error=unused-command-line-argument"
		
		export CC=$CC
		export CROSS_TOP=$IPHONE_OS_CROSS_TOP
		export CROSS_SDK=$IPHONE_OS_CROSS_SDK
		$SOURCE_PATH/Configure iphoneos-cross --prefix="$THIN/$ARCH" \
			$CONFIGURE_FLAGS || exit 1 

		make -j8 && make install_sw || exit 1
	done

	cd $CWD
}

combile_lib() {
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS

	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1

		echo "************************************************************"
		lipo -i $FAT/lib/$LIB
		echo "************************************************************"
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
}

# copy to link dir
copy_lib() {
	echo "********* copy ssl lib ********"
	DST=$CWD/../refs/ios/openssl
	if [ -d $DST ]
	then
		rm -rf $DST
	fi

	mkdir $DST
	cp -rf $FAT/* $DST
}

build_ssl || exit 1
combile_lib || exit 1
copy_lib

echo Done