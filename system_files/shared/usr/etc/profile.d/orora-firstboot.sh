#!/bin/bash

if test "$(id -u)" -gt "0" && test -d "$HOME"; then
    if test ! -e "$HOME"/.config/autostart/orora-firstboot.desktop; then
        mkdir -p "$HOME"/.config/autostart
        cp -f /etc/skel/.config/autostart/orora-firstboot.desktop "$HOME"/.config/autostart
    fi
fi
