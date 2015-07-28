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
ROOTDIRS=($(echo "/" ; ls -l / | awk '/^d/{printf("/%s\n",$9)}'))
STIGMNTS=(		# STIG-mandated mounts
   /var
   /var/log
   /var/log/audit
   /home
   /tmp
)

while [[ ${COUNT} -lt ${#ROOTDIRS[@]} ]]
do
   mountpoint -q ${ROOTDIRS[${COUNT}]}
   if [[ $? -eq 0 ]]
   then
      echo "Adding \"${ROOTDIRS[${COUNT}]}\" to ROOTDEVS array."
      ROOTDEVS+=(${ROOTDIRS[${COUNT}]})
   fi
   ((COUNT++))
done

echo ${ROOTDEVS[@]}
echo ${STIGMNTS[@]}
