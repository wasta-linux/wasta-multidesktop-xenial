#!/bin/bash

# ==============================================================================
# Wasta-Linux Login Wrapper Script
#
#   This wrapper is needed because a sleep is required in the real login script
#       in order to give time for the window manager to be fully loaded.  This
#       wrapper allows normal login process to continue since it will finish
#       immediately due to "&".  Real login script will sleep at beginning.
#
#   2013-12-21 rik: initial script
#
# ==============================================================================

/bin/bash -c "/usr/share/wasta-multidesktop/login/wasta-login.sh $*" &

exit 0
