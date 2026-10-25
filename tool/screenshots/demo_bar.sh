#!/usr/bin/env bash
# Clean status bar: 9:41, full battery, Wi-Fi only, no notifications.
b(){ adb shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
adb shell settings put global sysui_demo_allowed 1
b enter; b clock -e hhmm 0941; b battery -e level 100 -e plugged false
b network -e wifi show -e level 4 -e fully true; b network -e mobile hide; b network -e airplane hide
b notifications -e visible false
# Some emulator resolutions draw duplicate network icons; hide them (clock + battery only).
adb shell settings put secure icon_blacklist satellite,mobile,airplane,rotate,wifi
