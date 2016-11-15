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
#       - logname is not set, but $LIGHTDM_USER does match current logged in user when
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
#   2016-03-16 rik: wasta-logout.sh now sets defaults to nautilus each time,
#       adjusting processing based on this. (setting to nautilus on logout is
#       the only way I have been able to NOT have Unity get hung at login...
#       other techniques for re-starting Nautilus / Unity / etc. all break
#       Unity).
#   2016-04-27 rik: nemo-compare-preferences.desktop handling based on desktop
#   2016-10-01 rik: for all sessions make sure nemo and nautilus don't show
#       hidden files and for nemo don't show 'location-entry' (n/a for nautilus)
#   2016-10-19 rik: make sure nemo autostart is disabled.
#   2016-11-15 rik: adding debug login, also grabbing user and session from
#       lightdm log (instead of getting session from wmctrl)
#
# ==============================================================================

DEBUG=""
LIGHTDM_USER=$(grep "User .* authorized" /var/log/lightdm/lightdm.log | tail -1 | sed 's@.*User \(.*\) authorized@\1@')
LIGHTDM_SESSION=$(grep "Greeter requests session" /var/log/lightdm/lightdm.log | tail -1 | sed 's@.*Greeter requests session \(.*\)@\1@')
if [ $DEBUG ];
then
    echo | tee -a /wasta-login.txt
    echo "$(date) starting wasta-login" | tee -a /wasta-login.txt
    echo "lightdm user: $LIGHTDM_USER" | tee -a /wasta-login.txt
    echo "lightdm session: $LIGHTDM_SESSION" | tee -a /wasta-login.txt
    echo "NEMO show desktop icons: $(su $LIGHTDM_USER -c 'dbus-launch gsettings get org.nemo.desktop show-desktop-icons')" | tee -a /wasta-login.txt
    echo "NAUTILUS show desktop icons: $(su $LIGHTDM_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a /wasta-login.txt
    echo "NAUTILUS draw background: $(su $LIGHTDM_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a /wasta-login.txt
fi

# ------------------------------------------------------------------------------
# ALL Session Fixes
# ------------------------------------------------------------------------------

# Ensure Nautilus not showing hidden files (power users may be annoyed)
su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.gnome.nautilus.preferences show-hidden-files false'

if [ -x /usr/bin/nemo ];
then
    # Ensure Nemo not showing hidden files (power users may be annoyed)
    su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.nemo.preferences show-hidden-files false'

    # Ensure Nemo not showing "location entry" (text entry), but rather "breadcrumbs"
    su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.nemo.preferences show-location-entry false'

    # make sure Nemo autostart disabled (we start it ourselves)
    if [ -e /etc/xdg/autostart/nemo-autostart.desktop ]
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nemo-autostart.desktop || true;
    fi
fi

# ------------------------------------------------------------------------------
# Processing based on session
# ------------------------------------------------------------------------------

