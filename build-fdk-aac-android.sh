#########################################################################
# File Name: build-aac-android.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 六  6/22 22:13:15 2019
#########################################################################
#!/bin/bash

ANDROID_NDK_ROOT=~/android-ndk-r20
if [ ! -d "${ANDROID_NDK_ROOT}" ];then
echo error,no ANDROID_NDK_ROOT,set ANDROID_NDK_ROOT to NDK path
exit 1
fi

TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64

API_32=19
API_64=21
# 五种类型cpu编译链
android_abis=(
    # armeabi is no longer support build
#   "armeabi"
    "armeabi-v7a"
    "arm64-v8a"
    # "x86"
    # "x86_64"
)

platforms=(
	# "arm"
	"armv7a"
	"aarch64"
	"i686"
	"x86_64"
)

archs=(
	# "arm"
	"arm"
	"aarch64"
	"i686"
	"x86_64"
)

extra_cflags=(
    # "-march=armv5te -msoft-float -D__ANDROID__  -D__ANDROID_API__=$API -D__ARM_ARCH_5TE__ -D__ARM_ARCH_5TEJ__"
    "-march=armv7-a -mfloat-abi=softfp -mfpu=neon -mthumb -D__ANDROID__  -D__ANDROID_API__=$API_32 -D__ARM_ARCH_7__ -D__ARM_ARCH_7A__ -D__ARM_ARCH_7R__ -D__ARM_ARCH_7M__ -D__ARM_ARCH_7S__"
    "-march=armv8-a -D__ANDROID__  -D__ANDROID_API__=$API_64 -D__ARM_ARCH_8__ -D__ARM_ARCH_8A__"
    "-march=i686 -mtune=i686 -m32 -mmmx -msse2 -msse3 -mssse3 -D__ANDROID__  -D__ANDROID_API__=$API_32 -D__i686__"
    "-march=core-avx-i -mtune=core-avx-i -m64 -mmmx -msse2 -msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -D__ANDROID__  -D__ANDROID_API__=$API_64 -D__x86_64__"
)

CWD=`pwd`
SOURCE="fdk-aac-0.1.5"
SOURCE_PATH="$CWD/$SOURCE"
OUTPUT_OBJECT="$CWD/build/android/fdkaac/object"
OUTPUT_INSTALL="$CWD/build/android/fdkaac/install"

# Remove old build and installation files.
rm -rf $CWD/build/android/fdkaac

CONFIGURE_FLAGS="--enable-static \
				--disable-shared \
				--with-pic=yes"

buld_fdkaac() {
	if [ ! -f $SOURCE_PATH/configure ]
	then
		cd $SOURCE
		./autogen.sh
		cd $CWD
	fi

	num=${#android_abis[@]}
	for((i=0; i<num; i++))
	do
		echo "*******************************************"
		echo "Building fdk-aac for ${android_abis[i]} ..."
		echo "*******************************************"
		
		mkdir -p $OUTPUT_INSTALL/${android_abis[i]}
		mkdir -p $OUTPUT_OBJECT/${android_abis[i]}

		if [ "${android_abis[i]}" = "armeabi-v7a" ]
		then
			HOST=arm-linux
			CLANG_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-androideabi$API_32
		elif [ "${android_abis[i]}" = "arm64-v8a" ]
		then
			HOST=aarch64-linux-android
			CLANG_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-android$API_64
		elif [ "${android_abis[i]}" = "x86" ]
		then
			HOST=i686-linux-android
			CLANG_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-android$API_32
			CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-asm"
		elif [ "${android_abis[i]}" = "x86_64" ]
		then
			HOST=x86_64-linux-android
			CLANG_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-android$API_64
			CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-asm"
		fi

		SYSROOT=$TOOLCHAIN/sysroot
		if [ "${android_abis[i]}" = "armeabi-v7a" -o "${android_abis[i]}" = "armeabi" ]
		then
			CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi
		else
			CROSS_PREFIX=$TOOLCHAIN/bin/${platforms[i]}-linux-android
		fi

		cd $OUTPUT_OBJECT/${android_abis[i]}
		
		export CXX="$CLANG_PREFIX-clang++"
		export CC="$CLANG_PREFIX-clang"
		# export STRIP=$STRIP
		export RANLIB=$CROSS_PREFIX-ranlib
		export AR=$CROSS_PREFIX-ar
		export LDFLAGS="${extra_cflags[i]} -O3 -fPIC"
		export CFLAGS="${extra_cflags[i]} -O3 -fPIC --sysroot=${SYSROOT}"		
		
		echo "CC = $CC"
		echo "CXX = $CXX"
		echo "CFLAGS = $CFLAGS"
		echo "LDFLAGS = $LDFLAGS"

		$SOURCE_PATH/configure --prefix=$OUTPUT_INSTALL/${android_abis[i]} \
								$CONFIGURE_FLAGS \
								--host=$HOST \
								--with-sysroot=$SYSROOT || exit 1

		make -j8 && make install # && make distclean
		echo "Installed: $OUTPUT_INSTALL/${android_abis[i]}"
	done

	cd $CWD
}

copy_lib() {
	echo "*******************************************"
	echo "Copy fdkaac lib ..."
	echo "*******************************************"
    num=${#android_abis[@]}
	for((i=0; i<num; i++))
    do
        DST_LIB=$CWD/../refs/android/lib/${android_abis[i]}
        if [ ! -d $DST_LIB ]
        then
            mkdir -p $DST_LIB
        fi

        # copy lib
        cp -rf $OUTPUT_INSTALL/${android_abis[i]}/lib/*.a $DST_LIB/
    done
}

buld_fdkaac || exit 1
copy_lib || exit 1

echo "Done"