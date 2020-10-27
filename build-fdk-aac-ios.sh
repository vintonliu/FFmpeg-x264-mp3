#!/bin/sh

CWD=`pwd`

PLATFORM=iOS
SOURCE="fdk-aac-0.1.5"
SOURCE_PATH="$CWD/$SOURCE"

OUTPUT_OBJECT="$CWD/build/$PLATFORM/fdk-aac/object"
OUTPUT_INSTALL="$CWD/build/$PLATFORM/fdk-aac/install"
FAT="$OUTPUT_INSTALL/all"
THIN="$OUTPUT_INSTALL"

rm -rf $CWD/build/$PLATFORM/fdk-aac

MIN_VERSION="9.0"
CONFIGURE_FLAGS="--enable-static \
				--disable-shared \
				--with-pic=yes"

ARCHS="arm64 x86_64 armv7"

build_fdkaac() {
	if [ ! -f $SOURCE_PATH/configure ]
	then
		cd $SOURCE
		./autogen.sh
		cd $CWD
	fi

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
                HOST=x86_64-apple-darwin
		    else
                HOST=i386-apple-darwin
		    fi
		else
		    PLATFORM="iPhoneOS"
            HOST=arm-apple-darwin
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang -arch $ARCH -miphoneos-version-min=$MIN_VERSION"
		CXX=$CC
		export CC=$CC
		export CXX=$CXX

		$SOURCE_PATH/configure --prefix="$THIN/$ARCH" \
		    $CONFIGURE_FLAGS \
            --host=$HOST || exit 1

		make -j8 install
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

build_fdkaac || exit 1
combile_lib || exit 1
copy_lib