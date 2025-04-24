#!/bin/bash

# 设置输出目录
BUILD_DIR="build"
APP_NAME="KeyCount"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# 创建构建目录
mkdir -p "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/"{MacOS,Resources}

# 构建发布版本
swift build -c release --build-path "$BUILD_DIR"

# 复制可执行文件
cp "$BUILD_DIR/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# 创建 Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>需要访问辅助功能以监控键盘输入</string>
    <key>NSInputMonitoringUsageDescription</key>
    <string>需要监控键盘输入以统计按键次数</string>
</dict>
</plist>
EOF

echo "构建完成！应用程序包位于: $APP_BUNDLE"
echo "您可以将应用程序拖到应用程序文件夹中使用。" 