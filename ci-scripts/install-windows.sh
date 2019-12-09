#!/usr/bin/env bash

set +e

# this script is run by the git shell, not by the msys2 so we need to make a wrapper for run command inside
# msys2 shell lite pacman installs, etc... 
export msys2="cmd.exe //C RefreshEnv.cmd & C:/tools/msys64/msys2_shell.cmd -defterm -mingw64 -no-start -full-path -here -c \$\* --"

# dependencies 
choco install make
choco install protoc
choco install unzip
choco install tree
choco install python3
choco install pip
choco install gcc-arm-embedded
choco install gcc-arm
choco install cppcheck
choco install llvm

# get and install SDL2
curl http://libsdl.org/release/SDL2-devel-2.0.10-mingw.tar.gz
tar -zvzf SDL2*gz
cd SDL2-2.0.10/x86_64-w64-mingw32
# copy all .a from lib to lib
cp lib/*.a /usr/lib/
cd include
cp -r SDL2 /usr/include
cd ../bin
cp * /usr/bin

# install msys2 using chocolatey
# choco install msys2
# $msys2 pacman -Sy --noconfirm make gcc protobuf unzip python3-pip tree
# $msys2 pacman -Sy --noconfirm mingw-w64-x86_64-check
# $msys2 pacman -Sy --noconfirm mingw-w64-x86_64-SDL2
# $msys2 pacman -Sy --noconfirm mingw-w64-x86_64-protobuf-c
# $msys2 pacman -Sy --noconfirm mingw-w64-x86_64-clang

#set -e && echo "If u got error"

# debug the fylesystem structure on travis
#$msys2 tree -L 3 --filelimit 100 /c/tools/

#echo "Successfully installed all tools"

# cd /c/tools/msys64/mingw64/bin
# cp checkmk libcheck-0.dll SDL2.dll sdl2-config libprotobuf-c-1.dll protoc-c.exe protoc-gen-c.exe "/c/Program Files/Git/usr/bin"

# cd /c/tools/msys64/mingw64/include
# cp check.h check_stdint.h /usr/include/
# cp -r SDL2 google protobuf-c /usr/include/

# cd /c/tools/msys64/mingw64/lib
# cp libcheck.a libcheck.dll.a libSDL2.a libSDL2.dll.a libSDL2_test.a libSDL2main.a libprotobuf-c.a libprotobuf-c.dll.a /usr/lib/
# cp pkgconfig/sdl2.pc pkgconfig/check.pc pkgconfig/libprotobuf-c.pc /usr/lib/pkgconfig/

# cd /c/tools/msys64/mingw64/share
# cp licenses/protobuf-c/LICENSE /usr/share/licenses/
# cp aclocal/check.m4 aclocal/sdl2.m4 /usr/share/aclocal/
# cp -r doc/check /usr/share/doc/
# cp ./info/check.info.gz /usr/share/info/
# cp ./man/man1/checkmk.1.gz /usr/share/man/man1/

echo "Successfully moved all needed tools"
echo "WARNING!!! Don't forget to install Arm-None-Eabi Toolchain and ST-Link Utility"
echo "See README.md for more details"
