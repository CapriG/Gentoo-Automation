#!/usr/bin/perl -w
# Use -w or -d --^ for warnings/debug
#
# Capri.Gomez@Gmail.com
#
# vmdeploy.pl
# Version 1.5a
# Deployment Script for KVM

use Socket;
use v5.10;

### Config ###

# KVM Disk Path
$vmdsk = "/var/lib/libvirt/images/";

# Template Disk
$templatedsk = $vmdsk . "Windows7template.qcow2";

# VM Memory Size

# 3 Gigabyte
$VMMEM = "3145728";

# Spice Port Start
$spicep = "9000";

### /Config ###

# Deploy VM's according to config
sub routine {

	# Load configuration and execute deployments
	open(BKCONFIG, "<" . "/root/vms") || die("Could not open config file");
	@VM = <BKCONFIG>;
		
	foreach (@VM) {
		chomp($_);
	}
	
	# Execute job
	&live(@VM);
}

# Pass @ of VM's
# Deploy new VM instance
sub live {

	# Spice TCP Port
	$spiceportnum = $spicep;

	foreach(@VM) {
			
		$VM = $_;
		
		# Produce new XML File
		&xml($VM,$spiceportnum);

		# Output
		print $VM . ":" . $spiceportnum . "\n";
		
		# Increment Spice Port
		$spiceportnum = $spiceportnum + 1;

		# Define VM
		$definevm = "virsh define /tmp/$VM.xml";
		system($definevm);
		
		# Deploy new qcow2 image
		$qcow = "qemu-img create -f qcow2 -o backing_file=\"$templatedsk\" $vmdsk$VM.qcow2";
		system($qcow);
		
		# Delete XML
		$deldel = "rm -rf /tmp/$VM.xml";
		system($deldel);
	}
}

# XML Template for Standard VM
sub xml {
	open(XMLSS, ">" . "/tmp/$VM.xml");
	
	print XMLSS "<domain type='kvm'>
  <name>$VM</name>
  <memory unit='KiB'>$VMMEM</memory>
  <currentMemory unit='KiB'>$VMMEM</currentMemory>
  <vcpu placement='static'>2</vcpu>
  <os>
    <type arch='x86_64' machine='pc-1.2'>hvm</type>
    <boot dev='hd'/>
    <bootmenu enable='yes'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='localtime'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-kvm</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$vmdsk$VM.qcow2'/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </disk>
    <controller type='virtio-serial' index='0'>
      <alias name='virtio-serial0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </controller>
    <controller type='ide' index='0'>
      <alias name='ide0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-ehci1'>
      <alias name='usb0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x7'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <alias name='usb0'/>
      <master startport='0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0' multifunction='on'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <alias name='usb0'/>
      <master startport='2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <alias name='usb0'/>
      <master startport='4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x2'/>
    </controller>
    <interface type='bridge'>
      <source bridge='br0'/>
      <model type='virtio'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <serial type='pty'>
      <source path='/dev/pts/3'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/3'>
      <source path='/dev/pts/3'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='tablet' bus='usb'>
      <alias name='input0'/>
    </input>
    <input type='mouse' bus='ps2'/>
    <graphics type='spice' port='$spiceportnum' autoport='no' listen='0.0.0.0'>
      <listen type='address' address='0.0.0.0'/>
    </graphics>
    <sound model='ac97'>
      <alias name='sound0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </sound>
    <video>
      <model type='qxl' vram='65536' heads='1'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <redirdev bus='usb' type='spicevmc'>
      <alias name='redir0'/>
    </redirdev>
    <redirdev bus='usb' type='spicevmc'>
      <alias name='redir1'/>
    </redirdev>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </memballoon>
  </devices>
  <seclabel type='none'/>
</domain>";

	close(XMLSS);
}

# Execute Deployments
&routine();
# EOF
