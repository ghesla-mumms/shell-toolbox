#!/bin/bash

# https://apple.stackexchange.com/questions/293502/how-can-i-determine-the-battery-level-of-my-magic-mouse-from-the-command-line

BATTLVL=$(ioreg -r -l -n AppleHSBluetoothDevice | egrep '"BatteryPercent" = |^  \|   "Bluetooth Product Name" = '| sed 's/  |   "Bluetooth Product Name" = "Magic Mouse 2"/  \|  Mouse:/' | sed 's/  |   "Bluetooth Product Name" = "Magic Keyboard"/  \|  Keyboard:/'| sed 's/  |   |       "BatteryPercent" = / /'); echo $BATTLVL

BATTRPT=${BATTLVL//[$'\t\r\n']};

theScript=$"display notification \"$BATTRPT\" "
    echo $theScript | osascript
