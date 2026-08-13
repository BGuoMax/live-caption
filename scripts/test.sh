#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
BUILD_DIR="$PROJECT_DIR/.build/direct-tests"
MODULE_CACHE_DIR="$PROJECT_DIR/.build/module-cache"

mkdir -p "$BUILD_DIR" "$MODULE_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-$MODULE_CACHE_DIR}
export SWIFT_MODULECACHE_PATH=${SWIFT_MODULECACHE_PATH:-$MODULE_CACHE_DIR}

SDK_PATH=${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}
if ! xcrun swiftc \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx15.0 \
    -typecheck "$PROJECT_DIR/Sources/LiveCaption/Models.swift" >/dev/null 2>&1; then
    FALLBACK_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
    if [[ -d "$FALLBACK_SDK" ]]; then
        SDK_PATH=$FALLBACK_SDK
    fi
fi

xcrun swiftc \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx15.0 \
    -swift-version 6 \
    "$PROJECT_DIR/Sources/LiveCaption/Models.swift" \
    "$PROJECT_DIR/Sources/LiveCaption/CS2Glossary.swift" \
    "$PROJECT_DIR/Tests/SmokeTests/main.swift" \
    -o "$BUILD_DIR/LiveCaptionTests"

"$BUILD_DIR/LiveCaptionTests"
