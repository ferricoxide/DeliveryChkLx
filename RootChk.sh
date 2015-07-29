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
PHYSDEVLST=""
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
TOKINF="\033[0;0m[INFO]\033[0m"

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

function CreateRootKVP() {
   local COUNT
   while [[ ${COUNT} -lt ${#ALLROOTDIRS[@]} ]]
   do
      local ARRKEY="${ALLROOTDIRS[${COUNT}]}"
      local FSDEV=$(grep " ${ARRKEY} " /proc/mounts | 
                    sed -e '/rootfs/d' -e 's/ .*$//')
      # Dump into associative-array for later processing
      ROOTDIRSKVP[${ALLROOTDIRS[${COUNT}]}]="${FSDEV}"
      
      ((COUNT++))
   done
}

function CoreDiskObjects() {
   local STOROBJ=$1
   case ${STOROBJ} in
      tmpfs) 
         echo "is not on a block device"
         ;;
      /dev/mapper/*)
         local PHYSDEV=$(lvs --noheadings -o devices ${STOROBJ} | \
                         sed -e 's/(.*$//' -e 's/^ *//')

         if [[ ${PHYSDEVLST} =~ (^| )${PHYSDEV}($| ) ]]
         then
            echo > /dev/null # This is a no-op
         else
            PHYSDEVLST="${PHYSDEVLST} ${PHYSDEV}"
         fi

         echo "is on an LVM device"
         ;;
      /dev/xv*|/dev/sd*)

         if [[ ${PHYSDEVLST} =~ (^| )${STOROBJ}($| ) ]]
         then
            echo > /dev/null # This is a no-op
         else
            PHYSDEVLST="${PHYSDEVLST} ${STOROBJ}"
         fi
         echo "is on a bare disk"
         ;;
      *)
         echo "is NOT categorizable"
         ;;
   esac
}

function CheckIfPart() {
   local DEVLIST="${1}"
   local DISKLIST=$(fdisk -lu | grep "^Disk /dev" | grep -v mapper)
   for DEV in ${DEVLIST}
   do
      if [[ ${DISKLIST} =~ (^| )${DEV}($| ) ]]
      then
         printf "\t${DEV} is a physical disk\n"
      else
         printf "\t${DEV} is a partition on a physical disk\n"
      fi
   done
  
}

function GetRootVG() {
   local GETLVS=$(lvs --noheadings $(mount | awk '/ \/ /{ print $1}') 2> /dev/null)

   if [ "${GETLVS}" = "" ]
   then
      printf "${TOKINF}\t\"/\" filesystem not in LVM Volume-Group\n"
   else
      VG=$(echo ${GETLVS} | awk '{print $2}')
      printf "${TOKINF}\t\"/\" filesystem is in LVM Volume-Group \"${VG}\".\n"
   fi
}

function RootVgMember() {
   local LVLIST=$(lvs --noheadings VolGroup00 | awk '{print $1}')
   local XCKLST="/ ${STIGMNTS[@]} /usr /opt"

   echo ${LVLIST}
   echo ${XCKLST}

   # See only expected root volumes are in root volume-group
   for LVOL in ${LVLIST}
   do
      local VOL2MNT=$(grep -w ${LVOL} /proc/mounts | awk '{print $2}')
      local ISSWAP=$(awk '/'${LVOL}'/{print $2}' /etc/fstab)

      if [[ ${XCKLST} =~ (^| )${VOL2MNT}($| ) ]] || [ "${ISSWAP}" != "" ]
      then
         printf "${TOKAOK}\t${LVOL} should be in ${VG}\n"
      else
         printf "${TOKERR}\t${LVOL} not expected to be in ${VG}\n"
      fi
   done
      
}


StigMounts
CreateRootKVP

for ELEM in "${!ROOTDIRSKVP[@]}"
do
   printf "${TOKINF}\t${ELEM} "
   CoreDiskObjects "${ROOTDIRSKVP[${ELEM}]}"
done

printf "${TOKINF}\tOS filesystems found on: ${PHYSDEVLST}\n"
CheckIfPart "${PHYSDEVLST}"

GetRootVG
RootVgMember
