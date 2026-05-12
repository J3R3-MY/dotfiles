#!/bin/bash
# Take a screenshot, blur it, and use it as the wlogout background
tmpbg="/tmp/wlogout-bg.png"
grim "$tmpbg"
convert "$tmpbg" -filter Gaussian -blur 0x20 "$tmpbg"
wlogout
