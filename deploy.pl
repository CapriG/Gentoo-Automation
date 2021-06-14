#!/usr/bin/perl -w
# Use -w or -d --^ for warnings/debug
# Capri Gomez
# Mystic Solutions
#
# Gentoo Linux Diskless Deployment Management Console
#
# Version 2.4

use Socket;
use v5.10;

### Config ###

# Subnet Network IP with CIDR Notation
$subnet = "192.168.1.0/24";

# NFS/TFTP Server IP
$NFSD = "192.168.1.215";

# DNS domain (root/suffix)
$DNS = "mysticalinc.com";

# Internal DNS
$INDNS = "192.168.1.1";

# LDAP Domain (Active Directory Domain) to be used for rdesktop
$domain = "";

# KVM Server IP
$KVM_IP = "192.168.1.113";

### End Config ###

### Advanced Config ###

# Root of the slave filesystems. (Include trailing "/")
$diskless = "/diskless/";

# Root of pxelinux.cfg folder. (Include trailing "/")
$pxeroot = $diskless . "pxelinux.cfg/";

# Main User
$mainusername = "user";

# Home folder to be used for operations. (Include trailing "/")
$homefolder = "/home/user/";

# rdesktop Base Arguments
$rdc = "rdesktop -k en-us -r clipboard:PRIMARYCLIPBOARD -r sound:local -fx lan";

# Enter DNS Servers here, in order;
# Google for normal stuff
# 4.2.2.2 Backup DNS
@NSE = ($INDNS);

# NFS Aux (# of Other daemons which should be started)
# Add one for every non-diskless related NFS share
# Leave set to 0 if only using diskless systems.
$NFSAUX = "0";

### End Advanced Config ###

# Convert IP into hexadecimal host.
sub ip2hex() {

	# Split IP into its Octets
	($oct1, $oct2, $oct3, $oct4) = split(/\./, $host, 4);
	# Array for work.
	@ipa = ($oct1, $oct2, $oct3, $oct4);

	$hexipa = "";
	# Format each array into hexadecimal and build hex IP.
	foreach(@ipa) {

		# IP Octet for Checking
		$pll = $_;
		# Check that IP matches valid range
		if (($pll >= 0) && ($pll < 255)) {
			# The IF is a check for a numeric as well as a valid value.
		} else { die "Check your Terminal IP...\n"; }
		
		# Calculate first column (x16)
		$part1 = $pll / 16;
		# Format to represent integer.
		$part1 = sprintf("%d", $part1);
		# Calculate second column (x1)
		$part2 = $pll % 16;
		# Array for work
		@columns = ($part1,$part2);
		
		# Assign Number or Letter to hex string
		foreach(@columns){
			
			given($_) {
				when (/10/) {
					#print "This number is an A:$_\n";
					$hexipa = $hexipa . "A";
				}
				when (/11/) {
					#print "This number is a B:$_\n";
					$hexipa = $hexipa . "B";
				}
				when (/12/) {
					#print "This number is a C:$_\n";
					$hexipa = $hexipa . "C";
				}
				when (/13/) {
					#print "This number is a D:$_\n";
					$hexipa = $hexipa . "D";
				}
				when (/14/) {
					#print "This number is an E:$_\n";
					$hexipa = $hexipa . "E";
				}
				when (/15/) {
					#print "This number is an F:$_\n";
					$hexipa = $hexipa . "F";
				}
				default {
					#print "This number is a digit:$_\n"
					$hexipa = $hexipa . $_;
				}
			}
		}
	}
	# Return translated IP
	return $hexipa;
}

