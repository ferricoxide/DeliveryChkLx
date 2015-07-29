#!/bin/sh
#
# * SELinux configuration
#   * Verify /etc/selinux/config and /etc/sysconfig/selinux linking	( )
#   * What enforcement-mode is set					( )
#   * What enforcement-type is set					( )
#
#################################################################
FIX=${FIX:-0}
SELCFCANON=/etc/selinux/config
SELCFSYSCF=/etc/sysconfig/selinux	# Linkpath ../selinux/config

# Color-coded output tags
TOKERR="\033[0;33m[CHECK]\033[0m"
TOKAOK="\033[0;32m[OK]\033[0m"
TOKINF="\033[0;0m[INFO]\033[0m"

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

ChkSELlink
