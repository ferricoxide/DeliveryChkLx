# DeliveryChkLx
Collection of scripts to verify delivery-readiness of Linux instances
 
 
**Note on Issues-Submission**: this repository is duplicated to other locations. If an issue is discovered, only issues that are submitted via [the primary dev-repository](https://github.com/ferricoxide/DeliveryChkLx) will be accepted.

## Info Gathered
### RootChk.sh:
* Size/Device-node for root disk
* Partitioning info for root disk
* LVM2 VolumeGroup space allocations
* `df` info for root filesystems
* `mount` info for root filesystems and associated pseudo-filesystems

### GrubLinks.sh
* Grub info
  * Audit-at-boot?
  * Selinux-at-boot?
  * Nousb-at-boot?
  * FIPS-at-boot?
* Linking-verification

### SELchk.sh
* Verify /etc/selinux/config and /etc/sysconfig/selinux linking
* What enforcement-mode is set
* What enforcement-mode is active
* What enforcement-type is set
* Check whether system boooted with SELINUX active (via GRUB)
* Check whether set at boot (via GRUB)

* Presence of known/approved A/V solution(s)
* Presence of remote log-aggregation (splunk, etc.)
* SSH Daemon config
  * Grab all active-defines
  * Summarize:
    * Key-based logins allowed
    * GSSAPI-based logins allowed
    * FIPS-ready?
    * PermitRootLogin status
* Configuration of `sudo`
* RPM Information
  * RPM count
  * RPM manifest
  * Configured Repos
* Centralized Auth Setup
  * PBIS
  * Centrify
  * Native

### NetCheck.sh
* DNS Configuration
  * Verify that nameservers defined in /etc/resolv.conf are reachable
  * Check if nameservers defined
  * Check if declared servers are valid
  * Check if name service-switch consults DNS
* NTP Configuration
  * Check if ntp.conf file exists
  * Check if service enabled
  * Check if service is running
  * Check if declared servers are valid
* Check configuration of IPTables
* Check configuration of /etc/hosts.allow
  * Check if file exists
  * Check if active rules present
* Check configuration of /etc/hosts.deny
  * Check if file exists
  * Check if active rules present
* Check configuration of xinetd
  * Check install-status
  * Check start at boot
  * Check running-status
  * Check managed-services' statuses

* sysctl.conf contents
* Kernel Loadable Module Config
  * anaconda.conf
  * blacklist.conf
  * dist-alsa.conf
  * dist.conf
  * dist-oss.conf
  * custom defines:
    * nousb.conf
    * vmware-tools.conf
    * STIG-mandated additions
* Local-user objects:
  * Objects in /etc/passwd
  * Objects in /etc/shadow
  * Objects in /etc/group