# Gather names of all slaves...
sub get_hosts() {

	opendir(DIR, "$diskless") || die("Cannot open $diskless\n");
	# Read...
	my @folders = readdir(DIR);
	# Make undesired directories/files float to the top...
	my @excep = ("kernel","pxelinux.cfg","pxelinux.0",".","..","0.tar");
	# Initialize slave array
	my @slaves = "";
	# Omit irrelevant dir's and files...
	foreach $folder (@folders) {
		# Match against exceptions
		if ($folder ~~ @excep) { 
		# Do nothing on true...
		} else { if (! $folder ~~ @slaves) { push(@slaves, $folder) }; }
	}
	# We have our list of slaves
	# Get rid of fluff...
	shift(@slaves);
	return @slaves;
}

# Set hostname and DNS information in slave file system
sub set_host() {

	# Set host file in slave filesystem
	open(H, ">" . $diskless . $hosthex . "/etc/conf.d/hostname") || die("Can't open " . $diskless . $hosthex . "/etc/conf.d/hostname");
	# Set host to translation of IP into hexadecimal
	print H "HOSTNAME=\"$hosthex\"\n";
	close(H);
	#
	open(D, ">" . $diskless . $hosthex . "/etc/hosts") || die("Can't open " . $diskless . $hosthex . "/hosts");
	# Set host to translation of IP into hexadecimal
	print D "127.0.0.1 $hosthex $hosthex.$DNS localhost\n";
	close(D);
}

# Configure PXE Related Files
sub pxe() {
	# Write Kernel configuration to appropriate filename (host IP in hex)
	open(FILE, ">$pxeroot/$hosthex") || die("Cannot open " . $diskless . "pxelinux.cfg/$hosthex");
	
	# Edit to make use of kernel options
	print FILE "DEFAULT /kernel\n";
	print FILE "APPEND ip=dhcp raid=noautodetect root=/dev/nfs nfsroot=" . $NFSD . ":" . $diskless . $hosthex . " rw";
	close(FILE);
}

# Spice Desktop Icon Configuration
sub spicedesktop() {
	# Spice Viewer Arguments
	$spicec = "spicy -f --spice-usbredir-redirect-on-connect=\"0x03,-1,-1,-1,0|-1,-1,-1,-1,1\" --uri=spice://" . $KVM_IP . ":" . $VMPORT; 

	# Open Alternate File for Copy of Spice Config
	open(spice2, ">" . "/root/desktops/$hosthex");
	# Set spice file in slave autostart
	open(spice1, ">" . $diskless . $hosthex . $homefolder . ".config/autostart/Windows.desktop") || warn("Can't open" . $diskless . $hosthex . $homefolder . ".config/autostart/Windows.desktop");
	# Configuration Template
	print spice1 "[Desktop Entry]
Type=Application
Exec=$spicec
Hidden=false
X-GNOME-Autostart-enabled=true
Name[C]=Windows
Name=Windows
Comment[C]=Virtual Machine
Comment=Virtual Machine
Icon=$homefolder" . "windows.png";
	print spice2 "[Desktop Entry]
Type=Application
Exec=$spicec
Hidden=false
X-GNOME-Autostart-enabled=true
Name[C]=Windows
Name=Windows
Comment[C]=Virtual Machine
Comment=Virtual Machine
Icon=$homefolder" . "windows.png";
	close(spice1);
	close(spice2);
	# Write the Windows icon
	$ch = "chmod 777 " . $diskless . $hosthex . $homefolder . ".config/autostart/Windows.desktop";
	system($ch);
	$chl = "ln -sfn " . $homefolder . ".config/autostart/Windows.desktop " .  $diskless . $hosthex . $homefolder . "Desktop/Windows.desktop";
	system($chl);
	
	# Write file with IP as filename on Desktop for end users
	#$ipxx = "touch " . $diskless . $hosthex . $homefolder . "Desktop/$host";
	#system($ipxx);
	#$chh = "chmod 777 " . $diskless . $hosthex . $homefolder . "Desktop/$host";
	#system($chh);
	# Create term.conf for use with listing function.
	open(LONF, ">" . $diskless . $hosthex . $homefolder . "term.conf") || die("Can't open $homefolder/term.conf");
	# Set host to translation of IP into hexadecimal
	print LONF "$KVM_IP\n$VMPORT\n$host";
	close(LONF);
}

