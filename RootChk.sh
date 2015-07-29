#!/bin/sh
#
# Script to audit filesystems/volumes/devices used for hosting the
# root (OS) filesystems:
#   o Number of devices
#   o Size of devices
#   o Partitioning of devices
#     § if any STIG-mandated mounts are missing
#     § if any LVM2 volumes present in root VG that should not be
#     § Size of partitions/LVs
#     § Mount options (and if any STIG-mandated options are absent
#################################################################
BLOCKDEVS=($(fdisk -lu | awk '/Disk \/dev\/.*bytes/{ print $2}' | \
           grep -v "/mapper/" | sed 's/:$//'))
KEYROOTDIRS=(/ /boot)
ALLROOTDIRS=(${KEYROOTDIRS[@]})
STIGMNTS=(		# STIG-mandated mounts
   /var
   /var/log
   /var/log/audit
   /home
   /tmp
)
declare -A ROOTDIRSKVP

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
         ALLROOTDIRS+=(${STIGMNTS[${COUNT}]})
      else
         printf "${TOKERR}\t${STIGMNTS[${COUNT}]} is not a mount\n"
      fi
      
      ((COUNT++))
   done
      
}

function GetMountDevs() {
   local COUNT
   while [[ ${COUNT} -lt ${#ALLROOTDIRS[@]} ]]
   do
      local ARRKEY="${ALLROOTDIRS[${COUNT}]}"
      local FSDEV=$(grep " ${ARRKEY} " /proc/mounts | sed 's/ .*$//')
      echo "${FSDEV} mounted at ${ALLROOTDIRS[${COUNT}]}"
      ROOTDIRSKVP[${ALLROOTDIRS[${COUNT}]}]="${FSDEV}"
      
      ((COUNT++))
   done
}

StigMounts
GetMountDevs

for ELEM in "${!ROOTDIRSKVP[@]}"
do
   echo "Key:   ${ELEM}"
   echo "Value: ${ROOTDIRSKVP[${ELEM}]}"
done
