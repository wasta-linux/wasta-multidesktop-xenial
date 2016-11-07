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
#   2016-11-07 rik: updating to use "at" to call "real script", otherwise
#       in newer releases the login process waits for completion.
#
# ==============================================================================

if ! [ -e /var/spool/cron/atjobs/.SEQ ]; then
  /bin/bash -c "/usr/share/wasta-multidesktop/scripts/wasta-login.sh $*" &
else
  echo "/usr/share/wasta-multidesktop/scripts/wasta-login.sh $*" | at now
fi

exit 0
