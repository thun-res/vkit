#!/usr/bin/env bash

VKIT_COMMON_ENV_CONFIGSTR=\
"\
# ================================================================================\n\
\n\
if [ -z \"\$PATH\" ] || [[ \$PATH != *\$VKIT_PREBUILT_DIR/bin* ]];then\n\
\texport PATH=\$VKIT_PREBUILT_DIR/bin:\$PATH\n\
fi\n\
\n\
if [ -z \"\$LD_LIBRARY_PATH\" ] || [[ \$LD_LIBRARY_PATH != *\$VKIT_PREBUILT_DIR/lib* ]];then\n\
\texport LD_LIBRARY_PATH=\$VKIT_PREBUILT_DIR/lib:\$LD_LIBRARY_PATH\n\
fi\n\
\n\
[ -e \$VKIT_PREBUILT_DIR/bin/vlink-info ] && export VKIT_VERSION=\$(\$VKIT_PREBUILT_DIR/bin/vlink-info -v)\n\
\n\
if [ -n \"\$BASH\" ] && [ -d \$VKIT_CODE_COMPLETE_DIR ];then\n\
\tfor code_script in \$VKIT_CODE_COMPLETE_DIR/*.sh;do\n\
\t\t[ -f \$code_script ] && . \$code_script\n\
\tdone\n\
fi\n\
\n\
[ -e \$VKIT_ETC_DIR/oem-runtime-setup.sh ] && . \$VKIT_ETC_DIR/oem-runtime-setup.sh\n\
\n\
export VLINK_TMP_DIR=\${VLINK_TMP_DIR:-\$VKIT_PREBUILT_DIR/data}\n\
export VLINK_LOG_DIR=\${VLINK_LOG_DIR:-\$VKIT_PREBUILT_DIR/data/vlink-log}\n\
export VLINK_LOCK_DIR=\${VLINK_LOCK_DIR:-\$VKIT_PREBUILT_DIR/data/vlink-lock}\n\
[ -d \$VLINK_TMP_DIR ] || mkdir -p \$VLINK_TMP_DIR\n\
[ -d \$VLINK_LOG_DIR ] || mkdir -p \$VLINK_LOG_DIR\n\
[ -d \$VLINK_LOCK_DIR ] || mkdir -p \$VLINK_LOCK_DIR\n\
\n\
# ================================================================================\n\
"

VKIT_SDK_ENV_CONFIGSTR=\
"\
#!/bin/sh\n\
\n\
if [ -n \"\$BASH_SOURCE\" ] && [ \"\$0\" = \"\$BASH_SOURCE\" ];then\n\
\techo \"Error: This script must be sourced, not executed directly.\"\n\
\texit 1\n\
fi\n\
\n\
echo -e -n \"\\\033[2J\\\033[H\"\n\
echo -e \"Setup VKIT sdk environment...\"\n\
echo -e -n \"\\\033[32m\"\n\
echo -e \"\"\n\
echo -e \"##########################################################################\"\n\
echo -e \"# Platform: $VKIT_PLATFORM\"\n\
echo -e \"# Device: $VKIT_DEVICE\"\n\
echo -e \"# Date: $(date "+%Y-%m-%d  %H:%M:%S")\"\n\
echo -e \"# Copyright (C) 2026 by Thun Lu. All rights reserved.\"\n\
echo -e \"##########################################################################\"\n\
echo -e -n \"\\\033[0m\"\n\
echo -e \"\"\n\
\n\
export VKIT_PLATFORM=\"$VKIT_PLATFORM\"\n\
\n\
export VKIT_DEVICE=\"$VKIT_DEVICE\"\n\
\n\
export VKIT_HOST_PLATFORM=\"\$(uname -s | tr '[:upper:]' '[:lower:]')-\$(uname -m | tr '[:upper:]' '[:lower:]')\"\n\
\n\
export VKIT_ROOT_DIR=\$(cd \$(dirname \${BASH_SOURCE:-\$0}) && pwd)\n\
\n\
export VKIT_HOST_DIR=\$VKIT_ROOT_DIR/host/\$VKIT_HOST_PLATFORM\n\
\n\
export VKIT_PREBUILT_DIR=\$VKIT_ROOT_DIR/target\n\
\n\
export VKIT_ETC_DIR=\$VKIT_PREBUILT_DIR/etc\n\
\n\
export VKIT_CODE_COMPLETE_DIR=\$VKIT_ETC_DIR/vkit-code-complete\n\
\n\
if [ -z \"\$PATH\" ] || [[ \$PATH != *\$VKIT_HOST_DIR/bin* ]];then\n\
\texport PATH=\$VKIT_HOST_DIR/bin:\$PATH\n\
fi\n\
\n\
if [ -z \"\$LD_LIBRARY_PATH\" ] || [[ \$LD_LIBRARY_PATH != *\$VKIT_HOST_DIR/lib* ]];then\n\
\texport LD_LIBRARY_PATH=\$VKIT_HOST_DIR/lib:\$LD_LIBRARY_PATH\n\
fi\n\
\n\
export CMAKE_TOOLCHAIN_FILE=\$VKIT_ROOT_DIR/cmake/toolchain.cmake\n\
\n\
if [ \"\$0\" != \"\$BASH_SOURCE\" ] && [ -n \"\$1\" ];then\n\
\tif [ -f \$VKIT_ROOT_DIR/vkit-toolchains/\$1/\$1_setup.sh ];then\n\
\t\t. \$VKIT_ROOT_DIR/vkit-toolchains/\$1/\$1_setup.sh\n\
\telif [ -f ~/vkit-toolchains/\$1/\$1_setup.sh ];then\n\
\t\t. ~/vkit-toolchains/\$1/\$1_setup.sh\n\
\telif [ -f /opt/vkit-toolchains/\$1/\$1_setup.sh ];then\n\
\t\t. /opt/vkit-toolchains/\$1/\$1_setup.sh\n\
\telif [ -f /opt/\$1/\$1_setup.sh ];then\n\
\t\t. /opt/\$1/\$1_setup.sh\n\
\telse\n\
\t\techo -e \"Error: Can not find \$1_setup.sh!\"\n\
\t\treturn 1\n\
\tfi\n\
fi\n\
\n\
if [ \"\$VKIT_PLATFORM\" != \"\$VKIT_HOST_PLATFORM\" ];then\n\
\treturn 0\n\
fi\n\
\n\
${VKIT_COMMON_ENV_CONFIGSTR}\n\
"


