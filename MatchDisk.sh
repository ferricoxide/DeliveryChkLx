DISKLIST="/dev/xvde1 /dev/xvde2 /dev/xvdj1"
ALLBLKDEVS="$(cd /sys/block ; echo *)"

# Check DISKLIST to compute parent device
for ELEM in ${DISKLIST}
do
   ELEMCK=$(echo ${ELEM} | sed 's#/dev/##')
   while [ "${ELEMCK}" != "" ]
   do
      if [[ ${ALLBLKDEVS} =~ (^| )${ELEMCK}($| ) ]]
      then
          REALDISKS+=" /dev/${ELEMCK}"
          break
      else
          ELEMCK=$(echo ${ELEMCK} | sed 's/.$//')
      fi
   done
done

echo "Real devs: ${REALDISKS}"
