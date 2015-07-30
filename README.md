# DeliveryChkLx
Collection of scripts to verify delivery-readiness of Linux instances

## Info Gathered
### RootChk.sh:
* Size/Device-node for root disk
* Partitioning info for root disk
* LVM2 VolumeGroup space allocations
* `df` info for root filesystems
* `mount` info for root filesystems and associated pseudo-filesystems

### GrubLinks.sh
* Grub info
  * Contents
    * Audit-at-boot?
    * Selinux-at-boot?
    * Nousb-at-boot?
    * FIPS-at-boot?
  * Linking-verification

### SELchk.sh
* SELINUX Info
  * Symlink between /etc/selinux/conf and /etc/sysconfig/selinux
  * Configured enforcing-mode
  * Active enforcing-mode
  * Targeted enforcement-profile

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
* Network Services
  * Verify that nameservers defined in /etc/resolv.conf are reachable
  * Verify that ntp servers defined in /etc/ntp.conf are reachable
  * Check configuration of IPTables
  * Check configuration of /etc/hosts.allow
  * Check configuration of /etc/hosts.deny
  * Check configuration of xinetd
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
