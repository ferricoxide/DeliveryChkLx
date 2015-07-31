#!/bin/sh
#
# Script to ensure that host's timzeone configuration is
# correctly set up. Invoke with optional timezone argument:
#
# Usage: TZconf.sh [ TIMEZONE ]
#
# * Config checks/fixes:
#   * Fix /etc/sysconfig/clock if necessary		(✓)
#   * Verify that /etc/localtime is correct		(✓)
#   * Check if TZ set and set properly at shell-level
#     * Check /etc/profile				(✓)
#     * Check /etc/profile.d/* files			(✓)
#     * Check /etc/csh.cshrc				(✓)
#     * Check /etc/csh.login				(✓)
#     * Check ${HOME}/.profile				(✓)
#     * Check ${HOME}/.bash_profile			(✓)
#     * Check ${HOME}/.bashrc				(✓)
#     * Check ${HOME}/.cshrc				(✓)
#     * Check ${HOME}/.kshrc				(✓)
#     * Check ${HOME}/.tcshrc				(✓)
#
# LEGEND:
#   (✓) Feature implemented
#   ( ) Feature not implemented
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
   printf "${LOCALTIME} exists "
   SUMLOCALTIME=$(md5sum ${LOCALTIME} | awk '{print $1}')
   SUMWANTTIME=$(md5sum ${ZONEFILDIR}/${WANTEDTZ} | awk '{print $1}')
   if [[ "${SUMLOCALTIME}" = "${SUMWANTTIME}" ]]
   then
      echo "...and is correct"
   else
      echo "...but is incorrect. Attempting to fix"
      rm ${LOCALTIME} || echo "Failed to remove bad ${LOCALTIME}" > /dev/stderr
      cp "${ZONEFILDIR}/${WANTEDTZ}" ${LOCALTIME} || { echo Failed ;
        RETCODE=1 ; }
   fi

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

# Check shell-date
SHELLTZ=$(date "+%Z")
if [[ "${SHELLTZ}" = ${WANTEDTZ} ]]
then
   echo "Shell TimeZone matches system TimeZone [${WANTEDTZ}]."
else
   printf "Shell TimeZone [${SHELLTZ}] not the same as " > /dev/stderr
   echo "system TimeZone [${WANTEDTZ}]." > /dev/stderr
   SHINITFILES=(
      /etc/profile
      /etc/profile.d/*
      /etc/csh.cshrc
      /etc/csh.login
      ${HOME}/.profile
      ${HOME}/.bash_profile
      ${HOME}/.bashrc
      ${HOME}/.cshrc
      ${HOME}/.kshrc
      ${HOME}/.tcshrc
   )
   TZSETTERS=$(grep -l TZ ${SHINITFILES})
   if [ "${TZSETTERS}" != "" ]
   then
      echo "Check ${TZSETTERS} for shell-level overrides." > /dev/stderr
   fi
fi
