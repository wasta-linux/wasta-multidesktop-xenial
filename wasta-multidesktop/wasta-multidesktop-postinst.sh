#!/bin/bash

# ==============================================================================
# wasta-multidesktop-setup: wasta-multidesktop-postinst.sh
#
# This script is automatically run by the postinst configure step on
#   installation of wasta-multidesktop-setup.  It can be manually re-run, but is
#   only intended to be run at package installation.
#
# 2015-06-18 rik: initial script
# 2016-11-14 rik: enabling wasta-multidesktop systemd service
# 2017-03-18 rik: disabling wasta-logout systemd service: we now use
#   wasta-login lightdm script to record user session and retrieve it to
#   compare session to previous session and sync if any change.
#
# ==============================================================================

# ------------------------------------------------------------------------------
# Check to ensure running as root
# ------------------------------------------------------------------------------
#   No fancy "double click" here because normal user should never need to run
if [ $(id -u) -ne 0 ]
then
	echo
	echo "You must run this script with sudo." >&2
	echo "Exiting...."
	sleep 5s
	exit 1
fi

# ------------------------------------------------------------------------------
# Main Processing
# ------------------------------------------------------------------------------


#WASTA_SYSTEMD=$(systemctl is-enabled wasta-logout || true);

#if [ "$WASTA_SYSTEMD" == "enabled" ];
#then
#    echo
#    echo "*** DISabling wasta-logout systemd service"
#    echo
#    # check status this way: journalctl | grep wasta-logout
#    systemctl disable wasta-logout || true
#fi

# ------------------------------------------------------------------------------
# Finished
# ------------------------------------------------------------------------------
echo
echo "*** Finished with wasta-multidesktop-postinst.sh"
echo

exit 0
