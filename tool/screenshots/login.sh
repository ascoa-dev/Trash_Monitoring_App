#!/usr/bin/env bash
# Usage: login.sh [lang]  — wipes the app, optionally sets its language, logs in as the demo user.
set -e
adb shell pm clear com.ascoa.wemonitor >/dev/null
adb shell pm grant com.ascoa.wemonitor android.permission.ACCESS_FINE_LOCATION
[ -n "$1" ] && adb shell cmd locale set-app-locales com.ascoa.wemonitor --locales "$1"
adb shell am start -n com.ascoa.wemonitor/.MainActivity >/dev/null; sleep 25
# Field positions are fractions of the screen so this works at any resolution.
read W H < <(adb shell wm size | tail -1 | sed 's/.*: //; s/x/ /')
tap(){ adb shell input tap $(awk "BEGIN{print int($W*$1), int($H*$2)}"); }
tap 0.5 ${EMAIL_Y:-0.471}; sleep 1; adb shell input text amina.demo@example.com
tap 0.5 ${PASS_Y:-0.564}; sleep 1; adb shell input text wemonitor2026
adb shell input keyevent 4; sleep 1
tap 0.5 ${LOGIN_Y:-0.661}; sleep 30
