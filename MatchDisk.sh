function GetRealDsk() {
   local DISKLIST="${1}"
   local ALLBLKDEVS="$(cd /sys/block ; echo *)"
   local REALDISKS=""

   # Check DISKLIST to compute parent device
   for ELEM in ${DISKLIST}
   do
      ELEMCK=$(echo ${ELEM} | sed 's#/dev/##')
      while [ "${ELEMCK}" != "" ]
      do
         if [[ ${ALLBLKDEVS} =~ (^| )${ELEMCK}($| ) ]]
         then
            if [[ ${REALDISKS} =~ (^| )/dev/${ELEMCK}($| ) ]]
            then
               echo > /dev/null
            else
               REALDISKS+="/dev/${ELEMCK}"
               REALDISKS+=" "
            fi 
            break
         else
             ELEMCK=$(echo ${ELEMCK} | sed 's/.$//')
         fi
      done
   done
   
   echo "Real devs: ${REALDISKS}"
}
