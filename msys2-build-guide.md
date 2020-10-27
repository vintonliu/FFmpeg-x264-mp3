# MSYS2 build guide

## 1. Install MSYS2
- Download [MSYS2](http://www.msys2.org/), [msys2-x86_64-{date}.exe](http://www.msys2.org/);
- Install into c:/msys64;
- Edit c:/msys64/msys2_shell.cmd and remove rem from the line with rem set MSYS2_PATH_TYPE=inherit;
- Open a x86 Native Tools Command Prompt for VS 2017;
- Run c:/msys64/msys2_shell.cmd will auto open MSYS2 shell window;
- Use the MSYS2 shell for the next steps and enter:

```bash
pacman -Syu
pacman -S make
pacman -S diffutils
pacman -S yasm
pacman -S nasm
pacman -S msys/libtool
pacman -S msys/autoconf
pacman -S msys/automake-wrapper

mv /usr/bin/link.exe /usr/bin/link.exe.bak
```

2. Build Fdk-aac

```bash
cd <Path>/acsdk/acme/umcs2/ffmpeg
./build-fdk-aac-win.sh
```

3. 