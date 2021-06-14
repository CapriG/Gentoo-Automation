# Gentoo-Automation

This library currently contains 4 scripts which will make the life of any Gentoo Admin Easier.

Deploy.pl:

Automates deployment of Diskless Gentoo Terminals. (3 Seconds Per Terminal, can deploy hundreds if not thousands of machines)

Can be used after creating initial Terminal after completing Gentoo Diskless Tutorial from Official Gentoo Wiki.

Simply compress the Terminal Filesystem to 0.tar and set parameters in the header of the script.

Hardware Terminals need only be given a DHCP Reservation and PXE Boot Config in BIOS.

Identical Hardware makes things easier but the Terminal Kernel can be configured for a wide range of machines.



***Can redeploy an entire network to a new build in minutes after first use. ***



Read the pinp() function first to gather full functionality.

VMDeploy.pl :

***Deploys KVM Virtual Machine images (Linux / Windows) along with automagic KVM configuration complete with RDP / SPICE Desktop Icon Configuration. ***

Backup.pl :

***Will Mount a Backup Filesystem and Snapshot Filesystem to expedite live KVM Backups with full KVM configuration export and hash checking with automatic unmount after backup is over.

Good enough to run against cron after successful initial use.

Restore.pl:

Very simple Restore Function which moves over corrupt disk and re-deploys KVM Files according to the Virtual Machine Name provided.

***(Made to only affect a single machine at a time as a fail-safe to prevent accidential mass deletion).



