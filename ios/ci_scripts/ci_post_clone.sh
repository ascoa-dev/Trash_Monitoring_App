#!/bin/sh
# Xcode Cloud: runs after the repo is cloned, before the archive build.
# Installs Flutter, generates the iOS config Flutter's build phases need,
# and installs CocoaPods (which completes Runner.xcworkspace).
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Same Flutter version as the GitHub release workflow.
git clone https://github.com/flutter/flutter.git --depth 1 -b 3.44.2 "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"
flutter precache --ios

# .env is a declared asset but is gitignored; release builds read the Maps
# key from --dart-define instead, so an empty file is enough.
touch .env

flutter pub get
# Writes ios/Flutter/Generated.xcconfig (version from pubspec, dart-defines).
# Set GOOGLE_MAPS_API_KEY as a secret environment variable in the workflow.
flutter build ios --config-only --release \
  --dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY:-}"

HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
cd ios && pod install

exit 0
