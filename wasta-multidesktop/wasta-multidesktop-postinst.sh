#!/bin/bash

# ==============================================================================
# wasta-multidesktop-setup: wasta-multidesktop-postinst.sh
#
# This script is automatically run by the postinst configure step on
#   installation of wasta-multidesktop-setup.  It can be manually re-run, but is
#   only intended to be run at package installation.  
#
# 2015-06-18 rik: initial script
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

# ------------------------------------------------------------------------------
# Finished
# ------------------------------------------------------------------------------
echo
echo "*** Finished with wasta-multidesktop-postinst.sh"
echo

exit 0
