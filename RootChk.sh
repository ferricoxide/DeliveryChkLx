#!/bin/sh
#
# Script to audit filesystems/volumes/devices used for hosting the
# root (OS) filesystems:
#   o Number of devices
#   o Size of devices
#   o Partitioning of devices
#     § if any STIG-mandated mounts are missing
#     § if any volumes present that should not be
#     § Size of partitions/LVs
#     § Mount options (and if any STIG-mandated options are absent
#################################################################
BLOCKDEVS=($(fdisk -lu | awk '/Disk \/dev\/.*bytes/{ print $2}' | \
           grep -v "/mapper/" | sed 's/:$//'))
KEYROOTDIRS=(/ /boot)
STIGMNTS=(		# STIG-mandated mounts
   /var
   /var/log
   /var/log/audit
   /home
   /tmp
)

# Color-coded status tokens
TOKERR="\033[0;33m[CHECK]\033[0m"
TOKAOK="\033[0;32m[OK]\033[0m"

# Check if key directories are mountpoints (per STIGs)
function StigMounts() {
   local COUNT
   while [[ ${COUNT} -lt ${#STIGMNTS[@]} ]]
   do
      mountpoint -q ${STIGMNTS[${COUNT}]}
      if [[ $? -eq 0 ]]
      then
         printf "${TOKAOK}\t${STIGMNTS[${COUNT}]} is a mount per STIGS\n"
      else
         printf "${TOKERR}\t${STIGMNTS[${COUNT}]} is not a mount\n"
      fi
      
      ((COUNT++))
   done
      
}

StigMounts
