#!/bin/sh
#
# * Network Services
#   * Verify that nameservers defined in /etc/resolv.conf are reachable
#     * Check if nameservers defined					(✓)
#     * Check if declared servers are valid				(✓)
#     * Check if name service-switch consults DNS			(✓)
#   * Verify state of NTP
#     * Check if ntp.conf file exists					(✓)
#     * Check if service enabled					(✓)
#     * Check if service is running					(✓)
#     * Check if declared servers are valid				(✓)
#   * Check configuration of IPTables					( )
#   * Check configuration of /etc/hosts.allow
#     * Check if file exists						(✓)
#     * Check if active rules present					(✓)
#   * Check configuration of /etc/hosts.deny
#     * Check if file exists						(✓)
#     * Check if active rules present					(✓)
#   * Check configuration of xinetd					
#     * Check install-status						(✓)
#     * Check start at boot						(✓)
#     * Check running-status						(✓)
#     * Check managed-services' statuses				(✓)
#
# LEGEND:
#   (✓) Feature implemented
#   ( ) Feature not implemented
#
#################################################################
HAVEXINETD=$(rpm --quiet -q xinetd && echo "yes" || echo "no")
CURRUNLEVL=$(who -r | awk '{print $2}')

# Color-coded status tokens
TOKBAD="\033[0;31m[ALERT]\033[0m"
TOKERR="\033[0;33m[CHECK]\033[0m"
TOKAOK="\033[0;32m[OK]\033[0m"
TOKINF="\033[0;0m[INFO]\033[0m"

function RunAtBoot() {
   local CFGSTAT=$(chkconfig ${1} --list | \
                   sed -e 's/^.*'${CURRUNLEVL}'://' \
                   -e 's/[	 ][	 ]*.*$//')
   echo ${CFGSTAT}
}

function PingTest() {
  local SVC="${1}"
  local TARG="${2}"
  local PINGRSLT=$(ping -q -t 1 -c 1 "${TARG}" > /dev/null 2>&1)$?

  if [[ ${PINGRSLT} -eq 0 ]]
  then
     printf "${TOKAOK}\t${SVC}: ${TARG} responds to ping\n"
  else
     printf "${TOKERR}\t${SVC}: ${TARG} does not respond to ping\n"
  fi
}

function NtpdChecks() {
   local NTPDCFGSTAT=$(RunAtBoot ntpd)
   local NTPDSVCSTAT=$(service ntpd status > /dev/null 2>&1)$?
   local SVC="NTPD"
   local CFGFILE="/etc/ntp.conf"

   if [[ "${NTPDCFGSTAT}" = "on" ]]
   then
      printf "${TOKINF}\t${SVC}: service enabled for this run-level.\n"
      # Check if NTPD is actively-running
      if [[ ${NTPDSVCSTAT} -eq 0 ]]
      then
         printf "${TOKINF}\t${SVC}: time-service is running.\n"
      else
         printf "${TOKERR}\t${SVC}: time-service is not running.\n"
      fi

      # Basic service-validity checks
      if [[ -s ${CFGFILE} ]]
      then
         printf "${TOKAOK}\t${SVC}: config-file ${CFGFILE} exists.\n"
         for HOST in $(awk '/^server/{ print $2 }' ${CFGFILE})
         do
            printf "${TOKINF}\t${SVC}: Trying to ping ${HOST}...\n"
            PingTest NTPD "${HOST}"

            export HOST
            printf "${TOKINF}\t${SVC}: Attempting service-connect to "
            printf "${HOST}...\n"
            local SOCKTEST=$(timeout 5 bash -c 'cat < /dev/null > \
                             /dev/tcp/${HOST}/123')$?

            if [[ ${SOCKTEST} -eq 0 ]]
            then
               printf "${TOKAOK}\t${SVC}: Socket-test passed.\n"
            else
               printf "${TOKBAD}\t${SVC}: Socket-test failed.\n"
            fi
         done
      fi
   else
      printf "${TOKINF}\t${SVC}: service disabled for this run-level.\n"
   fi

}

