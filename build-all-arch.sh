#!/bin/bash
#
# http://wiki.openssl.org/index.php/Android

set -e

ARCHS=(android-arm android-arm64 android-x86 android-amd64)
OPENSSL_VERSION="1.0.2o"
CURRENT_DIR=$(pwd)
OUTPUT_DIR="$CURRENT_DIR/output/$OPENSSL_VERSION"
SYSROOT_INCLUDE="$ANDROID_NDK_ROOT/sysroot/usr/include"

rm -rf $OUTPUT_DIR

if [[ ! -s "openssl-$OPENSSL_VERSION.tar.gz" ]]; then
    printf "Downloading OpenSSL-%s\n" $OPENSSL_VERSION
    curl -L -o "openssl-$OPENSSL_VERSION.tar.gz" \
        https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
fi

if [ ! -d openssl-$OPENSSL_VERSION ] && [ -e  openssl-$OPENSSL_VERSION.tar.gz ]; then
    tar -xvf openssl-$OPENSSL_VERSION.tar.gz
fi

for arch in ${ARCHS[@]}; do
    printf "Building %s\n" $arch

    OPTIONS="shared no-ssl2 no-ssl3 no-comp no-hw no-engine no-asm"
    LIB="lib"
    case ${arch} in
        "android-arm")
            API_NUMBER=19
            PLATFORM_INCLUDES="arm-linux-androideabi"
            _ANDROID_TARGET_SELECT="arch-arm"
            _ANDROID_ARCH="arch-arm"
            _ANDROID_EABI="arm-linux-androideabi-4.9"
            _ANDROID_API="android-$API_NUMBER"
            configure_platform="android-armv7"
            ;;
        "android-arm64")
            API_NUMBER=21
            PLATFORM_INCLUDES="aarch64-linux-android"
            _ANDROID_TARGET_SELECT="arch-arm64-v8a"
            _ANDROID_ARCH="arch-arm64"
            _ANDROID_EABI="aarch64-linux-android-4.9"
            _ANDROID_API="android-$API_NUMBER"
            OPTIONS="$OPTIONS -fomit-frame-pointer -DB_ENDIAN"
            configure_platform="linux-generic64"
            ;;
        "android-x86")
            API_NUMBER=19
            PLATFORM_INCLUDES="i686-linux-android"
            _ANDROID_TARGET_SELECT="arch-x86"
            _ANDROID_ARCH="arch-x86"
            _ANDROID_EABI="x86-4.9"
            _ANDROID_API="android-$API_NUMBER"
            configure_platform="android-x86"
            ;;
        "android-amd64")
            API_NUMBER=21
            PLATFORM_INCLUDES="x86_64-linux-android"
            _ANDROID_TARGET_SELECT="arch-x86_64"
            _ANDROID_ARCH="arch-x86_64"
            _ANDROID_EABI="x86_64-4.9"
            _ANDROID_API="android-$API_NUMBER"
            LIB="lib64"
            #OPTIONS="$OPTIONS no-asm"
            configure_platform="linux-generic64"
            ;;
    esac

    . ./setenv-android-mod.sh

    cd openssl-$OPENSSL_VERSION

    CFLAGS="-D__ANDROID_API__=$API_NUMBER -I$SYSROOT_INCLUDE -I$SYSROOT_INCLUDE/$PLATFORM_INCLUDES -B$ANDROID_DEV/$LIB"

    perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.org

    ./Configure $OPTIONS $configure_platform \
        --openssldir=/usr/local/ssl/$_ANDROID_API \
        $CFLAGS \
        &> $arch.log

    make clean >> $arch.log 2>&1
    make CALC_VERSIONS="SHLIB_COMPAT=; SHLIB_SOVER=" depend >> $arch.log 2>&1
    make CALC_VERSIONS="SHLIB_COMPAT=; SHLIB_SOVER=" all >> $arch.log 2>&1

    file libcrypto.a
    file libssl.a

    mkdir -p $OUTPUT_DIR/lib/${arch}
    mkdir -p $OUTPUT_DIR/include/${arch}
    cp -RL include/openssl $OUTPUT_DIR/include/$arch/openssl
    cp libcrypto.a $OUTPUT_DIR/lib/${arch}/libcrypto.a
    cp libssl.a $OUTPUT_DIR/lib/${arch}/libssl.a
    printf "Finished\n\n"
    cd ..
done
exit 0

