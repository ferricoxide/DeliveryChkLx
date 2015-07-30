#!/bin/sh
#
# * SELinux configuration
#   * Verify /etc/selinux/config and /etc/sysconfig/selinux linking	(✓)
#   * What enforcement-mode is set					( )
#   * What enforcement-mode is active					( )
#   * What enforcement-type is set					( )
#   * Check whether set at boot (via GRUB)				( )
#
#################################################################
FIX=${FIX:-0}
SELCFCANON=/etc/selinux/config
SELCFSYSCF=/etc/sysconfig/selinux	# Linkpath ../selinux/config
NORMALIZE='tr "[:upper:]" "[:lower:]"'


# Color-coded output tags
TOKERR="\033[0;33m[CHECK]\033[0m"
TOKAOK="\033[0;32m[OK]\033[0m"
TOKINF="\033[0;0m[INFO]\033[0m"

# Check whether SELINUX config files properly linked
function ChkSELlink() {
   if [[ $(readlink -f ${SELCFSYSCF}) = ${SELCFCANON} ]]
   then
      printf "${TOKAOK}\t${SELCFSYSCF} is a symlink to ${SELCFCANON}\n"
   else
      printf "${TOKERR}\t${SELCFSYSCF} is NOT a symlink to ${SELCFCANON}"
      if [[ ${FIX} -eq 1 ]]
      then
         echo " ...fixing."
         rm ${SELCFSYSCF}
         (cd /etc/sysconfig ; ln -s ../selinux/config ${SELCFSYSCF})
      else
         echo
      fi
   fi
}

# Get SEL enforcement-mode - alert if different
function ChkModeMatch() {
   SETSELMODE=$(awk -F"=" '/^SELINUX=/{ print $2 }' ${SELCFCANON} | \
                ${NORMALIZE})
   ACTSELMODE=$(getenforce | ${NORMALIZE})

   if [[ "${ACTSELMODE}" = "${SETSELMODE}" ]]
   then
      printf "${TOKINF}\tSELINUX configured-mode set to ${SETSELMODE}\n"
      printf "${TOKINF}\tSELINUX active-mode set to ${ACTSELMODE}\n"
   else
      printf "${TOKERR}\tSELINUX configured-mode set to ${SETSELMODE}\n"
      printf "${TOKERR}\tSELINUX active-mode set to ${ACTSELMODE}\n"
   fi
}

ChkSELlink
ChkModeMatch
