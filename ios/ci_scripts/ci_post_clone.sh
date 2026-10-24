#!/bin/sh
# Xcode Cloud: install Flutter + CocoaPods and generate everything Flutter keeps out of git.
set -ex

cd "$CI_PRIMARY_REPOSITORY_PATH"

git clone https://github.com/flutter/flutter.git --depth 1 -b 3.44.2 "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# flutter build checks for CocoaPods, so install it first.
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

flutter precache --ios

# .env is a pubspec asset but gitignored.
touch .env
flutter pub get

# Generated.xcconfig + the plugin Swift package (Flutter/ephemeral).
flutter build ios --config-only --release \
  --dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY:-}"

cd ios
pod install

# Xcode Cloud disables automatic SwiftPM resolution and requires Package.resolved.
xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner

exit 0