function DnsCheck() {
   local SVC="DNS"
   local CFGFILE="/etc/resolv.conf"
   local SWITCHCFG="/etc/nsswitch.conf"

   local SERVERLIST=($(awk '/^[ ]*nameserver/{print $2}' ${CFGFILE}))
   local SERVERLIST=${SERVERLIST[@]}
   if [[ "${SERVERLIST}" = "" ]]
   then
      printf "${TOKBAD}\t${SVC}: No server entries found in ${CFGFILE}.\n"
   else
      printf "${TOKAOK}\t${SVC}: Found nameserver(s): ${SERVERLIST}\n"
      for HOST in ${SERVERLIST}
      do
         printf "${TOKINF}\t${SVC}: Trying to ping ${HOST}...\n"
         PingTest DNS "${HOST}"

         # Need to be a bit fancier...
         export HOST
         printf "${TOKINF}\t${SVC}: Attempting service-connect to ${HOST}...\n"
         local SOCKTEST=$(timeout 5 bash -c 'cat < /dev/null > \
                          /dev/tcp/${HOST}/53')$?

         if [[ ${SOCKTEST} -eq 0 ]]
         then
            printf "${TOKAOK}\t${SVC}: Socket-test passed.\n"
         else
            printf "${TOKBAD}\t${SVC}: Socket-test failed.\n"
         fi

      done
   fi

   local NSSWITCH=$(grep -qE "^hosts:.*dns.*" ${SWITCHCFG})$?
   if [[ ${NSSWITCH} -eq 0 ]]
   then
      printf "${TOKAOK}\t${SVC}: ${SWITCHCFG} configured for ${SVC}\n"
   else
      printf "${TOKBAD}\t${SVC}: ${SWITCHCFG} not configured for ${SVC}\n"
   fi

}

function CheckXinetdSvcs() {
   XINETSVCS=$(chkconfig --list --type xinetd | awk '{print $1}' | \
               sed -n -e '/:$/p' | sed -e 's/:$//')
   for XSVC in ${XINETSVCS}
   do
      SVCSTAT=$(chkconfig --list --type xinetd ${XSVC} | awk '{print $2}')
      printf "${TOKINF}\tXinetd-managed service ${XSVC} is ${SVCSTAT}.\n"
   done
}

function CheckXinetdMain() {
   local XNETSVCSTAT=$(service xinetd status > /dev/null 2>&1)$?
   local XNETCFGSTAT=$(RunAtBoot xinetd)
   local SVC="Xinetd"

   # Check if Xinetd is configured to run from boot
   if [[ "${XNETCFGSTAT}" = "on" ]]
   then
      printf "${TOKINF}\t${SVC}: service enabled for this run-level.\n"

      # Check if Xinetd is actively-running
      if [[ ${XNETSVCSTAT} -eq 0 ]]
      then
         printf "${TOKINF}\t${SVC}: service-launcher running.\n"
      else
         printf "${TOKERR}\t${SVC}: service-launcher not running.\n"
      fi

      CheckXinetdSvcs
   elif [[ ${XNETSVCSTAT} -eq 0 ]]
   then
      printf "${TOKINF}\t${SVC}: service disabled for this run-level.\n"
      printf "${TOKERR}\t${SVC}: service-launcher running.\n"
      # Note: the CheckXinetdSvcs function's dependecies break
      #       when Xinetd is not configured to start at boot
   else
      printf "${TOKINF}\t${SVC}: service disabled for this run-level.\n"
   fi 
}

function LibWrapChecks() {
   local LIBWRAPCFG=(/etc/hosts.allow /etc/hosts.deny)

   while [[ ${LOOP} -lt ${#LIBWRAPCFG[@]} ]]
   do
      # Check if file exists
      if [[ -s ${LIBWRAPCFG[${LOOP}]} ]]
      then
         printf "${TOKINF}\t${LIBWRAPCFG[${LOOP}]} exists.\n"
      fi
      # Check if any config directives active
      if [[ "$(grep -v "^#" ${LIBWRAPCFG[${LOOP}]})" = "" ]]
      then
         printf "\t* Found no service-definitions.\n"
      else
         printf "\t* Found service-definitions:\n"
         grep -v "^#" ${LIBWRAPCFG[${LOOP}]} | sed 's/^/\t  | /'
         
      fi
      LOOP+=1
   done
}


#########
## MAIN
#########

DnsCheck
NtpdChecks
# Only call extended Xinetd checks if service installed
if [[ "${HAVEXINETD}" = "yes" ]]
then
   printf "${TOKINF}\tXinetd: service-launcher installed.\n"
   CheckXinetdMain
else
   printf "${TOKINF}\tXinetd: service-launcher not installed.\n"
fi
LibWrapChecks
