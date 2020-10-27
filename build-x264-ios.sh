#!/bin/sh


# directories
#Lib install dir.
CWD=`pwd`
PLATFORM=iOS
SOURCE="x264"
X264_PATH="$CWD/$SOURCE"

OUTPUT_OBJECT="$CWD/build/$PLATFORM/x264/object"
OUTPUT_INSTALL="$CWD/build/$PLATFORM/x264/install"
FAT="$OUTPUT_INSTALL/all"
THIN="$OUTPUT_INSTALL"

rm -rf $CWD/build/$PLATFORM/x264

MIN_VERSION="9.0"
CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli --disable-asm"
ARCHS="arm64 x86_64 armv7"

build_x264() {
	for ARCH in $ARCHS
	do
		echo "building x264 on $ARCH..."
		mkdir -p $OUTPUT_OBJECT/$ARCH
		cd $OUTPUT_OBJECT/$ARCH

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    if [ "$ARCH" = "x86_64" ]
		    then
		    	HOST="--host=x86_64-apple-darwin"
		    else
				HOST="--host=i386-apple-darwin"
		    fi
		else
		    PLATFORM="iPhoneOS"
		    if [ $ARCH = "arm64" ]
		    then
		        HOST="--host=aarch64-apple-darwin"
		    else
		        HOST="--host=arm-apple-darwin"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"
		CFLAGS="-arch $ARCH -miphoneos-version-min=$MIN_VERSION -Wno-error=unused-command-line-argument"
		# CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
		export CC=$CC
		$X264_PATH/configure \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" || exit 1

		make -j3 && make install
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
		# cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1

		echo "************************************************************"
		lipo -i $FAT/lib/$LIB
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
}

copy_lib() {
	echo "********* copy fdk-aac lib ********"
	DST=$CWD/../refs/ios
	cp -rf $FAT/lib/*.a $DST
}

build_x264 || exit 1
combile_lib || exit 1
copy_lib

echo Done
