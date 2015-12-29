#!/bin/bash
#
# http://wiki.openssl.org/index.php/Android
#

set -e
rm -rf build

OPENSSL_VERSION=1.0.2d

if [ ! -d openssl-$OPENSSL_VERSION ] && [ -e  openssl-$OPENSSL_VERSION.tar.gz ]; then
    tar -xvf openssl-$OPENSSL_VERSION.tar.gz
fi

mkdir build

archs=(armeabi arm64-v8a x86 x86_64)

for arch in ${archs[@]}; do
    mkdir -p build/${arch}/lib

    xOPTIONS=
    xLIB="lib"
    case ${arch} in
        "armeabi")
            _ANDROID_TARGET_SELECT=arch-arm
            _ANDROID_ARCH=arch-arm
            _ANDROID_EABI=arm-linux-androideabi-4.9
            _ANDROID_API=android-19
            configure_platform="android-armv7" ;;
        "arm64-v8a")
            _ANDROID_TARGET_SELECT=arch-arm64-v8a
            _ANDROID_ARCH=arch-arm64
            _ANDROID_EABI=aarch64-linux-android-4.9
            _ANDROID_API=android-21
            configure_platform="linux-generic64 -DB_ENDIAN" ;;
        "x86")
            _ANDROID_TARGET_SELECT=arch-x86
            _ANDROID_ARCH=arch-x86
            _ANDROID_EABI=x86-4.9
            _ANDROID_API=android-21
            configure_platform="android-x86" ;;
        "x86_64")
            _ANDROID_TARGET_SELECT=arch-x86_64
            _ANDROID_ARCH=arch-x86_64
            _ANDROID_EABI=x86_64-4.9
            _ANDROID_API=android-21
            xLIB="lib64"
            xOPTIONS="no-asm"
            configure_platform="linux-generic64" ;;
    esac

    . ./setenv-android-mod.sh

    echo "CROSS COMPILE ENV : $CROSS_COMPILE"
    cd openssl-$OPENSSL_VERSION

    xCFLAGS="-fPIC -DOPENSSL_PIC -DDSO_DLFCN -DHAVE_DLFCN_H -mandroid -I$ANDROID_DEV/include -B$ANDROID_DEV/$xLIB -O3 -fomit-frame-pointer -Wall"

    perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.org
    ./Configure $xOPTIONS --openssldir=/usr/local/ssl/android-21/ $configure_platform $xCFLAGS

    make clean
    make depend
    make all

    file libcrypto.a
    file libssl.a
    cp -RL include ../build/${arch}/include
    cp libcrypto.a ../build/${arch}/lib/libprivatecrypto.a
    cp libssl.a ../build/${arch}/lib/libprivatessl.a
    cd ..
done
exit 0

