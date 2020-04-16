#!/usr/bin/env bash

local_path=~/Images/Wallpapers/laptop/divers

# get pid for dbus
pid=$(pgrep gnome-session | tail -n1)
export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/${pid}/environ|cut -d= -f2-)

# get random pic
random_pic=$(ls ${local_path} | sort -R | tail -n 1)

echo "Setting ${local_path}/${random_pic} as Wallpaper"
gsettings set org.gnome.desktop.background picture-uri "file:///${local_path}/${random_pic}"

# echo "Setting ${local_path}/${random_pic} as LockScreen"
# gsettings set org.gnome.desktop.screensaver picture-uri "file:///${local_path}/${random_pic}"
