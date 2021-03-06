#!/bin/sh
#
# Script to ensure that GRUB-related config files exist in their
# proper forms and locations
#
############################################################
SAVDATE=$(date "+%Y%m%d%H%M")
REALBOOTD="/boot"
REALGRUBD="${REALBOOTD}/grub"
GRUBCFG="${REALGRUBD}/grub.conf"
GRUBETC="/etc/grub.conf"
XENBOOTD="/boot/boot"
XENGRUBD="${XENBOOTD}/grub"
XENGRUBCFG="${XENGRUBD}/grub.conf"

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

   # Verify /etc/grub.conf state
   if [ -e ${GRUBETC} ]
   then
      # See if /etc/grub.conf is a symlink
      if [ -h ${GRUBETC} ]
      then
         WHEREPT=$(readlink ${GRUBETC})
         # Ensure /etc/grub.conf points to /boot/grub/grub.conf
         if [ "${WHEREPT}" = "${GRUBCFG}" ]
         then
            echo "${GRUBETC} symlinks to ${GRUBCFG}"
         else
            printf "${GRUBETC} does not point to " > /dev/stderr
            echo "${GRUBCFG}. Fixing." > /dev/stderr
            # Let's save the contents for later...
            mv ${GRUBETC} ${GRUBETC}-BAK_${SAVDATE}
            if [[ $? -eq 0 ]]
            then
               ln -s ${GRUBCFG} ${GRUBETC}
            else
               echo "Cannot fix ${GRUBETC}"
               RETCODE=1
            fi
            RETCODE=1
         fi
      else
         # Let's save the contents for later...
         mv ${GRUBETC} ${GRUBETC}-BAK_${SAVDATE}
         if [[ $? -eq 0 ]]
         then
            ln -s ${GRUBCFG} ${GRUBETC}
         else
            echo "Cannot fix ${GRUBETC}"
            RETCODE=1
         fi
         RETCODE=1
      fi
   else
      ln -s ${GRUBCFG} ${GRUBETC} || { RETCODE=1 ; \
        echo "Link-creation failed" > /dev/stderr ;}
   fi
else
   # Alert if file does not exist
   printf "${GRUBCFG} does not exist: does this " > /dev/stderr
   echo "system use GRUB to boot?" > /dev/stder
   RETCODE=1
fi

# See if /boot/boot exists
if [ -d ${XENBOOTD} ]
then
   # Ensure /boot/boot/grub/grub.conf is a real file
   if [ -e ${XENGRUBCFG} ] && [ ! -h ${XENGRUBCFG} ]
   then
      # Check link-count
      if [[ $(stat -c "%h" ${XENGRUBCFG}) -eq 1 ]]
      then
         printf "${XENGRUBCFG} is not hardlinked. " > /dev/stderr
         echo "Attempting to fix..." > /dev/stderr
         mv ${XENGRUBCFG} ${XENGRUBCFG}-BAK_${SAVDATE}
         # Check save operation status
         if [[ $? -eq 0 ]]
         then
            ln ${GRUBCFG} ${XENGRUBCFG} || { RETCODE=1 ; \
              echo "Failed." > /dev/stderr ; }
         else
            echo "Could not move ${XENGRUBCFG}" > /dev/stderr
            RETCODE=1
         fi
      elif [[ $(find /boot -inum $(stat -c "%i" ${GRUBCFG}) | \
        grep -w ${GRUBCFG}) = "${GRUBCFG}" ]]
      then
         echo "${XENGRUBCFG} hardlinks to ${GRUBCFG}"
      fi
   fi
fi

# Clean up menu.lst file(s)
MENULSTS=$(find ${REALBOOTD} -name menu.lst -type l)
for MENU in ${MENULSTS}
do
   MENUDIR=$(dirname ${MENU})
   LNKSRC=$(readlink ${MENU})
   if [[ $(echo ${LNKSRC} | grep -x "grub.conf") = "grub.conf" ]]
   then
      echo "${MENU} links from ./grub.conf"
   else
      echo "${MENU} does not link from ./grub.conf" > /dev/stderr
      RETCODE=1
   fi
done

if [ "${RETCODE}" != "" ]
then
   echo "Notice: one or more validations failed" > /dev/stderr
   exit ${RETCODE}
fi
