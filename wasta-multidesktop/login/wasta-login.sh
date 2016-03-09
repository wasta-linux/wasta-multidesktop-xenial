#!/bin/bash

# ==============================================================================
# Wasta-Linux Login Script
# 
#   This script is intended to run at login from lightdm.  It makes desktop
#       environment specific adjustments (for Cinnamon / XFCE / Gnome-Shell
#       compatiblity)
# 
#   NOTES:
#       - wmctrl needed to check if cinnamon running, because env variables
#           $GDMSESSION, $DESKTOP_SESSION not set when this script run by the
#           'session-setup-script' trigger in /etc/lightdm/lightdm.conf.d/* files
#       - logname is not set, but $USER does match current logged in user when
#           this script is executed by the 'session-setup-script' trigger in
#           /etc/lightdm/lightdm.conf.d/* files
#       - Appending '|| true;' to end of each call, because don't want to return
#           error if item not found (in case some items uninstalled).  the 'true'
#           will always return 0 from these commands.
#
#   2015-02-20 rik: initial script for 14.04
#   2015-06-18 rik: adding xfce processing
#   2015-06-29 rik: adding pavucontrol for xfce only
#   2015-08-04 rik: correcting "NoDisplay" to "Hidden" for autostart items
#       for xfce login
#   2016-02-21 rik: modifying for 16.04 with Ubuntu Unity base
#   2016-03-09 rik: adding nemo/nautilus defaults.list toggling
#
# ==============================================================================

# wmctrl data doesn't get set for a while, so need to let things settle down
sleep 5s

# ------------------------------------------------------------------------------
# ALL Session Fixes
# ------------------------------------------------------------------------------