# Add/Replace entry for rdesktop session in ~/.config/autostart/rdesktop.desktop
# Starts under gdm...
# Create a duplicate of that entry in ~/Desktop.
sub rdesktop() {
	
	my $rdcc = $rdc;
	# Domain
	if (! $domain eq "") { $rdcc = $rdcc . " -d $domain"; }
	# Wrap up with pedigree information
	$rdcc = $rdcc . " -u " . $username . " " . $windowshost;

	# Create check for directory and call it here!
	my $dir = $diskless . $hosthex . $homefolder . ".config/autostart/";
	&dircheck($dir);
	# Set rdesktop file in slave autostart
	open(rdp1, ">" . $diskless . $hosthex . $homefolder . ".config/autostart/Windows.desktop") || warn("Can't open" . $diskless . $hosthex . $homefolder . ".config/autostart/Windows.desktop");
	# Configuration Template
	print rdp1 "[Desktop Entry]
Type=Application
Exec=$rdcc
Hidden=false
X-GNOME-Autostart-enabled=true
Name[C]=Windows
Name=Windows
Comment[C]=Virtual Machine
Comment=Virtual Machine
Icon=$homefolder" . "windows.png";
	close(rdp1);
	# Write the Windows icon
	$ch = "chmod 777 " . $diskless . $hosthex. $homefolder . ".config/autostart/Windows.desktop";
	system($ch);
	$chl = "ln -sfn " . $homefolder . ".config/autostart/Windows.desktop " .  $diskless . $hosthex . $homefolder . "Desktop/Windows.desktop";
	system($chl);
	
	# Write file with IP as filename on Desktop for end users
	$ipxx = "touch " . $diskless . $hosthex . $homefolder . "Desktop/$host";
	system($ipxx);
	$chh = "chmod 777 " . $diskless . $hosthex . $homefolder . "Desktop/$host";
	system($chh);
	# Create dummy.conf for use with listing function.
	open(CONF, ">" . $diskless . $hosthex . $homefolder . "dummy.conf") || die("Can't open $homefolder/dummy.conf");
	# Set host to translation of IP into hexadecimal
	print CONF "$windowshost\n$username\n$host";
	close(CONF);
}

