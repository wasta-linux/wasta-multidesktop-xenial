#!/bin/bash
# ==============================================================================
# Wasta-Linux Logout Script
# 
#   This script is intended to run by lightdm at logout.
#
#   2016-03-16 rik: initial script for 16.04
#
# ==============================================================================

#NEMO_ACTIVE=$(pidof nemo)
#NAUTILUS_ACTIVE=$(pidof nautilus)

#if [ "$NEMO_ACTIVE" ];
#then
#    # sync Cinnamon background to GNOME background
#    CINNAMON_BACKGROUND=$(su "$USER" -c gsettings get org.cinnamon.desktop.background picture-uri)
#    su "$USER" -c "gsettings set org.gnome.desktop.background picture-uri $CINNAMON_BACKGROUND"
#fi

#if [ "$NAUTILUS_ACTIVE" ];
#then
#    # sync GNOME background to Cinnamon background
#    GNOME_BACKGROUND=$(su "$USER" -c gsettings get org.gnome.desktop.background picture-uri)
#    su "$USER" -c "gsettings set org.cinnamon.desktop.background picture-uri $GNOME_BACKGROUND"
#fi

# File manager defaults set to Nautilus, since Unity will not restart
# correctly when attempting to change from nemo and nautilus at login.
#
# Effectively for Cinnamon/Nemo users each time they login the defaults
# will be for Nautilus and then be re-toggled to Nemo after the
# wasta-login.sh script completes.

# Prevent Nemo from drawing the desktop
su "$USER" -c 'gsettings set org.nemo.desktop show-desktop-icons false'

# Ensure Nautilus managing desktop and showing desktop icons
su "$USER" -c 'gsettings set org.gnome.settings-daemon.plugins.background active true'
su "$USER" -c 'gsettings set org.gnome.desktop.background draw-background true'
su "$USER" -c 'gsettings set org.gnome.desktop.background show-desktop-icons true'

exit 0