# THUNAR: even for XFCE we default to NEMO for file management
if [ -e /usr/share/applications/Thunar.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/Thunar.desktop || true;
fi

if [ -e /usr/share/applications/thunar-settings.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/thunar-settings.desktop || true;
fi

# ------------------------------------------------------------------------------
# Processing based on active Window Manager
# ------------------------------------------------------------------------------

# Searching for "Name: <Anything>".  If WM isn't initialized, will not match
WMCTRL_NAME=$(wmctrl -m | grep "^Name: [[:alnum:]]")
if [ -z "$WMCTRL_NAME" ];
then
    # no wmctrl name (login taking too long), so won't make any changes
    #   this will be the case on first boot as it takes a while to set up
    #   a new home, etc.  No problem next time login it will be sorted out
    exit 0
fi

# Check if MUFFIN window manager is active
MUFFIN_ACTIVE=$(wmctrl -m | grep Muffin)
XFWM4_ACTIVE=$(wmctrl -m | grep Xfwm4)

if [ -n "$MUFFIN_ACTIVE" ];
then
    # ==========================================================================
    # ACTIVE SESSION: CINNAMON
    # ==========================================================================

    # --------------------------------------------------------------------------
    # CINNAMON Settings
    # --------------------------------------------------------------------------
    # SHOW CINNAMON items

    if [ -e /usr/share/applications/cinnamon-settings-startup.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/cinnamon-settings-startup.desktop || true;
    fi

    if [ -e /usr/bin/nemo ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nemo.desktop || true;

        # allow nemo to draw the desktop
        su "$USER" -c 'gsettings set org.nemo.desktop show-desktop-icons true'

        # Ensure Nemo not showing hidden files (power users may be annoyed)
        su "$USER" -c 'gsettings set org.nemo.preferences show-hidden-files false'

        # Ensure Nemo not showing "location entry" (text entry), but rather "breadcrumbs"
        su "$USER" -c 'gsettings set org.nemo.preferences show-location-entry false'

        # Ensure Nemo default folder handler
        sed -i \
            -e 's@\(inode/directory\)=.*@\1=nemo.desktop@' \
            -e 's@\(application/x-gnome-saved-search\)=.*@\1=nemo.desktop@' \
            /etc/gnome/defaults.list \
            /usr/share/applications/defaults.list \
            /usr/share/gnome/applications/defaults.list

        # Nautilus may be active: kill (will not error if not found)
        su "$USER" -c 'killall nautilus || true;'

        # Ensure Nemo Started
        su "$USER" -c 'nemo -n &'
    fi

    # --------------------------------------------------------------------------
    # UNITY/GNOME Settings
    # --------------------------------------------------------------------------
    # HIDE UNITY/GNOME items
    if [ -e /usr/share/applications/alacarte.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/alacarte.desktop || true
    fi

    # Gnome Startup Applications
    if [ -e /usr/share/applications/gnome-session-properties.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/gnome-session-properties.desktop || true;
    fi

    if [ -e /usr/share/applications/gnome-tweak-tool.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/gnome-tweak-tool.desktop || true;
    fi

    if [ -e /usr/share/applications/nautilus.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nautilus.desktop || true;

        # Prevent Nautilus from drawing the desktop
        su "$USER" -c 'gsettings set org.gnome.desktop.background show-desktop-icons false'
        su "$USER" -c 'gsettings set org.gnome.desktop.background draw-background false'
    fi

    if [ -e /usr/share/applications/software-properties-gnome.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/software-properties-gnome.desktop || true;
    fi

    # --------------------------------------------------------------------------
    # XFCE Settings
    # --------------------------------------------------------------------------
    # HIDE XFCE Items
    if [ -e /usr/share/applications/thunar-volman-settings.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/thunar-volman-settings.desktop || true;
    fi

    #if [ -e /usr/share/applications/pavucontrol.desktop ];
    #then
    #    desktop-file-edit --set-key=NoDisplay --set-value=true \
    #        /usr/share/applications/pavucontrol.desktop || true;
    #fi

    # Make inactive autostart items display (had to not display in XFCE since
    #   doesn't support the "Hidden=true" parameter)
    if [ -e /etc/xdg/autostart/skype.desktop ];
    then
        desktop-file-edit --remove-key=Hidden \
            /etc/xdg/autostart/skype.desktop || true;
    fi

    if [ -e /etc/xdg/autostart/artha.desktop ];
    then
        desktop-file-edit --remove-key=Hidden \
            /etc/xdg/autostart/artha.desktop || true;
    fi

elif [ -n "$XFWM4_ACTIVE" ];
then
    # ==========================================================================
    # ACTIVE SESSION: XFCE
    # ==========================================================================

    # --------------------------------------------------------------------------
    # CINNAMON Settings
    # --------------------------------------------------------------------------
    # SHOW CINNAMON items
    # NOTE: We still default to nemo for file managing in XFCE instead of Thunar
    if [ -e /usr/bin/nemo ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nemo.desktop || true;

        # allow nemo to draw the desktop
        su "$USER" -c 'gsettings set org.nemo.desktop show-desktop-icons true'

        # Ensure Nemo not showing hidden files (power users may be annoyed)
        su "$USER" -c 'gsettings set org.nemo.preferences show-hidden-files false'

        # Ensure Nemo not showing "location entry" (text entry), but rather "breadcrumbs"
        su "$USER" -c 'gsettings set org.nemo.preferences show-location-entry false'

        # Ensure Nemo default folder handler
        sed -i \
            -e 's@\(inode/directory\)=.*@\1=nemo.desktop@' \
            -e 's@\(application/x-gnome-saved-search\)=.*@\1=nemo.desktop@' \
            /etc/gnome/defaults.list \
            /usr/share/applications/defaults.list \
            /usr/share/gnome/applications/defaults.list

        # Nautilus may be active: kill (will not error if not found)
        su "$USER" -c 'killall nautilus || true;'

        # Ensure Nemo Started
        su "$USER" -c 'nemo -n &'

    fi

    # --------------------------------------------------------------------------
    # UNITY/GNOME Settings
    # --------------------------------------------------------------------------
    # SHOW UNITY/GNOME Items
    if [ -e /usr/share/applications/alacarte.desktop ];
    then
            desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/alacarte.desktop || true;
    fi

    # HIDE UNITY/GNOME Items
    # Gnome Startup Applications
    if [ -e /usr/share/applications/gnome-session-properties.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/gnome-session-properties.desktop || true;
    fi

    if [ -e /usr/share/applications/gnome-tweak-tool.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/gnome-tweak-tool.desktop || true;
    fi

    if [ -e /usr/share/applications/nautilus.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nautilus.desktop || true;

        # Prevent Nautilus from drawing the desktop
        su "$USER" -c 'gsettings set org.gnome.desktop.background show-desktop-icons false'
        su "$USER" -c 'gsettings set org.gnome.desktop.background draw-background false'

        # Nautilus may be active: kill (will not error if not found)
        su "$USER" -c 'killall nautilus || true;'

    fi

    if [ -e /usr/share/applications/software-properties-gnome.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/software-properties-gnome.desktop || true;
    fi

    # --------------------------------------------------------------------------
    # XFCE Settings
    # --------------------------------------------------------------------------
    # SHOW XFCE Items
    if [ -e /usr/share/applications/thunar-volman-settings.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/thunar-volman-settings.desktop || true;
    fi

    #if [ -e /usr/share/applications/pavucontrol.desktop ];
    #then
    #    desktop-file-edit --remove-key=NoDisplay \
    #        /usr/share/applications/pavucontrol.desktop || true;
    #fi

    # Make inactive autostart items not display (xfce has no "Hidden=true" key)
    if [ -e /etc/xdg/autostart/skype.desktop ];
    then
        desktop-file-edit --set-key=Hidden --set-value=true \
            /etc/xdg/autostart/skype.desktop || true;
    fi

    if [ -e /etc/xdg/autostart/artha.desktop ];
    then
        desktop-file-edit --set-key=Hidden --set-value=true \
            /etc/xdg/autostart/artha.desktop || true;
    fi

else
    # ==========================================================================
    # ACTIVE SESSION: UNITY/GNOME (sorry, no KDE support right now...)
    # ==========================================================================

    # --------------------------------------------------------------------------
    # CINNAMON Settings
    # --------------------------------------------------------------------------
    if [ -e /usr/bin/nemo ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nemo.desktop || true;

        # prevent nemo from drawing the desktop
        su "$USER" -c 'gsettings set org.nemo.desktop show-desktop-icons false'

        # Nemo may be active: kill (will not error if not found)
        su "$USER" -c 'killall nemo || true;'
    fi
    # --------------------------------------------------------------------------
    # UNITY/GNOME Settings
    # --------------------------------------------------------------------------
    # SHOW UNITY/GNOME Items
    if [ -e /usr/share/applications/alacarte.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/alacarte.desktop || true;
    fi

    # Gnome Startup Applications
    if [ -e /usr/share/applications/gnome-session-properties.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/gnome-session-properties.desktop || true;
    fi

    if [ -e /usr/share/applications/gnome-tweak-tool.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/gnome-tweak-tool.desktop || true;
    fi

    if [ -e /usr/share/applications/nautilus.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nautilus.desktop || true;

        # Allow Nautilus to draw the desktop
        su "$USER" -c 'gsettings set org.gnome.desktop.background show-desktop-icons true'
        su "$USER" -c 'gsettings set org.gnome.desktop.background draw-background true'

        # Ensure Nautilus default folder handler
        sed -i \
            -e 's@\(inode/directory\)=.*@\1=nautilus-folder-handler.desktop@' \
            -e 's@\(application/x-gnome-saved-search\)=.*@\1=nautilus-folder-handler.desktop@' \
            /etc/gnome/defaults.list \
            /usr/share/applications/defaults.list \
            /usr/share/gnome/applications/defaults.list

        # Ensure Nautilus Started
        su "$USER" -c 'nautilus -n &'
    fi

    if [ -e /usr/share/applications/software-properties-gnome.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/software-properties-gnome.desktop || true;
    fi

    # --------------------------------------------------------------------------
    # XFCE Settings
    # --------------------------------------------------------------------------
    # HIDE XFCE Items
    if [ -e /usr/share/applications/thunar-volman-settings.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/thunar-volman-settings.desktop || true;
    fi

    #if [ -e /usr/share/applications/pavucontrol.desktop ];
    #then
    #    desktop-file-edit --set-key=NoDisplay --set-value=true \
    #        /usr/share/applications/pavucontrol.desktop || true;
    #fi

    # Make inactive autostart items display (had to not display in XFCE since
    #   doesn't support the "Hidden=true" parameter)
    if [ -e /etc/xdg/autostart/skype.desktop ];
    then
        desktop-file-edit --remove-key=Hidden \
            /etc/xdg/autostart/skype.desktop || true;
    fi

    if [ -e /etc/xdg/autostart/artha.desktop ];
    then
        desktop-file-edit --remove-key=Hidden \
            /etc/xdg/autostart/artha.desktop || true;
    fi
fi

exit 0