VKIT_RUNTIME_ENV_CONFIGSTR=\
"\
#!/bin/sh\n\
\n\
if [ -n \"\$BASH_SOURCE\" ] && [ \"\$0\" = \"\$BASH_SOURCE\" ];then\n\
\techo \"Error: This script must be sourced, not executed directly.\"\n\
\texit 1\n\
fi\n\
\n\
echo -e -n \"\\\033[2J\\\033[H\"\n\
echo -e \"Setup VKIT runtime environment...\"\n\
echo -e -n \"\\\033[32m\"\n\
echo -e \"\"\n\
echo -e \"##########################################################################\"\n\
echo -e \"# Platform: $VKIT_PLATFORM\"\n\
echo -e \"# Device: $VKIT_DEVICE\"\n\
echo -e \"# Date: $(date "+%Y-%m-%d  %H:%M:%S")\"\n\
echo -e \"# Copyright (C) 2026 by Thun Lu. All rights reserved.\"\n\
echo -e \"##########################################################################\"\n\
echo -e -n \"\\\033[0m\"\n\
echo -e \"\"\n\
\n\
export VKIT_PLATFORM=\"$VKIT_PLATFORM\"\n\
\n\
export VKIT_DEVICE=\"$VKIT_DEVICE\"\n\
\n\
if [ -n \"\$BASH_VERSION\" ] || [ -n \"\$ZSH_VERSION\" ];then\n\
\texport VKIT_ROOT_DIR=\$(cd \$(dirname \${BASH_SOURCE:-\$0}) && pwd)\n\
else\n\
\texport VKIT_ROOT_DIR=\$(pwd)\n\
fi\n\
\n\
export VKIT_PREBUILT_DIR=\$VKIT_ROOT_DIR\n\
\n\
export VKIT_ETC_DIR=\$VKIT_PREBUILT_DIR/etc\n\
\n\
export VKIT_CODE_COMPLETE_DIR=\$VKIT_ETC_DIR/vkit-code-complete\n\
\n\
${VKIT_COMMON_ENV_CONFIGSTR}\n\
"

