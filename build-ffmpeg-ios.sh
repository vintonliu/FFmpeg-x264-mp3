#!/bin/sh

# check h264 lib 
if [ ! -f "$(pwd)/iOS/x264/install/all/lib/libx264.a" ]; 
then
echo "no x264 lib,start to build x264"
./build-x264-ios.sh
fi

# check mp3lame lib 
if [ ! -f "$(pwd)/iOS/mp3lame/install/all/lib/libmp3lame.a" ]; 
then
echo "no mp3lame lib,start to build mp3lame"
./build-lame-ios.sh
fi

ROOT=`pwd`
PLATFORM=iOS
SOURCE="ffmpeg"
PROJECT=ffmpeg
FFMPEG_PATH="$ROOT/$SOURCE"

ARCHS="arm64 armv7 x86_64"

# absolute path to x264 library
X264="$ROOT/$PLATFORM/x264/install/all"
MP3_LAME="$ROOT/$PLATFORM/mp3lame/install/all"

OUTPUT_OBJECT="$ROOT/$PLATFORM/$PROJECT/object"
OUTPUT_INSTALL="$ROOT/$PLATFORM/$PROJECT/install"

# Remove old build and installation files.
rm -rf $ROOT/$PLATFORM/$PROJECT

mkdir -p $OUTPUT_OBJECT
mkdir -p $OUTPUT_INSTALL

FAT="$OUTPUT_INSTALL/all"
THIN=$OUTPUT_INSTALL


#FDK_AAC=`pwd`/fdk-aac/fdk-aac-ios

CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs \
                 --disable-doc --enable-pic"

if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi

if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac"
fi

if [ "$MP3_LAME" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libmp3lame --enable-decoder=mp3 --enable-encoder=libmp3lame --enable-muxer=mp3"
fi

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

DEPLOYMENT_TARGET="8.0"


if [ ! `which yasm` ]
then
	echo 'Yasm not found'
	if [ ! `which brew` ]
	then
		echo 'Homebrew not found. Trying to install...'
		ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
			|| exit 1
	fi
	echo 'Trying to install Yasm...'
	brew install yasm || exit 1
fi
if [ ! `which gas-preprocessor.pl` ]
then
	echo 'gas-preprocessor.pl not found. Trying to install...'
	(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
		-o /usr/local/bin/gas-preprocessor.pl \
		&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
		|| exit 1
fi

if [ ! -r $SOURCE ]
then
	echo 'FFmpeg source not found. Trying to download...'
	curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj \
		|| exit 1
fi

CWD=`pwd`
for ARCH in $ARCHS
do
	echo "building $ARCH..."
	mkdir -p "$OUTPUT_OBJECT/$ARCH"
	cd "$OUTPUT_OBJECT/$ARCH"

	CFLAGS="-arch $ARCH"
	if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
	then
		PLATFORM="iPhoneSimulator"
		CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
	else
		PLATFORM="iPhoneOS"
		CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET"
		if [ "$ARCH" = "arm64" ]
		then
			EXPORT="GASPP_FIX_XCODE5=1"
		fi
	fi

	XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
	CC="xcrun -sdk $XCRUN_SDK clang"
	CXXFLAGS="$CFLAGS"
	LDFLAGS="$CFLAGS"

	if [ "$X264" ]
	then
		CFLAGS="$CFLAGS -I$X264/include"
		LDFLAGS="$LDFLAGS -L$X264/lib"
	fi

	if [ "$FDK_AAC" ]
	then
		CFLAGS="$CFLAGS -I$FDK_AAC/include"
		LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
	fi

	if [ "$MP3_LAME" ]
	then
		CFLAGS="$CFLAGS -I$MP3_LAME/include"
		LDFLAGS="$LDFLAGS -L$MP3_LAME/lib"
	fi

# TMPDIR=${TMPDIR/%\/} 

	$CWD/$SOURCE/configure --prefix="$THIN/$ARCH" \
		--target-os=darwin \
		--arch=$ARCH \
		--cc="$CC" \
		$CONFIGURE_FLAGS \
		--extra-cflags="$CFLAGS" \
		--extra-cxxflags="$CXXFLAGS" \
		--extra-ldflags="$LDFLAGS" \
	|| exit 1

	make -j3 && make install && make distclean || exit 1
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
	lipo -i $FAT/lib/$LIB
	echo "************************************************************"
done

cd $CWD
cp -rf $THIN/$1/include $FAT

echo Done
