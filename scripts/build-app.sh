#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
APP_DIR="$PROJECT_DIR/dist/Live Caption.app"
CONTENTS_DIR="$APP_DIR/Contents"
BUILD_DIR="$PROJECT_DIR/.build/direct"
MODULE_CACHE_DIR="$PROJECT_DIR/.build/module-cache"

cd "$PROJECT_DIR"

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

if ! xcrun swiftc \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx15.0 \
    -typecheck "$PROJECT_DIR/Sources/LiveCaption/Models.swift" >/dev/null 2>&1; then
    print -u2 "The active Apple developer tools are inconsistent and cannot compile Foundation."
    print -u2 "Install or update Xcode, then select it with:"
    print -u2 "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

xcrun swiftc \
    -sdk "$SDK_PATH" \
    -parse-as-library \
    -swift-version 6 \
    -O \
    -target arm64-apple-macosx15.0 \
    -module-name LiveCaption \
    "$PROJECT_DIR"/Sources/LiveCaption/*.swift \
    "$PROJECT_DIR"/Sources/LiveCaption/Capture/*.swift \
    "$PROJECT_DIR"/Sources/LiveCaption/Recognition/*.swift \
    "$PROJECT_DIR"/Sources/LiveCaption/UI/*.swift \
    -framework AppKit \
    -framework AVFoundation \
    -framework CoreMedia \
    -framework ScreenCaptureKit \
    -framework Speech \
    -framework SwiftUI \
    -framework Translation \
    -o "$BUILD_DIR/LiveCaption"

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$BUILD_DIR/LiveCaption" "$CONTENTS_DIR/MacOS/LiveCaption"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
xattr -cr "$APP_DIR"
codesign \
    --force \
    --deep \
    --sign - \
    --requirements '=designated => identifier "local.live-caption.app"' \
    "$APP_DIR"

# File Provider/Finder may add these attributes as soon as an app bundle appears
# in a synced folder. They are not part of the app and make strict verification fail.
xattr -d com.apple.FinderInfo "$APP_DIR" 2>/dev/null || true
xattr -d com.apple.ResourceFork "$APP_DIR" 2>/dev/null || true
codesign --verify --deep --strict "$APP_DIR"

print "Built: $APP_DIR"
