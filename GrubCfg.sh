#!/bin/sh
#
# Script to identify what GRUB-related config files are present
# and if they are properly linked
#
#################################################################
GRUBCANON="/boot/grub/grub.conf"
GRUBFILES=($(echo /etc/grub.conf ;find /boot -name grub.conf -o -name menu.lst))
GRUBCFIND=$(stat -c %i ${GRUBCANON})

TOKERR="\033[0;33m[CHECK]\033[0m"
TOKAOK="\033[0;32m[OK]\033[0m"

while [[ COUNT -lt ${#GRUBFILES[@]} ]]
do
   # Determine if real file-content location
   CHKLINK=$(readlink -f ${GRUBFILES[${COUNT}]})

   if [[ "${CHKLINK}" = "${GRUBFILES[${COUNT}]}" ]]
   then
      if [[ "${CHKLINK}" = "${GRUBCANON}" ]]
      then
         printf "${TOKAOK}\t${GRUBFILES[${COUNT}]} is the canonical grub.conf\n"
      elif [[ $(stat -c %i ${GRUBFILES[${COUNT}]}) -eq ${GRUBCFIND} ]]
      then
         printf "${TOKAOK}\t${GRUBFILES[${COUNT}]} is a hardlink to ${GRUBCANON}\n"
      fi
   elif [[ "${CHKLINK}" = "${GRUBCANON}" ]]
   then
       printf "${TOKAOK}\t${GRUBFILES[${COUNT}]} is a sym-link to ${CHKLINK}\n"
   else
       printf "${TOKERR}\t${GRUBFILES[${COUNT}]} is a sym-link to ${CHKLINK}\n"
   fi

   # Up our counter
   ((COUNT++))
done

