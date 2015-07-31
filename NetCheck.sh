#!/bin/sh
#
# * Network Services
#   * Verify that nameservers defined in /etc/resolv.conf are reachable	( )
#   * Verify that ntp servers defined in /etc/ntp.conf are reachable	( )
#   * Check configuration of IPTables					( )
#   * Check configuration of /etc/hosts.allow				( )
#   * Check configuration of /etc/hosts.deny				( )
#   * Check configuration of xinetd					( )
#
# LEGEND:
#   (✓) Feature implemented
#   ( ) Feature not implemented
#
#################################################################
HAVEXINETD=$(rpm --quiet -q xinetd && echo "yes" || echo "no")

# Color-coded status tokens
TOKERR="\033[0;33m[CHECK]\033[0m"
TOKAOK="\033[0;32m[OK]\033[0m"
TOKINF="\033[0;0m[INFO]\033[0m"

function CheckXinetdStuff() {
   service xinetd status > /dev/null 2>&1
   if [[ $? -eq 0 ]]
   then
      printf "${TOKINF}\tXinetd service-launcher running.\n"
   else
      printf "${TOKINF}\tXinetd service-launcher not running.\n"
   fi 
}

if [[ "${HAVEXINETD}" = "yes" ]]
then
   printf "${TOKINF}\tXinetd service-launcher installed.\n"
   CheckXinetdStuff
else
   printf "${TOKINF}\tXinetd service-launcher not installed.\n"
fi