# Edit Slave fstab and export the directory in NFS
sub fs() {
	open(FS, ">$diskless$hosthex/etc/fstab") || die("Cannot open slave fstab");

	# Write slave fstab
	# Use real IP to avoid DNS delay...
	print FS "$NFSD:/diskless/$hosthex		/		nfsvers=3,async,rw,nolock		0 0\n";
	print FS "$NFSD:/usr		/usr		nfs		nfsvers=3,async,ro,nolock		0 0\n";
	print FS "none		/proc		proc		defaults		0 0\n";
	close(FS);

	# Check for our line
	open(NFZ, "</etc/exports") || die("Cannot open /etc/exports");
	@d = "";
	@d = <NFZ>;
	close(NFZ);
	$write = 1;
	# Regex for matching line in /etc/exports
	$nf = $diskless . $hosthex . " " . $host . "*";
	foreach (@d) {
		# If we have a match...
		if ($_ =~ $nf) {
			# Don't Write slave export to /etc/exports
			$write = 0;
		}
	}
	# Write line unless its already there...
	unless ($write eq 0) {
		open(QEX, ">>/etc/exports") || die("Cannot open /etc/exports");
		print QEX "/diskless/$hosthex $host(async,rw,no_root_squash,no_all_squash,no_subtree_check)\n";
		close(QEX);
	}

	# Make sure /usr export is correct

	# Open exports to scan for /usr line...
	open(NFZQE, "</etc/exports") || die("Cannot open /etc/exports");
	@qww = "";
	@qww = <NFZQE>;
	close(NFZQE);
	
	# Control variable for matching /usr line.
	$match = 0;
		# Loop through /etc/exports...
		$break = 0;
		while ($break == 0 ) {
			foreach (@qww) {
				# If we have a /usr line, don't write one.
				if ($_ =~ "/usr*") {
					# Don't Write slave export to /etc/exports.
					$match = 1;
					# Correct entry if necessary
					if ($_ !~ $subnet) {
						# Open exports for comparison
						open(SDS, "</etc/exports") || die("Cannot open /etc/exports");
						@linescfg = <SDS>;
						# If /usr subnet is wrong, replace the line.
						foreach(@linescfg) { if($_ =~ "usr" && $_ !~ $subnet) { $_ = "/usr	$subnet(async,ro,no_root_squash,no_all_squash,no_subtree_check)\n"; } }
						close(SDS);
						# Write the new file
						open(CC, ">/etc/exports") || die("Cannot open /etc/exports");
						print CC @linescfg;
						close(CC);
					}
				# Stop the loop if no lines match.
				} else { $break = 1; }
			}
		}
	# Append a fresh /usr line if we never had a match...
	if ($match == 0) {
		open(QEXQ, ">>/etc/exports") || die("Cannot open /etc/exports");
		print QEXQ "/usr	$subnet(async,ro,no_root_squash,no_all_squash,no_subtree_check)\n";
		close(QEXQ);
	}

	# Increment NFSDCOUNT in /etc
	
	# Get number of nodes
	$hostcount = 0;
	$hostcount = get_hosts();

	# Add number of shares besides those used for nodes
	$hostcount += $NFSAUX;
	
	# Debug for number of items in /diskless folder (@slaves)
	#print "We have $hostcount hosts.\n";
	
	# Read...
	open(NF, "</etc/conf.d/nfs") || die("Cannot open /etc/conf.d/nfs");
	@lines = <NF>;
	# Match the option for daemon counts, replace with suitable entry
	foreach(@lines) { if($_ =~ "OPTS_RPC_NFSD=\"*\"") { $_ = "OPTS_RPC_NFSD=\"$hostcount\"\n"; } }
	close(NF);
	# Write the new file
	open(W, ">/etc/conf.d/nfs") || die("Cannot open /etc/conf.d/nfs");
	print W @lines;
	close(W);
}
#
# Clean up
sub mrclean() {
	# Delete terminal
	$f = "rm -rf $diskless$hosthex";
	system($f);
	# Delete pxelinux.cfg/CONFIG as $hosthex
	$s = "rm -rf " . $diskless . "pxelinux.cfg/" . $hosthex;
	system($s);

	# Delete NFSD entry
	# Read...
	open(NFX, "</etc/exports") || die("Cannot open /etc/exports");
	@nt = "";
	@nt = <NFX>;
	close(NFX);
	# Regex for matching line in /etc/exports
	$nfsline = $diskless . $hosthex . " " . $host . "*";
	foreach(@nt) {
		if ( $_ =~ $nfsline ) {
			$_ = "";
		}
	}
	# Write the new file
	open(NFX, ">/etc/exports") || die("Cannot open /etc/exports");
	print NFX @nt;
	close(NFX);
	@nt = "";

	# Decrement NFSDCOUNT in /etc
	$hostcount = get_hosts();
	# Add number of shares besides those used for nodes
	$hostcount = $hostcount + $NFSAUX;
	# Read...
	open(NFA, "</etc/conf.d/nfs") || die("Cannot open /etc/conf.d/nfs");
	@lines = <NFA>;
	# Match the option for daemon counts, replace with suitable entry
	foreach(@lines) { if($_ =~ "OPTS_RPC_NFSD=\"*\"") { $_ = "OPTS_RPC_NFSD=\"$hostcount\"\n"; } }
	close(NFA);
	# Write the new file
	open(NFC, ">/etc/conf.d/nfs") || die("Cannot open /etc/conf.d/nfs");
	print NFC @lines;
	close(NFC);
}

