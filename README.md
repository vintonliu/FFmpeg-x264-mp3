# FFmpeg-x264-mp3
ffmpeg with x264 and mp3 build script for ios

test ok for FFmpeg release/4.1, lame3.100 and x264 stable code.

## Issue about ndk r17c
- x264 build not found limits.h
```
arm-linux-androideabi/4.9.x/include-fixed/limits.h:168:61: error: no include path in which to search for limits.h
 #include_next <limits.h>  /* recurse down to the real one */
```
see https://android.googlesource.com/platform/ndk/+/ndk-r15-release/docs/UnifiedHeaders.md