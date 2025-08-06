#!/bin/bash

if [[ "$(uname -s)" == "Darwin" ]]; then
    export NDK_HOST_TAG="darwin-x86_64"
elif [[ "$(uname -s)" == "Linux" ]]; then
    export NDK_HOST_TAG="linux-x86_64"
else
    echo "Unsupported OS."
    exit
fi

#NDK=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-"$ANDROID_SDK_ROOT/ndk"}}
#COMPILER_DIR="$NDK/toolchains/llvm/prebuilt/$NDK_HOST_TAG/bin"
#export PATH="$COMPILER_DIR:$PATH"

COMPILER_DIR="/home/dgh18/commandline-tools-linux-x64-5.0.5.310/command-line-tools/sdk/default/openharmony/native/llvm/bin"
export PATH="$COMPILER_DIR:$PATH"
export CMAKE_OHOS_ARCH_ABI="arm64-v8a"

echo "$COMPILER_DIR"


export CC_aarch64_unknown_linux_ohos=$COMPILER_DIR/aarch64-unknown-linux-ohos-clang
export AR_aarch64_unknown_linux_ohos=$COMPILER_DIR/llvm-ar
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_OHOS_LINKER=$COMPILER_DIR/aarch64-unknown-linux-ohos-clang
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_OHOS_AR=$COMPILER_DIR/llvm-ar

rustup target add aarch64-unknown-linux-ohos
cargo build --target aarch64-unknown-linux-ohos --release
mv "../target/aarch64-unknown-linux-ohos/release/libisar.so" "libisar_ohos_arm64-v8a.so"