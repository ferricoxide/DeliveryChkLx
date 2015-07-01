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
LOCALTIME="/etc/localtime"

# Ensure valid TZ is specified
if [ -f ${ZONEFILDIR}/${WANTEDTZ} ]
then
   echo "Using \"${WANTEDTZ}\" for validity-testing."
else
   echo "Invalid timezone [${WANTEDTZ}] specified. Aborting." > /dev/stderr
   exit 1
fi

# Verify TZ value in /etc/sysconfig/clock
if [ -f ${CLOCKCFG} ]
then
   # Compare desired TZ value to one set in /etc/sysconfig/clock
   SYSCFGVAL=$(awk -F "=" '/'$(echo ${WANTEDTZ} | \
     sed 's#/#\\/#g')'/{ print $2 }' ${CLOCKCFG} | grep -x ${WANTEDTZ})
   
   # Fix /etc/sysconfig/clock if necessary
   if [ "${SYSCFGVAL}" = "" ]
   then
      printf "${WANTEDTZ} not set in ${CLOCKCFG}. " > /dev/stderr
      echo "Attempting to fix." > /dev/stderr
      sed -i '/^ZONE/s#=.*#='${WANTEDTZ}'#' ${CLOCKCFG}
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
else
   echo "ZONE=${WANTEDTZ}" >> ${CLOCKCFG} && echo "Created ${CLOCKCFG}"
fi

# Verify that /etc/localtime is correct
if [ -f ${LOCALTIME} ]
then
   echo "${LOCALTIME} exists"
else
   cp "${ZONEFILDIR}/${WANTEDTZ}" "${LOCALTIME}"
   if [[ $? -eq 0 ]]
   then
      echo "Created ${LOCALTIME}"
   else
      echo "Creation of ${LOCALTIME} failed." > /dev/stderr
      RETCODE=1
   fi
fi
