#!/usr/bin/perl -w
# Use -w or -d --^ for warnings/debug
#
# Capri.Gomez@Gmail.com
#
# Backup.pl
# Version 2.02a
# Script for Managing and Executing Image-level KVM Backups.

use Socket;
use v5.10;

### Advanced Config ###

# Backup Disk ID
$bkdiskid = "000c8520";

# Backup Path
$backpath = "/mnt/backup/";

# Snapshot Disk ID
$snapdiskid = "c3072e18";

# Snapshot Path
$snappath = "/mnt/scratch/";

# KVM Disk Path
$vmdsk = "/var/lib/libvirt/images/";

### End Advanced Config ###

# Process input...
sub pinp {
	# This function will take options from command line in order to know who/what is running it. 
}

# Interface for managing backup jobs
sub config {
	# CLI based GUI for managing backup logs
	# Should work well over SSH
	# Will create and be able to produce current jobs and past reports
}

# Run a backup job
sub routine {

	# Mount Backup Filesystem
	&mountback();

	# Mount Snapshot Filesystem
	&mountsnap();
	
	$today = &today();
	# Variable for root of todays directory
	$todayroot = $backpath . $today;
	$dirpath = $todayroot;
	$IFF = &dircheck($dirpath);

		if($IFF == 0) { 
			# Create Backup Folders if they don't exist
			&mknewdir($dirpath) || die("Could not create $dirpath");
		} #else { print "It thinks the dir is there \n"; }
		
	# General Log File
	$log = "$dirpath/KVMBK/";

	# Load Configuration and execute backups in order
	open(BKCONFIG, "<" . "/root/backups") || die("Could not open config file");
	@VM = <BKCONFIG>;
		
	foreach (@VM) {
		chomp($_);
	}
	
	# Execute job
	&live(@VM);
	
	# Unmount Backup filesystem
	$diskid = $bkdiskid;
	&umount($diskid);
	# Unmount Snapshot filesystem
	$diskid = $snapdiskid;
	&umount($diskid);
	
	#print "\n@VM has been logged.\n";
}

