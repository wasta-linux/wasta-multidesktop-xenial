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
#       - logname is not set, but $CURR_USER does match current logged in user when
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
#   2017-03-18 rik: writing user session to log so can retrieve on next login
#       to sync settings if session has changed (this was formerly done by a
#       wasta-logout systemd script which was difficult to work with).
#   2017-03-18 rik: this script is no longer triggered by 'at' so user login
#       won't complete until after this script completes.
#   2018-01-10 rik: adding gnome-flashback-metacity and gnome-flashback-compiz
#       sessions to the unity/gnome processing.
#
# ==============================================================================

DEBUG=""
CURR_USER=$(grep "User .* authorized" /var/log/lightdm/lightdm.log | \
    tail -1 | sed 's@.*User \(.*\) authorized@\1@')
CURR_SESSION=$(grep "Greeter requests session" /var/log/lightdm/lightdm.log | \
    tail -1 | sed 's@.*Greeter requests session \(.*\)@\1@')

mkdir -p /var/log/wasta-multidesktop
LOGFILE=/var/log/wasta-multidesktop/wasta-login.txt
PREV_SESSION_FILE=/var/log/wasta-multidesktop/$CURR_USER-prev-session
PREV_SESSION=$(cat $PREV_SESSION_FILE)

if [ $DEBUG ];
then
    echo | tee -a $LOGFILE
    echo "$(date) starting wasta-login" | tee -a $LOGFILE
    echo "current user: $CURR_USER" | tee -a $LOGFILE
    echo "current session: $CURR_SESSION" | tee -a $LOGFILE
    echo "PREV session for user: $PREV_SESSION" | tee -a $LOGFILE
    echo "NEMO show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.nemo.desktop show-desktop-icons')" | tee -a $LOGFILE
    echo "NAUTILUS show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a $LOGFILE
    echo "NAUTILUS draw background: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a $LOGFILE
fi

# ------------------------------------------------------------------------------
# Store current backgrounds
# ------------------------------------------------------------------------------
CINNAMON_BACKGROUND=$(su "$CURR_USER" -c 'dbus-launch gsettings get org.cinnamon.desktop.background picture-uri')
GNOME_BACKGROUND=$(su "$CURR_USER" -c 'dbus-launch gsettings get org.gnome.desktop.background picture-uri')
LIGHTDM_BACKGROUND=$(su "$CURR_USER" -c 'dbus-launch gsettings get com.canonical.unity-greeter background')
if [ $DEBUG ];
then
    echo "cinnamon bg: $CINNAMON_BACKGROUND" | tee -a $LOGFILE
    echo "gnome bg: $GNOME_BACKGROUND" | tee -a $LOGFILE
    echo "lightdm bg: $LIGHTDM_BACKGROUND" | tee -a $LOGFILE
fi

# ------------------------------------------------------------------------------
# ALL Session Fixes
# ------------------------------------------------------------------------------

# Ensure Nautilus not showing hidden files (power users may be annoyed)
su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.nautilus.preferences show-hidden-files false'

if [ -x /usr/bin/nemo ];
then
    # Ensure Nemo not showing hidden files (power users may be annoyed)
    su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.preferences show-hidden-files false'

    # Ensure Nemo not showing "location entry" (text entry), but rather "breadcrumbs"
    su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.preferences show-location-entry false'

    # make sure Nemo autostart disabled (we start it ourselves)
    if [ -e /etc/xdg/autostart/nemo-autostart.desktop ]
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nemo-autostart.desktop || true;
    fi
    # stop nemo if running (we'll start later)
    if [ "$(pidof nemo)" ];
    then
        if [ $DEBUG ];
        then
            echo "nemo is running: $(pidof nemo)" | tee -a $LOGFILE
        fi
        killall nemo
    fi
fi