# Show users Terminal Configuration
sub list(){
	# List Terminals with usernames and IP information.
	@slaves = get_hosts();
	print "[Terminal IP][Terminal][VM IP/Host][Username]\n";
	foreach (@slaves) {
		# Open Configuration file in ~/dummy.conf
		open(NFC, "<" . $diskless . $_ . $homefolder . "dummy.conf") || die("Cannot open $homefolder/dummy.conf");
		@lines = <NFC>;
		chomp(@lines);
		print "[" . $lines[2] . "][" . $_ . "]" . "[" . $lines[0] . "]" . "[" . $lines[1] . "]\n";
		close(NFC);
	}
}

# Show users Spice Terminal Configuration
sub spicelist(){
	# List Terminals with usernames and IP information.
	@slaves = get_hosts();
	print "[Terminal IP][Terminal][Spice Port]\n";
	foreach (@slaves) {
		# Open Configuration file in ~/term.conf
		open(NFC, "<" . $diskless . $_ . $homefolder . "term.conf") || die("Cannot open $homefolder/term.conf");
		@lines = <NFC>;
		chomp(@lines);
		print "[" . $lines[2] . "][" . $_ . "]" . "[" . $lines[1] . "]\n";
		close(NFC);
	}
}

# Import Terminal Configuration
sub importconf(){

	# Directory passed from input
	$importdir = "/root/";
	# Filename passed from input
	$filename = "config.dks";
		
	open(IMPS, "<" . $importdir . $filename);
	# Array for Terminal info
	@DATA = <IMPS>;
	foreach (@DATA) {
		# Populate variables for deployment
		($host, $windowshost, $username) = split(/\,/, $_, 3);
		# Remove newline from config.dks
		chop $username;
		# Recursive call for deployment of Terminal.
		&addterm2($host,$windowshost,$username);
	}
	# Restart NFS Daemon
	system("/etc/init.d/nfs restart");
}

# Export Terminal Configuration
sub exportconf(){

	# Directory passed from input
	$exportdir = "/root/";
	# Filename passed from input
	$filename = "config.dks";
	# List Terminals with usernames and IP information.
	@slaves = get_hosts();
	foreach (@slaves) {
		# Open slave config to read values...
		open(NFC, "<" . $diskless . $_ . $homefolder . "dummy.conf") || die("Cannot open $homefolder/dummy.conf");
		@lines = <NFC>;
		close(NFC);
		chomp(@lines);
		# Create comma delimited line for each terminal
		$configline = $lines[2] . "," . $lines[0] ."," . $lines[1] . "\n";
		# Build Array for writing file.
		push (@configfile, $configline);
	}
	# Write Configuration file. 
	open (EXPP, ">" . $exportdir . $filename);
	print EXPP @configfile;
	close (EXPP);
}

# Import Spice Terminal Configuration
sub spiceimportconf(){

	# Directory passed from input
	$importdir = "/root/";
	# Filename passed from input
	$filename = "spiceconfig.dks";
		
	open(IMPS, "<" . $importdir . $filename);
	# Array for Terminal info
	@DATA = <IMPS>;
	foreach (@DATA) {
		# Populate variables for deployment
		($KVM, $VMPORT, $host) = split(/\,/, $_, 3);
		# Remove newline from config.dks
		chop $host;
		# Recursive call for deployment of Terminal.
		$KVM = "";
		&addspice($host,$VMPORT);
	}
	# Restart NFS Daemon
	system("/etc/init.d/nfs restart");
}

