#!/usr/bin/env bash
# $mod+Ctrl+g: drag a box around any text on screen and it's in the clipboard.
# Offline OCR (tesseract, English + German); the screenshot is never saved.
set -u
command -v tesseract >/dev/null || { notify-send -a OCR "tesseract isn't installed"; exit 1; }
geo=$(slurp) || exit 0
# 2x scale: tesseract reads small screen text much better
text=$(grim -s 2 -g "$geo" - | tesseract stdin stdout -l eng+deu 2>/dev/null | sed -e 's/[[:space:]]*$//' | sed -e '/./,$!d')
if [ -n "$text" ]; then
    printf '%s' "$text" | wl-copy
    notify-send -a OCR "Text copied" "$(printf '%s' "$text" | head -c 160)"
else
    notify-send -a OCR "No text found"
fi