# --------------------------------------------------------------------------
# SYNC to PREV_SESSION if different
# --------------------------------------------------------------------------
# previously I only triggered if current and prev sessions were different
# but I will always apply the changes in case it didn't succeed before.
if [ "$PREV_SESSION" == "cinnamon" ];
then
    # apply Cinnamon settings to GNOME
    if [ $DEBUG ];
    then
        echo "Previous Session Cinnamon: Sync TO GNOME" | tee -a $LOGFILE
    fi
    # sync Cinnamon background to GNOME background
    su "$CURR_USER" -c "dbus-launch gsettings set org.gnome.desktop.background picture-uri $CINNAMON_BACKGROUND"
    # sync Cinnmaon background to Unity Greeter LightDM background
    LIGHTDM_BACKGROUND=$(echo $CINNAMON_BACKGROUND | sed 's@file://@@')
    su "$CURR_USER" -c "dbus-launch gsettings set com.canonical.unity-greeter background $LIGHTDM_BACKGROUND"
else
    # apply GNOME settings to Cinnamon
    if [ $DEBUG ];
    then
        echo "Previous Session NOT Cinnamon: Sync TO Cinnamon" | tee -a $LOGFILE
    fi
    # sync GNOME background to Cinnamon background
    su "$CURR_USER" -c "dbus-launch gsettings set org.cinnamon.desktop.background picture-uri $GNOME_BACKGROUND"
    # sync GNOME background to Unity Greeter LightDM background
    LIGHTDM_BACKGROUND=$(echo $GNOME_BACKGROUND | sed 's@file://@@')
    # set LIGHTDM background
    su "$CURR_USER" -c "dbus-launch gsettings set com.canonical.unity-greeter background $LIGHTDM_BACKGROUND"
fi

# ------------------------------------------------------------------------------
# Processing based on session
# ------------------------------------------------------------------------------