# Export Spice Terminal Configuration
sub spiceexportconf(){

	# Directory passed from input
	$exportdir = "/root/";
	# Filename passed from input
	$filename = "spiceconfig.dks";
	# List Terminals with usernames and IP information.
	@slaves = get_hosts();
	foreach (@slaves) {
		# Open slave config to read values...
		open(NFC, "<" . $diskless . $_ . $homefolder . "term.conf") || die("Cannot open $homefolder/term.conf");
		@lines = <NFC>;
		close(NFC);
		chomp(@lines);
		# Create comma delimited line for each terminal
		$configline = $lines[0] . "," . $lines[1] . "," . $lines[2] . "\n";
		# Build Array for writing file.
		push (@configfile, $configline);
	}
	# Write Configuration file. 
	open (EXPP, ">" . $exportdir . $filename);
	print EXPP @configfile;
	close (EXPP);
}

# Provision a host (or more...)
sub addterm() {
	# Wipe out current config to rid corrupt files...
	if(-d "$diskless$hosthex") { 
		system("rm -rf $diskless$hosthex"); 
	}
	# Create root dir
	$arg = "mkdir $diskless$hosthex";
	system($arg);

	# Untar slave root filesystem
	system("tar -xf $diskless" .  "0.tar -C $diskless$hosthex");
	# Commit host specific values to configuration
	&set_host($hosthex);
	&fs($host,$hosthex);
	&pxe($hosthex);
	# Set DNS in slave
	open(XC, ">" . $diskless . $hosthex . "/etc/resolv.conf") || die ("Cannot open $diskless$hosthex/etc/resolv.conf");
	foreach (@NSE) { print XC "nameserver $_\n"; }
	close(XC);
}

sub updateterm() {
	open(CONF, ">" . $diskless . $hosthex . $homefolder . "dummy.conf") || die("Can't open $homefolder/dummy.conf");
	# Set host to translation of IP into hexadecimal
	print CONF "$windowshost\n$username\n$host";
	close(CONF);
	# Install unique login credentials for RDP
	&rdesktop($hosthex,$windowshost,$username);
}

sub addterm2() {
	# Convert IP to hex
	$hosthex = &ip2hex($host);
	# Add Terminal
	&addterm($hosthex);
	# Configure rdesktop entry
	&rdesktop($hosthex,$windowshost,$username);
	# Success!
	print "\n$hosthex was deployed successfully.\n";
}

sub addspice() {
	# Convert IP to hex
	$hosthex = &ip2hex($host);
	# Add Terminal
	&addterm($hosthex);
	# Configure desktop entry
	&spicedesktop($VMPORT);
	# Success!
	print "\n$hosthex was deployed successfully.\n";
}

# Check for a directories existence and for valid permissions.
sub dircheck() {
	# If it doesn't exist...
	if (!-d $dir) {
		# Create dir
		system("mkdir $dir");
		# chown for correct user
		system("chown $mainusername $dir");
		# chmod for correct permissions
		system("chmod -R 770 $dir");
	} #else { print "It exists\n"; }
}

