#!/bin/bash
# ==============================================================================
# Wasta-Linux Logout Script
# 
#   This script is intended to run by lightdm at logout.
#
#   2016-03-16 rik: initial script for 16.04
#   2016-03-26 rik: syncing user's cinnamon / gnome backgrounds on logout
#   2016-05-03 rik: double-quote variables when replacing backgrounds
#
# ==============================================================================

# ------------------------------------------------------------------------------
# Store current backgrounds
# ------------------------------------------------------------------------------
CINNAMON_BACKGROUND=$(su "$USER" -c 'gsettings get org.cinnamon.desktop.background picture-uri')
GNOME_BACKGROUND=$(su "$USER" -c 'gsettings get org.gnome.desktop.background picture-uri')

# ------------------------------------------------------------------------------
# All Session Fixes
# ------------------------------------------------------------------------------

# 2016-03-16 rik: Unity hangs up if Nemo set to draw desktop, but Cinnamon
#   does not have issues if Nautilus set to handle desktop.  So, need to set
#   Nautilus as desktop handler on logout all the time, requiring Cinnamon
#   to set it back to Nemo each time on login.

# Prevent Nemo from drawing the desktop
su "$USER" -c 'gsettings set org.nemo.desktop show-desktop-icons false'

# Ensure Nautilus managing desktop and showing desktop icons
su "$USER" -c 'gsettings set org.gnome.settings-daemon.plugins.background active true'
su "$USER" -c 'gsettings set org.gnome.desktop.background draw-background true'
su "$USER" -c 'gsettings set org.gnome.desktop.background show-desktop-icons true'

# ------------------------------------------------------------------------------
# Processing based on active Window Manager
# ------------------------------------------------------------------------------

# WHEN UNITY ACTIVE, normally wmctrl -m returns "Compiz" but here it is not
# showing, just empty wmctrl -- maybe it gets unloaded sooner or something?
# Anyway, will have to adjust based only on Muffin found or not then

MUFFIN_ACTIVE=$(wmctrl -m | grep Muffin)
# UNITY_ACTIVE$(wmctrl -m | grep Compiz)

if [ "$MUFFIN_ACTIVE" ];
then
    # sync Cinnamon background to GNOME background
    su "$USER" -c "gsettings set org.gnome.desktop.background picture-uri $CINNAMON_BACKGROUND"
    # sync Cinnmaon background to Unity Greeter LightDM background
    LIGHTDM_BACKGROUND=$(echo $CINNAMON_BACKGROUND | sed 's@file://@@')
else
    # sync GNOME background to Cinnamon background
    su "$USER" -c "gsettings set org.cinnamon.desktop.background picture-uri $GNOME_BACKGROUND"
    # sync Cinnmaon background to Unity Greeter LightDM background
    LIGHTDM_BACKGROUND=$(echo $GNOME_BACKGROUND | sed 's@file://@@')
fi

# set LIGHTDM background
su "$USER" -c "gsettings set com.canonoical.unity-greeter background $LIGHTDM_BACKGROUND"

exit 0
