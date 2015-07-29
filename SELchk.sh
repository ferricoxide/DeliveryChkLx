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