function do_packup_runtime() {
    echo -e "[ do_packup_runtime ]"
    if tar --version 2>&1 | grep -qi 'gnu';then
        tar -czf $VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz -C $VKIT_PACKUP_DIR/target \
            --transform="flags=r;s|./|./vkit-${VKIT_DEVICE_PLATFORM}-runtime/|" \
            --exclude='include' \
            --exclude='share' \
            --exclude='ssl' \
            --exclude='usr' \
            --exclude='lib/include' \
            --exclude='lib/python' \
            --exclude='lib/cmake' \
            --exclude='lib/pkgconfig' \
            --exclude='lib/src' \
            --exclude='lib/source' \
            --exclude='lib/sources' \
            --exclude='lib/test' \
            --exclude='lib/tests' \
            --exclude='lib/example' \
            --exclude='lib/examples' \
            --exclude='*.a' \
            --exclude='*.la' \
            --exclude='*.sym' \
            --exclude='*.o' \
            --exclude='*.in' \
            --exclude='*.cmake' \
            --exclude='*.pc' \
            --exclude-from=$SHELL_DIR/vkit.ignore \
            ./
    else
        tar -czf $VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz -C $VKIT_PACKUP_DIR/target \
            -s "|^./|./vkit-${VKIT_DEVICE_PLATFORM}-runtime/|" \
            --exclude='include' \
            --exclude='share' \
            --exclude='ssl' \
            --exclude='usr' \
            --exclude='lib/include' \
            --exclude='lib/python' \
            --exclude='lib/cmake' \
            --exclude='lib/pkgconfig' \
            --exclude='lib/src' \
            --exclude='lib/source' \
            --exclude='lib/sources' \
            --exclude='lib/test' \
            --exclude='lib/tests' \
            --exclude='lib/example' \
            --exclude='lib/examples' \
            --exclude='*.a' \
            --exclude='*.la' \
            --exclude='*.sym' \
            --exclude='*.o' \
            --exclude='*.in' \
            --exclude='*.cmake' \
            --exclude='*.pc' \
            --exclude-from=$SHELL_DIR/vkit.ignore \
            ./
    fi
}

function do_packup_sdk() {
    echo -e "[ do_packup_sdk ]"
    if tar --version 2>&1 | grep -qi 'gnu';then
        tar -czf $VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz -C $VKIT_PACKUP_DIR \
            --transform="flags=r;s|./|./vkit-${VKIT_DEVICE_PLATFORM}-sdk/|" \
            ./
    else
        tar -czf $VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz -C $VKIT_PACKUP_DIR \
            -s "|^./|./vkit-${VKIT_DEVICE_PLATFORM}-sdk/|" \
            ./
    fi
}

function do_packup() {
    mkdir -p $VKIT_PACKUP_DIR/cmake
    mkdir -p $VKIT_PACKUP_DIR/host
    mkdir -p $VKIT_PACKUP_DIR/target
    if command -v rsync &> /dev/null;then
        rsync -a --delete  $VKIT_ROOT_DIR/cmake/ $VKIT_PACKUP_DIR/cmake/
        rsync -a --delete $VKIT_ROOT_DIR/tools/ $VKIT_PACKUP_DIR/host/
        rsync -a --delete $VKIT_PREBUILT_DIR/ $VKIT_PACKUP_DIR/target/
    else
        rm -rf $VKIT_PACKUP_DIR/cmake/* && cp -rf $VKIT_ROOT_DIR/cmake/* $VKIT_PACKUP_DIR/cmake/
        rm -rf $VKIT_PACKUP_DIR/host/* && cp -rf $VKIT_ROOT_DIR/tools/* $VKIT_PACKUP_DIR/host/
        rm -rf $VKIT_PACKUP_DIR/target/* && cp -rf $VKIT_PREBUILT_DIR/* $VKIT_PACKUP_DIR/target/
    fi
    rm -rf $VKIT_PACKUP_DIR/target/lib/engines-*
    echo -e $VKIT_SDK_ENV_CONFIGSTR > $VKIT_PACKUP_DIR/vkit-sdk-setup.sh && chmod +x $VKIT_PACKUP_DIR/vkit-sdk-setup.sh
    echo -e $VKIT_RUNTIME_ENV_CONFIGSTR > $VKIT_PACKUP_DIR/target/vkit-runtime-setup.sh && chmod +x $VKIT_PACKUP_DIR/target/vkit-runtime-setup.sh
    mkdir -p $VKIT_PACKUP_DIR/target/data
    if [ "$VKIT_PACKUP_RUNTIME" = "1" ];then
        do_packup_runtime
    fi
    if [ "$VKIT_PACKUP_SDK" = "1" ];then
        do_packup_sdk
    fi
}
