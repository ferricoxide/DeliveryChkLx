#!/bin/sh
#
# Script to identify what GRUB-related config files are present
# and if they are properly linked
#
#################################################################
GRUBCANON="/boot/grub/grub.conf"
GRUBFILES=($(echo /etc/grub.conf ;find /boot -name grub.conf -o -name menu.lst))
GRUBCFIND=$(stat -c %i ${GRUBCANON})

while [[ COUNT -lt ${#GRUBFILES[@]} ]]
do
   CHKLINK=$(readlink -f ${GRUBFILES[${COUNT}]})

   if [[ "${CHKLINK}" = "${GRUBFILES[${COUNT}]}" ]]
   then
      if [[ "${CHKLINK}" = "${GRUBCANON}" ]]
      then
         echo "This is the canonical grub.conf"
      else
         echo "This is NOT the canonical grub.conf"
      fi
   else
       echo "${GRUBFILES[${COUNT}]} is a sym-link to ${CHKLINK}"
   fi

   # Up our counter
   ((COUNT++))
done

echo ${GRUBFILES[@]}