if [ "$LIGHTDM_SESSION" == "cinnamon" ];
then
    # ==========================================================================
    # ACTIVE SESSION: CINNAMON
    # ==========================================================================
    if [ $DEBUG ];
    then
        echo "processing based on cinnammon session" | tee -a /wasta-login.txt
    fi

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
        su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.nemo.desktop show-desktop-icons true'

        # Ensure Nemo default folder handler
        sed -i \
            -e 's@\(inode/directory\)=.*@\1=nemo.desktop@' \
            -e 's@\(application/x-gnome-saved-search\)=.*@\1=nemo.desktop@' \
            /etc/gnome/defaults.list \
            /usr/share/applications/defaults.list \
            /usr/share/gnome/applications/defaults.list

        # Nautilus may be active: kill (will not error if not found)
        su "$LIGHTDM_USER" -c 'dbus-launch killall nautilus || true;'

        if ! [ "$(pidof nemo)" ];
        then
            if [ $DEBUG ];
            then
                echo "nemo not started: attempting to start" | tee -a /wasta-login.txt
            fi
            # Ensure Nemo Started
            su "$LIGHTDM_USER" -c 'dbus-launch nemo -n &'
        fi
    fi

    if [ -e /usr/share/applications/nemo-compare-preferences.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nemo-compare-preferences.desktop || true;
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
        su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons false'
        su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background false'
    fi

    if [ -e /usr/share/applications/org.gnome.Nautilus.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/org.gnome.Nautilus.desktop || true;

        # Prevent Nautilus from drawing the desktop
        su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons false'
        su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background false'
    fi

    if [ -e /usr/share/applications/nautilus-compare-preferences.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nautilus-compare-preferences.desktop || true;
    fi

    if [ -e /usr/share/applications/software-properties-gnome.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/software-properties-gnome.desktop || true;
    fi

elif [ "$LIGHTDM_SESSION" == "ubuntu" ];
then
    # ==========================================================================
    # ACTIVE SESSION: UNITY (sorry, no XFCE, KDE, or GNOME support right now...)
    # ==========================================================================

    if [ $DEBUG ];
    then
        echo "processing based on unity / gnome session" | tee -a /wasta-login.txt
    fi

    # --------------------------------------------------------------------------
    # CINNAMON Settings
    # --------------------------------------------------------------------------
    if [ -e /usr/bin/nemo ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nemo.desktop || true;

        # prevent nemo from drawing the desktop
        su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.nemo.desktop show-desktop-icons false'

        # Nemo may be active: kill (will not error if not found)
        su "$LIGHTDM_USER" -c 'dbus-launch killall nemo || true;'
    fi

    if [ -e /usr/share/applications/nemo-compare-preferences.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nemo-compare-preferences.desktop || true;
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
        su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons true'
        su "$LIGHTDM_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background true'

        # Ensure Nautilus default folder handler
        sed -i \
            -e 's@\(inode/directory\)=.*@\1=nautilus-folder-handler.desktop@' \
            -e 's@\(application/x-gnome-saved-search\)=.*@\1=nautilus-folder-handler.desktop@' \
            /etc/gnome/defaults.list \
            /usr/share/applications/defaults.list \
            /usr/share/gnome/applications/defaults.list

        # Ensure Nautilus Started
        if ! [ "$(pidof nautilus)" ];
        then
            if [ $DEBUG ];
            then
                echo "nautilus not started, but not starting or unity will hang" | tee -a /wasta-login.txt
            fi
            # rik: IF Nautlius not already started, below will sort of "HANG" Unity
            #     so not doing here: instead, using wasta-login.sh to set defaults
            #     to Nautilus, meaning that Nautilus *should* be ready to start
            #     each time.
            # 2016-11-15: confirmed still "hangs" if attempt to restart nautilus,
            #   so keeping commented out.
            # Ensure Nautilus Started
            #su "$LIGHTDM_USER" -c 'dbus-launch nautilus -n &' | tee -a /wasta-login.txt
        fi
    fi

    if [ -e /usr/share/applications/nautilus-compare-preferences.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nautilus-compare-preferences.desktop || true;
    fi

    if [ -e /usr/share/applications/software-properties-gnome.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/software-properties-gnome.desktop || true;
    fi

else
    if [ $DEBUG ];
    then
        echo "desktop session not supported" | tee -a /wasta-login.txt
    fi

fi

if [ $DEBUG ];
then
    echo "final settings:" | tee -a /wasta-login.txt
    echo "NEMO show desktop icons: $(su $LIGHTDM_USER -c 'dbus-launch gsettings get org.nemo.desktop show-desktop-icons')" | tee -a /wasta-login.txt
    echo "NAUTILUS show desktop icons: $(su $LIGHTDM_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a /wasta-login.txt
    echo "NAUTILUS draw background: $(su $LIGHTDM_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a /wasta-login.txt
    echo "$(date) exiting wasta-login" | tee -a /wasta-login.txt
fi

exit 0