if [ "$CURR_SESSION" == "cinnamon" ];
then
    # ==========================================================================
    # ACTIVE SESSION: CINNAMON
    # ==========================================================================
    if [ $DEBUG ];
    then
        echo "processing based on cinnammon session" | tee -a $LOGFILE
    fi

    # Nautilus may be active: kill (will not error if not found)
    if [ "$(pidof nautilus)" ];
    then
        if [ $DEBUG ];
        then
            echo "nautilus running (TOP) and needs killed: $(pidof nautilus)" | tee -a $LOGFILE
        fi
        killall nautilus || true;
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

    if [ -x /usr/bin/nemo ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nemo.desktop || true;

        # allow nemo to draw the desktop
        su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.desktop show-desktop-icons true'

        # Ensure Nemo default folder handler
        sed -i \
            -e 's@\(inode/directory\)=.*@\1=nemo.desktop@' \
            -e 's@\(application/x-gnome-saved-search\)=.*@\1=nemo.desktop@' \
            /etc/gnome/defaults.list \
            /usr/share/applications/defaults.list \
            /usr/share/gnome/applications/defaults.list

        if ! [ "$(pidof nemo)" ];
        then
            if [ $DEBUG ];
            then
                echo "nemo not started: attempting to start" | tee -a $LOGFILE
            fi
            # Ensure Nemo Started
            su "$CURR_USER" -c 'dbus-launch nemo -n &'
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

        # Nautilus may be active: kill (will not error if not found)
        if [ "$(pidof nautilus)" ];
        then
            if [ $DEBUG ];
            then
                echo "nautilus running (MID) and needs killed: $(pidof nautilus)" | tee -a $LOGFILE
            fi
            killall nautilus || true;
        fi

        # Prevent Nautilus from drawing the desktop
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons false'
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background false'
    fi

    if [ -e /usr/share/applications/org.gnome.Nautilus.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/org.gnome.Nautilus.desktop || true;

        # Prevent Nautilus from drawing the desktop
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons false'
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background false'
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

    if [ $DEBUG ];
    then
        echo "after unity and cinnamon settings NEMO show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.nemo.desktop show-desktop-icons')" | tee -a $LOGFILE
        echo "after unity and cinnamon settings NAUTILUS show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a $LOGFILE
        echo "after unity and cinnamon settings NAUTILUS draw background: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a $LOGFILE
    fi

    #again trying to set nemo to draw....
    su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.desktop show-desktop-icons true'
    su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons false'
    su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background false'

    if [ $DEBUG ];
    then
        echo "after nemo draw desk again NEMO show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.nemo.desktop show-desktop-icons')" | tee -a $LOGFILE
        echo "after nemo draw desk again NAUTILUS show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a $LOGFILE
        echo "after nemo draw desk again NAUTILUS draw background: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a $LOGFILE
    fi

elif [ "$CURR_SESSION" == "ubuntu" ] || [ "$CURR_SESSION" == "gnome" ] || [ "$CURR_SESSION" == "gnome-flashback-metacity" ] || [ "$CURR_SESSION" == "gnome-flashback-compiz" ];
then
    # ==========================================================================
    # ACTIVE SESSION: UNITY (sorry, no XFCE, KDE, or MATE support right now...)
    # ==========================================================================

    if [ $DEBUG ];
    then
        echo "processing based on unity / gnome session" | tee -a $LOGFILE
    fi

    # --------------------------------------------------------------------------
    # CINNAMON Settings
    # --------------------------------------------------------------------------
    if [ -x /usr/bin/nemo ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nemo.desktop || true;

        # prevent nemo from drawing the desktop
        su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.desktop show-desktop-icons false'

        # Nemo may be active: kill (will not error if not found)
        if [ "$(pidof nemo)" ];
        then
            if [ $DEBUG ];
            then
                echo "nemo running (MID) and needs killed: $(pidof nemo)" | tee -a $LOGFILE
            fi
            killall nemo
        fi
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
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons true'
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background true'

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
                echo "nautilus not started, but not starting or unity will hang" | tee -a $LOGFILE
            fi
            # rik: IF Nautlius not already started, below will sort of "HANG" Unity
            #     so not doing here: instead, using wasta-logout.sh to set defaults
            #     to Nautilus, meaning that Nautilus *should* be ready to start
            #     each time.
            # 2016-11-15: confirmed still "hangs" if attempt to restart nautilus,
            #   so keeping commented out.
            # Ensure Nautilus Started
            #su "$CURR_USER" -c 'dbus-launch nautilus -n &' | tee -a $LOGFILE
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
        echo "desktop session not supported" | tee -a $LOGFILE
    fi

fi


# ------------------------------------------------------------------------------
# SET PREV Session file for user
# ------------------------------------------------------------------------------
echo $CURR_SESSION > $PREV_SESSION_FILE

# ------------------------------------------------------------------------------
# FINISHED
# ------------------------------------------------------------------------------
if [ $DEBUG ];
then
    if [ "$(pidof nemo)" ];
    then
        echo "END: nemo IS running!" | tee -a $LOGFILE
    else
        echo "END: nemo NOT running!" | tee -a $LOGFILE
    fi

    if [ "$(pidof nautilus)" ];
    then
        echo "END: nautilus IS running!" | tee -a $LOGFILE
    else
        echo "END: nautilus NOT running!" | tee -a $LOGFILE
    fi
    echo "final settings:" | tee -a $LOGFILE
    CINNAMON_BACKGROUND_NEW=$(su "$CURR_USER" -c 'dbus-launch gsettings get org.cinnamon.desktop.background picture-uri')
    GNOME_BACKGROUND_NEW=$(su "$CURR_USER" -c 'dbus-launch gsettings get org.gnome.desktop.background picture-uri')
    LIGHTDM_BACKGROUND_NEW=$(su "$CURR_USER" -c 'dbus-launch gsettings get com.canonical.unity-greeter background')
    echo "cinnamon bg NEW: $CINNAMON_BACKGROUND_NEW" | tee -a $LOGFILE
    echo "gnome bg NEW: $GNOME_BACKGROUND_NEW" | tee -a $LOGFILE
    echo "lightdm bg NEW: $LIGHTDM_BACKGROUND_NEW" | tee -a $LOGFILE
    echo "NEMO show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.nemo.desktop show-desktop-icons')" | tee -a $LOGFILE
    echo "NAUTILUS show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a $LOGFILE
    echo "NAUTILUS draw background: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a $LOGFILE
    echo "$(date) exiting wasta-login" | tee -a $LOGFILE
fi

exit 0
