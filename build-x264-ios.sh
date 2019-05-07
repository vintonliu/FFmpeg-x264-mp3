#!/bin/sh

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli --disable-asm"

# sunminmin blog: http://depthlove.github.io/
# modified by sunminmin, 2015/09/07
ARCHS="arm64 x86_64 armv7"
#ARCHS="arm64 x86_64 armv7"

# directories
#Lib install dir.
ROOT=`pwd`
PLATFORM=iOS
PROJECT=x264

OUTPUT_OBJECT="$ROOT/$PLATFORM/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/$PLATFORM/$PROJECT/install"
X264_PATH="$ROOT/x264"
rm -rf $ROOT/$PLATFORM/$PROJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

SOURCE="$PROJECT"
FAT="$OUTPUT_INSTALL/all"

SCRATCH="$OUTPUT_INSTALL"
# must be an absolute path
THIN="$OUTPUT_INSTALL"
BUILD_LIBS="libx264.a"


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

		CC=$CC $CWD/$SOURCE/configure \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH"

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

# begin: added by sunminmin, 2015/09/07
echo "copy config.h to ..."
for ARCH in $ARCHS
do
cd $CWD
echo "copy $SCRATCH/$ARCH/config.h to $THIN/$ARCH/$include"
cp -rf $SCRATCH/$ARCH/config.h $THIN/$ARCH/$include || exit 1
done

echo "building success!"
# end: added by sunminmin, 2015/09/07

echo Done
