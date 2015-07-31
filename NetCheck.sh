#!/bin/sh
#
# * Network Services
#   * Verify that nameservers defined in /etc/resolv.conf are reachable
#     * Check if nameservers defined					( )
#     * Check if declared servers are valid				( )
#     * Check if name service-switch consults DNS			( )
#   * Verify that ntp servers defined in /etc/ntp.conf are reachable
#     * Check if file exists						( )
#     * Check if service enabled					(✓)
#     * Check if service is running					(✓)
#     * Check if declared servers are valid				( )
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
TOKERR="\033[0;33m[CHECK]\033[0m"
TOKAOK="\033[0;32m[OK]\033[0m"
TOKINF="\033[0;0m[INFO]\033[0m"

function RunAtBoot() {
   local CFGSTAT=$(chkconfig ${1} --list | \
                   sed -e 's/^.*'${CURRUNLEVL}'://' \
                   -e 's/[	 ][	 ]*.*$//')
   echo ${CFGSTAT}
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

   # Check if Xinetd is configured to run from boot
   if [[ "${XNETCFGSTAT}" = "on" ]]
   then
      printf "${TOKINF}\tXinetd service enabled for this run-level.\n"

      # Check if Xinetd is actively-running
      if [[ ${XNETSVCSTAT} -eq 0 ]]
      then
         printf "${TOKINF}\tXinetd service-launcher running.\n"
      else
         printf "${TOKERR}\tXinetd service-launcher not running.\n"
      fi

      CheckXinetdSvcs
   elif [[ ${XNETSVCSTAT} -eq 0 ]]
   then
      printf "${TOKINF}\tXinetd service disabled for this run-level.\n"
      printf "${TOKERR}\tXinetd service-launcher running.\n"
      # Note: the CheckXinetdSvcs function's dependecies break
      #       when Xinetd is not configured to start at boot
   else
      printf "${TOKINF}\tXinetd service disabled for this run-level.\n"
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

function NtpdChecks() {
   local NTPDCFGSTAT=$(RunAtBoot ntpd)
   local NTPDSVCSTAT=$(service ntpd status > /dev/null 2>&1)$?

   if [[ "${NTPDCFGSTAT}" = "on" ]]
   then
      printf "${TOKINF}\tThe ntpd service enabled for this run-level.\n"
      # Check if NTPD is actively-running
      if [[ ${NTPDSVCSTAT} -eq 0 ]]
      then
         printf "${TOKINF}\tNTPD time-service is running.\n"
      else
         printf "${TOKERR}\tNTPD time-service is not running.\n"
      fi
   else
      printf "${TOKINF}\tThe ntpd service enabled for this run-level.\n"
   fi

}


#########
## MAIN
#########

# Only call extended Xinetd checks if service installed
if [[ "${HAVEXINETD}" = "yes" ]]
then
   printf "${TOKINF}\tXinetd service-launcher installed.\n"
   CheckXinetdMain
else
   printf "${TOKINF}\tXinetd service-launcher not installed.\n"
fi
LibWrapChecks
NtpdChecks