# Tell subroutines what to do based on user input...
sub pinp() {
	# Input...
	given($ARGV[0]) {
		# Add Terminal
		when ("-a") {
			# Check for our required args; Print help if not valid;
			if ($ARGV[1] eq "" ) { help(); die("\nError: Enter a valid IP...\n"); }
			if ($ARGV[2] eq "" ) { help(); die("\nError: Enter a valid windows host...\n"); }
			if ($ARGV[3] eq "" ) { help(); die("\nError: Enter a valid user...\n"); }
			# Set Variables for use
			$host = $ARGV[1];
			$windowshost = $ARGV[2];
 			$username = $ARGV[3];
			# Add Terminal
			&addterm2($host,$windowshost,$username);
			# Restart NFS Daemon
			system("/etc/init.d/nfs restart");
		}
		# Add Spice Terminal
		when ("-s") {
			# Check for our required args; Print help if not valid;
			if ($ARGV[1] eq "" ) { help(); die("\nError: Enter a valid IP...\n"); }
			if ($ARGV[2] eq "" ) { help(); die("\nError: Enter a valid Spice port...\n"); }
			# Set Variables for use
			$host = $ARGV[1];
			$VMPORT = $ARGV[2];
			# Add Terminal
			&addspice($host,$VMPORT);
			# Restart NFS Daemon
			system("/etc/init.d/nfs restart");
		}
		# Delete Terminal
		when ("-d") {
			if ($ARGV[1] eq "" ) { help(); die("\nError: Enter a Terminal Hostname to be Deleted...\n"); }
			if ($ARGV[2] eq "" ) { help(); die("\nError: Enter a valid IP...\n"); }
			$hosthex = $ARGV[1];
			$host = $ARGV[2];
			unless((length($hosthex)) == 8) { die("\nError: Check your hostname...\n"); }
			unless((length($host)) >= 7) { die("\nError: Check your IP...\n"); }
			# Die unless values match...
			if ($hosthex eq &ip2hex($host)) { &mrclean($hosthex,$host); } else { die("Error: Your hostname and IP don't match.\n") }
		}
		when ("-l") {
			# Print Terminal Configuration to console
			&list();
		}
		when ("-ls") {
			# Print Spice Terminal Configuration to console
			&spicelist();
		}
		when ("-e") {
			# Export Terminal Configuration
			&exportconf();
		}
		when ("-i") {
			# Import Terminal Configuration
			&importconf();
		}
		when ("-se") {
			# Export Spice Terminal Configuration
			&spiceexportconf();
		}
		when ("-si") {
			# Import Spice Terminal Configuration
			&spiceimportconf();
		}
		# Update Terminal
		when ("-u") {
			print "Terminal Updated.\n";
			if ($ARGV[1] eq "" ) { help(); die("\nError: Enter a valid IP...\n"); }
			if ($ARGV[2] eq "" ) { help(); die("\nError: Enter a valid windows host...\n"); }
			if ($ARGV[3] eq "" ) { help(); die("\nError: Enter a valid user...\n"); }
			# Set Variables for use
			$host = $ARGV[1];
			$windowshost = $ARGV[2];
			$username = $ARGV[3];	
			
			# Convert and set IP/hostname
			$hosthex = &ip2hex($host);
			&updateterm($hosthex,$windowshost,$username,$host);
		}
		default {
			help();
		}
	}
}
#
## ./deploy.pl START!

# Process input...
&pinp();

# Print Help for lost wanderers...
sub help() {

# deploy.pl
# Configuration script for diskless Terminals
#
# Usage :
# 
# Add a Terminal:
#
# ./deploy.pl -a TerminalIP VM[:port] Username
#
# List Terminals
#
# ./deploy.pl -l
# ** Use \"./deploy.pl -l | more\" or \"./deploy.pl -l | grep\"
# for long lists **
#
# Update Terminal for a new user:
#
# ./deploy.pl TerminalIP VM[:port] Username\n#
# Delete a Terminal:
#
# ./deploy.pl -d TerminalHostname TerminalIP
#
# ** Both Hostname and IP are required for deletions for safety reasons. **
#
# Export Terminal Configuration:
#
# ./deploy.pl -e
#
# Import Terminal Configuration:
#
# ./deploy.pl -i
# 
# * Configuration is stored in /root/*
#
################################################################################
";
#
}
#
# Note : This script assumes use of the Gentoo Diskless tutorial and 
# may be tailered to automate your specific needs.
#
# This script currently imposes a scheme where hostnames equal their respective IP's in hexadecimal
# This behavior is derived from pxelinux.0
# IP Addresses are used strictly in actual NFS networking to avoid DNS errors/delays
#
# This script also assumes Terminal IP Addresses are reserved by MAC Address.
#
# This script automatically writes the /usr line of NFS Server Configuration if incorrect according to $subnet in configuration area just before deploying machines
# This feature is a failsafe against last minute changes.
#
# NFS Daemon counts are also configured/incremented automatically. (Per Terminal)
#
## TO-DO
# Create GUI?
# Fix Permissions on Desktop Icons to be absolutely read only.
# EOF

}
# EOF
