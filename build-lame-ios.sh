#!/bin/sh

CONFIGURE_FLAGS="--disable-shared --disable-frontend"

ARCHS="arm64 x86_64 armv7"

# directories
ROOT=`pwd`

PLATFORM=iOS
PROJECT=mp3lame
OUTPUT_OBJECT="$ROOT/$PLATFORM/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/$PLATFORM/$PROJECT/install"
rm -rf $ROOT/$PLATFORM/$PROJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

SOURCE="lame-3.100"
FAT="$OUTPUT_INSTALL/all"

SCRATCH="$OUTPUT_INSTALL"
# must be an absolute path
THIN="$OUTPUT_INSTALL"
BUILD_LIBS="libmp3lame.a"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="8.0"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

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
		CFLAGS="-arch $ARCH $SIMULATOR"
		#if ! xcodebuild -version | grep "Xcode [1-6]\."
		#then
		#	CFLAGS="$CFLAGS -fembed-bitcode"
		#fi
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		CC=$CC $CWD/$SOURCE/configure \
		    $CONFIGURE_FLAGS \
            --host=$HOST \
		    --prefix="$THIN/$ARCH"
        CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"

		make -j3 install
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
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
fi

echo "************************************************************"
lipo -i $FAT/lib/$BUILD_LIBS
echo "************************************************************"
