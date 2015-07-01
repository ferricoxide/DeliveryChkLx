#!/bin/sh
#
# Script to ensure that host's timzeone configuration is
# correctly set up. Invoke with optional timezone argument:
#
# Usage: TimeCfg.sh [ TIMEZONE ]
#
############################################################
WANTEDTZ=${1:-UTC}
ZONEFILDIR="/usr/share/zoneinfo"
CLOCKCFG="/etc/sysconfig/clock"

# Ensure valid TZ is specified
if [ -f ${ZONEFILDIR}/${WANTEDTZ} ]
then
   echo "Using \"${WANTEDTZ}\" for validity-testing."
else
   echo "Invalid timezone [${WANTEDTZ}] specified. Aborting." > /dev/stderr
   exit 1
fi

SYSCFGVAL=$(awk -F "=" '/'${WANTEDTZ}'/{ print $2 }' ${CLOCKCFG} |
   grep -x ${WANTEDTZ})

if [ "${SYSCFGVAL}" = "" ]
then
   echo "${WANTEDTZ} not set in ${CLOCKCFG}." > /dev/stderr
   RETCODE=1
else
   echo "${WANTEDTZ} set in ${CLOCKCFG}."
fi