# Execute "live" backup job
sub live {
	foreach(@VM) {
			
		$VM = $_;

		# Check for Backup Folders
		$dirpath = $todayroot . "/" . $VM;
		if(! &dircheck($dirpath)) { 
			# Create Backup Folders if they don't exist
			&mknewdir($dirpath);
		}
		# Obtain VM Status 
		# Save VM's according to status.
		given(&status($VM) {

			when(/shut\ off/) {

				$log = $log . &today() . ".bkd";
				# Open Log File
				open(LOG, ">>$log");
				print LOG &today();
				print LOG "\n";

				# Ascertain MD5 Sum for Disk
				$filemd5 = $vmdsk . "$VM.qcow2";
				$backuphash = &md5($filemd5);

				# Obtain size of Disk			
				$diskpath = $vmdsk . "$VM.qcow2";
				$filesize = &size($diskpath);
				$vmdisksize = abbrev($filesize);

				# Backup VM to destination 
				# Implement Timer...
				$backuppath = $dirpath;

				#print "Copying VDISK ($VM)...\n";
				&backupdisk($VM,$backuppath);
	
				# Verify VM Disk
				$filehasha = $backuphash;
				$filemd5 = $dirpath . "/$VM.qcow2";
				$filehashb = &md5($filemd5);
		
				$VER = &verify($filehasha,$filehashb);

				if ($VER) { print LOG "$VM Disk Copy Successful!(MD5 Verified)\n"; } else { print LOG "Error on Disk Copy...\n"; }

				# Dump XML
				$XMLDUMP = "virsh dumpxml $VM > $dirpath/$VM.xml";
				if (! system($XMLDUMP)) { $xmldumpstat = 1; }

				# Write to Log
					if (! $xmldumpstat) { print LOG "XML Dump Failed.\n"; }
					print LOG "$VM was off\n";
					print LOG "\n$VM Disk MD5 Hash:$backuphash\n";
					print LOG "$VM Disk Size:$vmdisksize\n";

				# Close Log
				close(LOG);
			}
			# When running, paused, crashed!?
			default() {
				
				$log = $log . &today() . ".bkd";
				# Open Log File
				open(LOG, ">>$log");
				print LOG &today();
				print LOG "\n";

				# Snapshot VM to $snappath
				#print "Saving $VM\n";
				&snapshot($VM);

				# Ascertain MD5 Sum for RAM and Disk
				$filemd5 = $snappath . $VM . ".ram";
				$snapshothash = &md5($filemd5);
				$filemd5 = $vmdsk . "$VM.qcow2";
				$backuphash = &md5($filemd5);

				# Obtain sizes for RAM and Disk
				$diskpath = $snappath . "$VM.ram";
				$filesize = &size($diskpath);
				$snapshotsize = abbrev($filesize);			
				$diskpath = $vmdsk . "$VM.qcow2";
				$filesize = &size($diskpath);
				$vmdisksize = abbrev($filesize);

				# Backup VM to destination 
				# Implement Timer...
				$backuppath = $dirpath;
				#print "Copying RAM ($VM)...\n";
				&backupram($VM,$backuppath);
				#print "Copying VDISK ($VM)...\n";
				&backupdisk($VM,$backuppath);

				# Verify VM Disk
				$filehasha = $backuphash;
				$filemd5 = $dirpath . "/$VM.qcow2";
				$filehashb = &md5($filemd5);
		
				$VER = &verify($filehasha,$filehashb);

				if ($VER) { print LOG "$VM Disk Copy Successful!(MD5 Verified)\n"; } else { print LOG "Error on Disk Copy...\n"; }

				# Verify RAM
				$filehasha = $snapshothash;
				$filemd5 = $dirpath . "/$VM.ram";
				$filehashb = &md5($filemd5);
		
				$VER2 = &verify($filehasha,$filehashb);

				if ($VER2) { print LOG "$VM RAM Copy Successful!(MD5 Verified)\n"; } else { print LOG "Error on RAM Copy...\n"; }

				# Restore VM
				&restore($snappath,$VM);
				#print "Restored $VM!\n";

				# Dump XML
				$XMLDUMP = "virsh dumpxml $VM > $dirpath/$VM.xml";
				if (! system($XMLDUMP)) { $xmldumpstat = 1; }

				# Delete RAM Snapshot from scratchpad
				$ramsnapdel = $snappath . $VM . ".ram";
				if (! system("rm -rf $ramsnapdel") { $ramdelstat = 1; }

				if (&status($VM) !~ /running/) { $vmstatstat = 0 }

				# Write to Log
				if (! $xmldumpstat) { print LOG "XML Dump Failed.\n"; }
				if (! $ramdelstat) { print LOG "RAM scratch deletion Failed.\n"; }
				if (! $vmstatstat) { print LOG "$VM could not be restored!\n"; }
				print LOG "\n$VM Disk MD5 Hash:$backuphash\n";
				print LOG "$VM Ram MD5 Hash:$snapshothash\n";
				print LOG "$VM Ram Size:$snapshotsize\n";
				print LOG "$VM Disk Size:$vmdisksize\n";
				# Close Log
				close(LOG);
			}
		}
	}
}
sub today {
	# Establish time for backup
	# date +%s for Unix Timestamp # date +%F for YYYY-MM-DD
	$currenttimestamp = `date +\%F`;
	chomp($currenttimestamp);

	return $currenttimestamp;
}

# Check if places already exist!
sub dircheck {
	if (-d $dirpath) { $exists = 1; } else { $exists = 0; }
	return $exists;
}

# Create new folder
sub mknewdir {
	$SS = `mkdir $dirpath`;
	if ($SS eq "") { return 1; } else { return 0; }
}

# Predict Usage for RAM Saves and Amalgamated Disks...
sub usage {
	# Report filesystem data.
	# exec("df -h | grep $kvmroot");
	# Report VM data size.
	# Report RAM state size (Get Used Mem Data)
}

# Identify Disk Path
sub identpath {
	
	# Determine Disk Device Path /dev/sd**
	$diskpath = `fdisk -l | grep $diskid -A 3 | grep /dev`;
	$diskpath = substr($diskpath, 0, 9);

	return $diskpath;
}

# Mount Disk
sub mount {

	$mountok = system("mount $diskpath $diskdir");
	return $mountok;
}

# Unmount Disk
sub umount {

	# Determine Disk Device Path /dev/sd*
	$diskpath = &identpath($diskid);

	# Umount disk
	$umountok = system("umount $diskpath");
	return $umountok;
}

# Verify integrity of Disk/RAM via MD5
sub verify {
	# Compare given MD5 hash with our own...
	if ($filehasha =~ $filehashb) { $match = 1; } else { $match = 0; }
	return $match;
}

# Retrieve VM Status
sub status {
	# Ask virsh for status
	$status = `virsh domstate $VM`;
	chomp($status);
	return $status;
}

# Return size in bytes
sub size {
	$size = -s "$diskpath";
	return $size;
}

# Abbreviate size of files.
sub abbrev {
	
	$kilo = 1024; # Bytes in a Kilo
	$mega = 1048576; # Mega
	$giga = 1073741824; # Giga
	$tera = 1099511627776; # Tera

	given($filesize) { 
		when(($filesize >= $kilo) && ($filesize < $mega)) {
			$filesize = $filesize / $kilo;
			$filesize = sprintf("%.2f", $filesize);
			$filesize = $filesize . "KB";
		}
		when(($filesize >= $mega) && ($filesize < $giga)) {
			$filesize = $filesize / $mega;
			$filesize = sprintf("%.2f", $filesize);
			$filesize = $filesize . "MB";
		}
		when(($filesize >= $giga) && ($filesize < $tera)) {
			$filesize = $filesize / $giga;
			$filesize = sprintf("%.2f", $filesize);
			$filesize = $filesize . "GB";
		}
		when($filesize > $tera) {
			$filesize = $filesize / $tera;
			$filesize = sprintf("%.2f", $filesize);
			$filesize = $filesize . "TB";
		}
		default {
			$filesize = $filesize . "B";
		}
	}
	return $filesize;
}

# Engage Virtual Machine
sub poweron {
	# Obtain VM Status...
	given(&status($VM)) {
		when("paused") {
			# Bring back VM from Paused State.
			$success = `virsh resume $VM`;
			$poweronstat = 1;
		}
		when("shut off") {
			# Turn VM from cold state.
			$success = `virsh start $VM`;
			$poweronstat = 2;
		}
		when("error: Domain is already active") {
			# It's already active!
			$poweronstat = 3;
		}
		default {
			# No match / Error
			$poweronstat = 0;
		}
	}	
	return $poweronstat;
}

# Restore RAM State
sub restore {

	# Domain restored from /mnt/scratch/WindowsXP.RAM
	# virsh restore $RAMPATH (--running || --paused)
	
	$restore = `virsh restore $snappath$VM.ram --running`;

	return $restore;
}

# Ascertain MD5 sum for file and return it.
# Pass absolute path of file
sub md5 {

	# md5sum $filepath
	# Keep first 32 characters from `md5sum`
	
	$md5 = `md5sum $filemd5`;
	$md5 = substr($md5, 0, 32);
	return $md5;
}

# Suspend in order to save RAM state as well... 
sub snapshot {

	# Save State
	# Domain WindowsXP saved to /tmp/scratch/WindowsXP.ram
	# virsh save $vm /mnt/scratch/$VM.ram
	$snapshot = `virsh save $VM $snappath$VM.ram`;
	
	if ($snapshot = "Domain $VM saved to " . $snappath . $VM . ".ram") {
		$snapshot = 1;
	}
	return $snapshot;
}

# Copy VM Disk and RAM to backup destination
# Pass absolute path of save state file and virtual disk.
sub backupdisk {

	# Copy raw image to backup destination
	$dskcopy = "rsync -avzq $vmdsk$VM.qcow2 $backuppath";
	system($dskcopy);
}

sub backupram {

	# Copy RAM to backup destination
	$ramcopy = "rsync -avzq $snappath$VM.ram $backuppath";
	system($ramcopy);
}

# Mount Snapshot Filesystem
sub mountsnap {

	$diskid = $snapdiskid;
	$diskpath = &identpath($diskid); 
	$diskdir = $snappath;
	
	if (! &mount($diskid,$diskpath,$diskdir)) { return 1; } else { return 0; }
}

# Mount Backup Filesystem
sub mountback {

	$diskid = $bkdiskid;
	$diskpath = &identpath($diskid); 
	$diskdir = $backpath;
	
	if (! &mount($diskid,$diskpath,$diskdir)) { return 1; } else { return 0; }
}

# Print Help for lost wanderers...
sub help() {

print "
# backup.pl
################################################################################
";
#
}
# Execute Backup
&routine();

# To-Do:
# Create function to write restore script for each VM backup
# Finish functions for determining filesystem stats in order to guage whether or not to continue
# Create E-Mail Report Function
#
# EOF
