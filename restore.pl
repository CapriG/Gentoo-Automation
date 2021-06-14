#!/usr/bin/perl -w
# Use -w or -d --^ for warnings/debug
#
# Capri.Gomez@Gmail.com
#
# restore.pl
# Version .01a
# Script for Restoring KVM Backups

$vmdsk = "/var/lib/libvirt/images/";

# Backup Path (No Slashes)
$backpath = "/mnt/backup";

$VM = "virtualMachineName";

# Prompt user to be absolutely sure they know what they're doing!
#print "Are you sure you want to restore $VM?\n\nAll data will be reverted as of the backup date!\n";
#print "Please solve to continue...\n 60+17=??";

#$response = <STDIN>;
#chomp($response);

#if($response != 77) { die("WRONG!"); }

# Identify VM Status and Shutoff if required

given(&status($VM) {
	when(/running/) {
		$action = "virsh shutdown $VM"
		system($action);
	}
	when(/paused/) {
		$action = "virsh shutdown $VM"
		system($action);
	}
	when(/crashed/) {
		$action = "virsh shutdown $VM"
		system($action);
	}
}


# Delete the VM
$delvirsh = "virsh del $VM";
system($delvirsh);
print "Moving File Instead $VM\n";

# Delete VM Disk
#$deldisk = "rm -rf $vmdsk$VM.qcow2";
$deldisk = "mv $vmdsk$VM.qcow2.bak";
system($deldisk);
print "\n";

# Copy VM Disk from Backup DIR
$copyvirsh = "rsync -avz $backpath/$VM.qcow2 $vmdsk";
system($copyvirsh);
print "\n";

# Restore VM from XML
$virshdefine = "virsh define ./$VM.xml";
system($virshdefine);
print "\n";

# Print Success or Failure

sub status {
	# Ask virsh for status
	$status = `virsh domstate $VM`;
	chomp($status);
	return $status;
}

# Print Help for lost wanderers...
sub help() {

print "
# restore.pl

################################################################################
#
# This script Restores its respective VM Backup.
#
# USE WITH CAUTION!
";
#
}
# EOF
