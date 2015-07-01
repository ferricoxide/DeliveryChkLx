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

if [ -f ${CLOCKCFG} ]
then
   # Compare desired TZ value to one set in /etc/sysconfig/clock
   SYSCFGVAL=$(awk -F "=" '/'${WANTEDTZ}'/{ print $2 }' ${CLOCKCFG} |
      grep -x ${WANTEDTZ})
   
   # Fix /etc/sysconfig/clock if necessary
   if [ "${SYSCFGVAL}" = "" ]
   then
      printf "${WANTEDTZ} not set in ${CLOCKCFG}. " > /dev/stderr
      echo "Attempting to fix." > /dev/stderr
      sed -i '/^ZONE/s/=.*/='${WANTEDTZ}'/' ${CLOCKCFG}
      if [[ $? -eq 0 ]]
      then
         echo "Updated 'ZONE' setting in ${CLOCKCFG} to ${WANTEDTZ}."
      else
         echo "Update of ${CLOCKCFG} failed." > /dev/stderr
         RETCODE=1
      fi
   else
      echo "${WANTEDTZ} already set in ${CLOCKCFG}."
   fi
fi
