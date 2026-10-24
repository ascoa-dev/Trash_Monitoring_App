#!/bin/sh
# Xcode Cloud: install Flutter + CocoaPods and generate everything Flutter keeps out of git.
set -ex

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Xcode Cloud turns off automatic SwiftPM resolution, but Flutter resolves its plugin
# package during the build below. Allow it here; the Package.resolved files written
# by this script satisfy the archive step that runs afterwards.
defaults write com.apple.dt.Xcode IDEPackageOnlyUseVersionsFromResolvedFile -bool NO
defaults write com.apple.dt.Xcode IDEDisableAutomaticPackageResolution -bool NO

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
# Same file next to the project too, in case the archive resolves via the project.
mkdir -p Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
cp Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved   Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

exit 0
