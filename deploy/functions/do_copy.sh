#!/usr/bin/env bash

function do_copy() {
    echo -e "[ do_copy ]"
    if [ -n "$VKIT_PLATFORM_DEPLOY_DIR" ] && [ -d "$VKIT_PLATFORM_DEPLOY_DIR" ];then
        cp -rf $VKIT_PLATFORM_DEPLOY_DIR/* $VKIT_PREBUILT_DIR/
    fi
    if [ -n "$VKIT_SETUP_DIR" ] && [ -d "$VKIT_SETUP_DIR" ];then
        cp -rf $VKIT_SETUP_DIR/* $VKIT_PREBUILT_DIR/etc/
    fi
    if [ "$VKIT_PLATFORM" = "qnx-aarch64" ];then
        cp -rf $QNX_TARGET/aarch64le/usr/lib/libsqlite3.so* $VKIT_PREBUILT_DIR/lib/
        cp -rf $QNX_TARGET/aarch64le/usr/lib/libicui18n.so* $VKIT_PREBUILT_DIR/lib/
        cp -rf $QNX_TARGET/aarch64le/usr/lib/libicuuc.so* $VKIT_PREBUILT_DIR/lib/
        cp -rf $QNX_TARGET/aarch64le/usr/lib/libicudata.so* $VKIT_PREBUILT_DIR/lib/
        rm -rf $VKIT_PREBUILT_DIR/lib/*.sym
    elif [ "$VKIT_PLATFORM" = "qnx-x86_64" ];then
        cp -rf $QNX_TARGET/x86_64/usr/lib/libsqlite3.so* $VKIT_PREBUILT_DIR/lib/
        cp -rf $QNX_TARGET/x86_64/usr/lib/libicui18n.so* $VKIT_PREBUILT_DIR/lib/
        cp -rf $QNX_TARGET/x86_64/usr/lib/libicuuc.so* $VKIT_PREBUILT_DIR/lib/
        cp -rf $QNX_TARGET/x86_64/usr/lib/libicudata.so* $VKIT_PREBUILT_DIR/lib/
        rm -rf $VKIT_PREBUILT_DIR/lib/*.sym
    elif [ "$VKIT_PLATFORM" = "android-aarch64" ];then
        cp -rf $ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
        $VKIT_PREBUILT_DIR/lib/
    elif [ "$VKIT_PLATFORM" = "android-x86_64" ];then
        cp -rf $ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so \
        $VKIT_PREBUILT_DIR/lib/
    fi
    [ -f $VKIT_PREBUILT_EXT_DIR/bin/iox-roudi ] && cp -rf $VKIT_PREBUILT_EXT_DIR/bin/iox-roudi $VKIT_PREBUILT_DIR/bin/
    [ -f $VKIT_PREBUILT_EXT_DIR/bin/iox-introspection-client ] && cp -rf $VKIT_PREBUILT_EXT_DIR/bin/iox-introspection-client $VKIT_PREBUILT_DIR/bin/
    [ -L $VKIT_PREBUILT_EXT_DIR/bin/fast-discovery-server ] && cp -rf $VKIT_PREBUILT_EXT_DIR/bin/fast-discovery-server-* $VKIT_PREBUILT_DIR/bin/fast-discovery-server
}
