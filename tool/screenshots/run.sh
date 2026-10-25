#!/usr/bin/env bash
# Captures every store screen on the running emulator for one device + language.
#   ./run.sh <device> <lang>      e.g.  ./run.sh tablet_7 fr
# Expects: emulators seeded (seed.mjs), app installed with USE_EMULATOR=true,
# `adb reverse` for 8085/9099/9199. Tap positions are fractions of the screen
# (see POS below), tuned per device because the layout reflows.
set -e
cd "$(dirname "$0")"
DEV=$1; LANG_=$2
read W H < <(adb shell wm size | tail -1 | sed 's/.*: //; s/x/ /')
px(){ awk "BEGIN{print int($W*$1), int($H*$2)}"; }
tap(){ adb shell input tap $(px "$1" "$2"); sleep "${3:-2}"; }
swipe(){ adb shell input swipe $(px 0.92 "$1") $(px 0.92 "$2") "${3:-800}"; sleep 3; }
shot(){ ./cap.sh "$DEV" "$LANG_" "$1" >/dev/null; echo "  $1"; }

# Bottom nav (same fractions on every device)
NAV_Y=0.886; HOME=0.168; STATS=0.323; PLUS=0.5; NEWS=0.675; PROFILE=0.85

case "$DEV" in
  phone)     EMAIL=0.471 PASS=0.564 LOGIN=0.661 STREAK_OK=0.659 COMM_SWIPE="0.77 0.37" CARD="0.41 0.568"
             CLUSTER1="0.294 0.751" CLUSTER2="0.392 0.601" POINT="0.284 0.726" ACH=0.521 FORM_ITEM="0.31 0.877"
             COUNTS="0.693:0.356:24 0.693:0.400:46 0.693:0.444:112 0.693:0.488:85 0.693:0.532:9 0.693:0.664:58 0.693:0.708:31" ;;
  tablet_7)  EMAIL=0.508 PASS=0.600 LOGIN=0.697 STREAK_OK=0.649 COMM_SWIPE="0.78 0.33" CARD="0.40 0.531"
             CLUSTER1="0.345 0.744" CLUSTER2="0.425 0.598" POINT="0.266 0.739" ACH=0.540 FORM_ITEM="0.33 0.833"
             COUNTS="0.698:0.236:24 0.698:0.302:46 0.698:0.368:112 0.698:0.433:85 0.698:0.499:9 0.698:0.695:58 0.698:0.760:31" ;;
  *) echo "positions for $DEV not tuned yet"; exit 1 ;;
esac

echo "[$DEV/$LANG_] login"
./demo_bar.sh
EMAIL_Y=$EMAIL PASS_Y=$PASS LOGIN_Y=$LOGIN ./login.sh "$([ "$LANG_" = fr ] && echo fr-FR || echo en-US)"
./demo_bar.sh
shot 06_streak
tap 0.5 $STREAK_OK 4;                 shot 01_home
swipe $COMM_SWIPE;                    shot 09_community
tap $CARD 6;                          shot 10_detail
adb shell input keyevent 4; sleep 2
tap $STATS $NAV_Y 8;                  shot 03_stats
swipe 0.78 0.21; swipe 0.78 0.36; sleep 3
tap $CLUSTER1 5; tap $CLUSTER2 5; tap $POINT 4; shot 04_map
tap $PROFILE $NAV_Y 6;                shot 08_profile
tap 0.5 $ACH 6;                       shot 05_achievements
adb shell input keyevent 4; sleep 2
echo "  (fill cleanup form manually, then: ./cap.sh $DEV $LANG_ 02_cleanup_items; then news)"
