# FFmpeg-x264-mp3
ffmpeg with x264 and mp3 build on IOS and Android 

## Environment
- OS: MAC 10.14.5
- IDE:
    
    Xcode 10.2.1

    NDK r17c

## Sources
    FFmpeg release/4.1

    Lame 3.100

    x264  5493be84cdccecee613236c31b1e3227681ce428

## Prepare
```
    brew install automake
    brew install libtool
```

## Usage
### x264
- IOS
```
./build-x264-ios.sh
```

- Android
```
./android_build_x264.sh
```

### LameMP3
- IOS
```
./build-lame-ios.sh
```

- Android
```
./android_build_lame.sh
```

### FdkAAC
- IOS
```
./build-aac-ios.sh
```

- Android
```
./android_build_aac.sh
```

### FFmpeg
- IOS
```
./build-ffmpeg-ios.sh
```
- Android
```
./android_build_ffmpeg.sh
```

## Issue about ndk r17c
- x264 build not found limits.h
```
arm-linux-androideabi/4.9.x/include-fixed/limits.h:168:61: error: no include path in which to search for limits.h
 #include_next <limits.h>  /* recurse down to the real one */
```
see https://android.googlesource.com/platform/ndk/+/ndk-r15-release/docs/UnifiedHeaders.md