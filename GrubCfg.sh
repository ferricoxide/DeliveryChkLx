#!/bin/sh
#
# Script to ensure that GRUB-related config files exist in their proper form
#
############################################################
GRUBCFG="/boot/grub/grub.conf"
GRUBETC="/etc/grub.conf"

# Verify that /boot/grub/grub.conf exists
if [ -e ${GRUBCFG} ]
then
   # Alert if file is empty
   if [ ! -s ${GRUBCFG} ]
   then
      printf "${GRUBCFG} is empty: does this "  > /dev/stderr
      echo "system use GRUB to boot" > /dev/stderr
      RETCODE=1
   fi
else
   # Alert if file does not exist
   printf "${GRUBCFG} does not exist: does this " > /dev/stderr
   echo "system use GRUB to boot?" > /dev/stder
   RETCODE=1
fi

exit ${RETCODE}
