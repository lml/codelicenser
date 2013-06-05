#!/usr/bin/perl -w
BEGIN
{
	$WORKING_DIR = `pwd -P`;
	chomp $WORKING_DIR;
	$WORKING_DIR =~ s!/+$!!g;
	$WORKING_DIR .= "/";

	$SCRIPT_DIR = $WORKING_DIR;
	if ($0 =~ m!^\.!) {
		$SCRIPT_DIR = $WORKING_DIR . $0;
	}
	elsif ($0 =~ m!^/!) {
		$SCRIPT_DIR = $0;
	}

	$SCRIPT_DIR =~ m!(^.*/)!;
	$SCRIPT_DIR = $1;

	$SCRIPT_NAME = $0;
	if ($0 =~ m!^(.*/)(.+)$!) {
		$SCRIPT_NAME = $2;
	}
	
	push(@INC, $SCRIPT_DIR);
}

use Module::Load;

my $setup = initAndControl(@ARGV);

readConfigFile($setup);
loopFiles($setup);

sub initAndControl
{
	my @args = @_;
	
	my $setup = {};
	$setup->{configFilename} = $SCRIPT_DIR . "config.license_tool";
	$setup->{fileRootDir} = $SCRIPT_DIR ;
	$setup->{insertLicense} = 1;
	$setup->{message} = "";
	$setup->{viewing} = 0;

	my $i = 0;
	my $curArg = $args[$i];
	while (defined($curArg)) {
		if ($curArg eq "-r" | $curArg eq "-remove") {
			# Set such that existing License Agreement is only removed, nothing new added
			$setup->{insertLicense} = 0;
		}
		elsif ($curArg eq "-h" | $curArg eq "-help") {
			# Displays License Tool's usage instructions
			printUsage();
		}
		elsif ($curArg eq "-n" | $curArg eq "-new") {
			# Generate new config file
			makeNewConfig();
		}
		elsif ($curArg eq "-v" | $curArg eq "-view") {
			# Set such that file information is displayed
			$setup->{viewing} = 1;
		}
		elsif ($curArg eq "-m" | $curArg eq "-message") {
			# Append custom message after license tool
			my $next = $args[$i + 1];
			my $found = 0;

			print STDOUT ("---------the next arg is $next\n\n");

			# Message provided
			if (defined($next)) {
				if ($next !~ m/^-/) {
					print STDOUT ("here\n");
					$found = 1;
					$i++;
					$setup->{message} = $next;
					chomp($setup->{message});
				}
			}

			# Message not provided
			if (!$found) {
				print STDOUT ("here2\n");
				print STDOUT ("\nEnter message to append after License Agreement\n(note this is a one line message):\n");
				$setup->{message} = <STDIN>;
				<STDIN>;
				chomp($setup->{message});
			}
		}
		else {
			printUsage();

			print STDOUT ("\n------------\nNOTE: unknown argument ($curArg)\n");
		}
		$i++;
		$curArg = $args[$i];
	}
	
	return $setup;
}

sub readConfigFile
{
	my ($setup) = @_;

	die("\n------------\nERROR: could not open config file ($setup->{configFilename}) [$!]\n\n")
		if !open(IN, $setup->{configFilename});
	my @configLines = <IN>;
	close(IN);

	$setup->{licenseLines} = [];
	$setup->{regexParamPairs} = {};
	$setup->{omissionPairs} = [];
	$_ = $setup->{configFilename};
	s/\/.*\///g;
	push (@{$setup->{omissionPairs}}, $_ . "\$");
	push (@{$setup->{omissionPairs}}, __FILE__ . "\$");

	# Make things look pretty
	print STDOUT ("\n")
		if ($setup->{viewing});

	foreach (@configLines) {
		my $curConfigLine = $_;

		# Skip comment lines
		next
			if ($curConfigLine =~ m/^#/);

		# Remove any in-line comments
		$curConfigLine =~ s/#(?=(?:(?:[^']*'){2})*[^']*$).*//;
		
		# Remove extranious space before or after
		$curConfigLine =~ s/^\s+|\s+$//g;

		# Skip blank lines
		next
			if $curConfigLine eq "";

		# Test if part of License Agreement
		if ($curConfigLine =~ m/^@/) {
			$curConfigLine =~ s/@\s+|@//;

			# Skip blank lines
			next
				if $curConfigLine eq "";
			
			push (@{$setup->{licenseLines}}, $curConfigLine);
			
			print STDOUT ("Added to License Agreement\n")
				if ($setup->{viewing});
			
			next;
		}

		# Test if regex-param pair (included file formats)
		if ($curConfigLine =~ m/^(.*)\s*pass(.*'.*'.*,.*'.*'.*,.*'.*'.*,.*'.*'.*,.*,.*,.*)$/) {
			my $cur1 = $1;
			my $cur2 = $2;

			$cur1 =~ s/^\s+|\s+$//g;
			$cur2 =~ s/^\s+|\s+$//g;

			die ("\n------------\nERROR: file type has more than one param assignment, $curConfigLine\n\n")
				if (exists $setup->{regexParamPairs}->{$cur1});

			$setup->{regexParamPairs}->{$cur1} = $cur2;

			print STDOUT ("Added to Regex-Param Pairs (file type included)\n")
				if ($setup->{viewing});

			next;
		}

		# Test if regex-param pair (omitted file formats)
		if ($curConfigLine =~ m/^(.*)\s*(Noop)$/) {
			my $cur = $1;

			$cur =~ s/^\s+|\s+$//g;

			push (@{$setup->{omissionPairs}}, $cur);

			print STDOUT ("Added to Regex-Param Pairs (file type omitted)\n")
				if ($setup->{viewing});

			next;
		}

		die ("\n------------\nERROR: invalid code in $setup->{configFilename} ($curConfigLine)\n\n")
	}

	# Check that there is a License Agreement
	die ("\n------------\nERROR: no license agreement found\n\n")
		if (scalar @{$setup->{licenseLines}} eq 0);

	# Check that there are regex-param pairs
	die ("\n------------\nERROR: no regex-param pairs found\n\n")
		if (keys(%{$setup->{regexParamPairs}}) eq 0);

	# Confirm if there are any omitted file types
	print STDOUT ("\n------------\nNOTE: no omitted file types found\n\n")
		if (scalar @{$setup->{omissionPairs}} eq 0);
}

sub loopFiles {
	my ($setup) = @_;

	# Get list of all files in this directory
	my $cmd = "find $setup->{fileRootDir} -type f";
	my @filenamesToProcess = `$cmd`;

	# Make things look pretty
	print STDOUT ("\n")
		if ($setup->{viewing});

	# Loop through and append 
	foreach (@filenamesToProcess) {
		my $curFilename = $_;
		# Clean up file name
		$curFilename =~ s/^\s+|\s+$//g;

		print STDOUT ("Current File: $curFilename\n")
			if ($setup->{viewing});

		# Test if this file name is something
		next
			if $curFilename eq "";

		# Test if this file name is to be omitted
		my $omit = 0;
		foreach (@{$setup->{omissionPairs}}) {
			if ($curFilename =~ m/$_/) {
				print STDOUT ("Omitted file type\n\n")
					if ($setup->{viewing});

				$omit = 1;
				last;
			}
		}

		# Test which regex expression matches
		if (!$omit) {
			# Assume ignored until proven otherwise
			my $ignored = 1;
			foreach (keys %{$setup->{regexParamPairs}}) {
				if ($curFilename =~ m/$_/) {
					# Proven file not ignored
					$ignored = 0;
					# License file
					licenseFile($curFilename, $_, $setup->{regexParamPairs}->{$_}, @{$setup->{licenseLines}});
					last;
				}
			}
			print STDOUT ("File type not addressed, ignored\n\n")
				if ($setup->{viewing} & $ignored);
		}
	}
}

sub licenseFile {
	my ($fileName, $regex, $param, @license) = @_;

	# Parse parameters
	$param =~ m/\(.*'(.*)'.*,.*'(.*)'.*,.*'(.*)'.*,.*'(.*)'.*,(.*),(.*),(.*)$/;
	my $inline = $1;
	my $blockS = $2;
	my $blockI = $3;
	my $blockE = $4;
	my $skip   = $5;
	my $before = $6;
	my $after  = $7;

	# Clean up numbers
	$skip   =~ s/\D//g;
	$before =~ s/\D//g;
	$after  =~ s/\D//g;

	if ($after < 2) {
		$after = 2;
	}

	die("\n------------\nERROR: could not open file ($fileName) [$!]\n\n")
		if !open(IN, $fileName);
	my @fileLines = <IN>;
	close(IN);

	$length = scalar @fileLines;
	
	# Find where the old License Agreement is
	my $i = 1;
	my $j = 1;

	$length = scalar @fileLines;

	foreach (0...$length-1) {

		$temp = $fileLines[$_];

		# Keep stepping util we find the License Agreement
		if ($temp !~ m/Copyright/) {
			$i++;
		}
		# We have found the first line of the License Agreement
		elsif ($temp =~ m/Copyright/) {

			$j = $i;

			# Step backwards until we find first blank line and/or the beginning of the file
			$i--;
			while (($i > $skip) && ($fileLines[$i] =~ m/\s/)) {
				$i--;
			}

			# Step through rest of License Agreement
			while (($fileLines[$j] !~ m/^\s*$/) & ($j < $length-1)) {
				$j++;
			}

			# Find any trailing white space
			while (($fileLines[$j] =~ m/^\s*$/) & ($j < $length-1)) {
				$j++;
			}

			last;
		}
	}

	if ($i == ($#fileLines + 2) && $j == 1) {
		# No License Agreement included
		print STDOUT ("No License Agreement included\n")
			if ($setup->{viewing});
	}
	else {
		# Cut out License Agreement
		splice (@fileLines, $i, $j-$i);
		print STDOUT ("Removed existing License Agreement\n")
			if ($setup->{viewing});
	}

	@newFile = "";
	if ($setup->{insertLicense}) {
		# Remove "Skip"
		push (@newFile, splice (@fileLines, 0, $skip));

		# Add "Before"
		for (my $m = 0; $m < $before; $m++) {
			push (@newFile, "\n");
		}

		# Add License Agreement
		push (@newFile, $blockS . $inline . $license[0] . "\n");
		print STDOUT ("$blockS . $inline . $license[0] . \n")
			if ($setup->{viewing});
		for (my $m = 1; $m <= $#license; $m++) {
			push (@newFile, $blockI . $inline . $license[$m] . "\n");
			print STDOUT ("$blockI . $inline . $license[$m] . \n")
				if ($setup->{viewing});
		}

		# Add message if it exists
		if ($setup->{message} !~ m/^\s*$/) {
			push (@newFile, $blockI . $inline . $setup->{message} . "\n");
			print STDOUT ("$blockI . $inline . $setup->{message} . \n")
				if ($setup->{viewing});
		}

		# Add "After"
		push (@newFile, $blockE . "\n");
		print STDOUT ("$blockE . \n")
			if ($setup->{viewing});
		for (my $m = 1; $m <= $after; $m++) {
			push (@newFile, "\n");
		}
	}

	# Add remaining document
	push (@newFile, @fileLines);

	# Write to file
	open(OUT, ">$fileName");
	print OUT (@newFile);
	close(OUT);
	print STDOUT ("Written to file\n\n")
		if ($setup->{viewing});

}

sub makeNewConfig {
	open(NEW, ">config.license_tool");
	print NEW (
"###############################################################################
# HOW TO USE THIS CONFIG.LICENSE_TOOL
###############################################################################
# This config.license_tool has two features. It first includes the License
# Agreement followed by a table of perl regular expression and a parameter,
# these are called Regex-Param pairs.
# 
# Text after the '#' symbol is considered to be a comment and is ignored.
# 
# Blank lines are ignored.
# 
# Text after the '\@' symbol is considered to be the License Agreement.
# 
# All other lines are considered to be Regex-Param pairs.
# 
# Whitespace before or after any line and the whitespace included in the
# Regex-Param pairs is ignored.
# 
# For each filename processed, this config.license_tool is scanned. The first
# Regex matching the current filename will cause the paired parameter to be
# passed into the Licenser appending the License Agreement to current filename.
# 
# Appropriate commenting and 'pretty' formatting is done to each filename
# processed.
# 
###############################################################################

###############################################################################
# LICENSE
###############################################################################
# For this code to function properly the License Agreement must start with 
# 'Copyright' and there cannot be any blank lines within the License Agreement.
###############################################################################

\@Copyright 2013 Giggles and Co.
\@Cool coders have worked on this.

###############################################################################
# PATTERNS
###############################################################################
# 
# Making new patterns/parameters:
# 
# pass(Inline, BlockS, BlockI, BlockE, Skip, Before, After)
# 
# Inline is appended to every line of License Agreement
# BlockS is appended to the first line of License Agreement
# BlockI is appended to all lines that are not first of License Agreement
# BlockE is appended after last line of License Agreement
# Skip is number of lines to skip before any insertion
# Before is number of lines to insert immediately before License Agreement
# After is number of lines to insert immediately after License Agreement
# 
###############################################################################
# 
# Sample parameters for filetypes:
#
# Coffee      use inline '# '								pass('# ', '', '', '', 0, 0, 2)
# Css         use block '/* ... */' with intermediate ' * '	pass('', '/* ', ' * ', ' */', 0, 0, 2)
# Erb         use block '<%# ... %>'						pass('', '<%# ', '', '%>', 0, 0, 2)
# JavsScript  use inline '// '								pass('// ', '', '', '', 0, 0, 2)
# Latex       use inline '% '								pass('% ', '', '', '', 0, 0, 2)
# Noop        do not apply license							Noop
# PerlModule  use inline '# '								pass('# ', '', '', '', 0, 0, 2)
# Rake        use inline '# '								pass('# ', '', '', '', 0, 0, 2)
# Ruby        use inline '# '								pass('# ', '', '', '', 0, 0, 2)
# Script      use inline '# ' after skipping first line 	pass('# ', '', '', '', 1, 2, 2)
# Scss        use inline '// '								pass('// ', '', '', '', 0, 0, 2)
# Text        use inline '# '								pass('# ', '', '', '', 0, 0, 2)
# Yaml        use inline '# '								pass('# ', '', '', '', 0, 0, 2)
#
###############################################################################

###############################################################################
# OMITTED FILE EXTENSIONS
# (file types not dealt with in this file are also omitted)
###############################################################################
# 
# config.license_tool (this file) omitted by default
# the perl code (default: licenseUpdateTool.pl) omitted by default
# 
###############################################################################

\\.bmp\$\t\t\t\t\tNoop
\\.gif\$\t\t\t\t\tNoop
\\.jpg\$\t\t\t\t\tNoop
\\.png\$\t\t\t\t\tNoop

###############################################################################
# INCLUDED FILE EXTENSIONS
###############################################################################

# Coffee
\\.coffee\$\t\t\t\tpass('# ', '', '', '', 0, 0, 2)

# Css
\\.css\$\t\t\t\t\tpass('', '/* ', ' * ', ' */', 0, 0, 2)

# Erb
\\.erb\$\t\t\t\t\tpass('', '<%#', '   ', '   %>', 0, 0, 2)

# JavaScript
\\.js\$\t\t\t\t\tpass('// ', '', '', '', 0, 0, 2)

# Latex
\\.tex\$\t\t\t\t\tpass('% ', '', '', '', 0, 0, 2)

# PerlModule
\\.pm\$\t\t\t\t\tpass('# ', '', '', '', 0, 0, 2)

# Rake
\\.rake\$\t\t\t\t\tpass('# ', '', '', '', 0, 0, 2)

# Ruby
\\.rb\$\t\t\t\t\tpass('# ', '', '', '', 0, 0, 2)

# Script
\\.pl\$\t\t\t\t\tpass('# ', '', '', '', 1, 2, 2)

# Scss
\\.scss\$\t\t\t\t\tpass('// ', '', '', '', 0, 0, 2)

# Text
\\.txt\$\t\t\t\t\tpass('# ', '', '', '', 0, 0, 2)

# Yaml
\\.yml\$\t\t\t\t\tpass('# ', '', '', '', 0, 0, 2)");
	close(NEW);
	exit(1);
}

sub printUsage {	
	print STDOUT (
"\n\nThis script adds or removes license text from files in the codebase
containing the script, the code must be loaded on the top directory.

    RECOMMENDED USAGE:
    	perl licenseUpdateTool.pl [-r] [-h] [-n] [-m] [\"Text\"] [-v]

    USAGE VIA CURL AND PIPE (URL is the address to this file):
    	curl -s URL | perl - [-r] [-h] [-n] [-m] [\"Text\"] [-v]

By default, the License Agreement found in the config.license_tool
file on the BASEDIR will be used as the license text to be inserted
or removed.

By default, the Regex-Param Pairs found in the config.license_tool
will be used to determine the comment styles for each file. See
config.license_tool file for usage details.

By default, the root directory of the codebase is assumed to be
BASEDIR (this level's directory).

By default, the License Agreement will be inserted (per Regex-Param
Pairs) into files in which it is not already present.

The following command-line arguments can be given:

    -r[emove]
        Removes the License Agreement from files in the codebase, if
        present.

    -h[elp]
    	Pulls up this usage text.

    -n[ew]
    	Generates a new config.license_tool file.

    -m[essage] [\"Text\"]
    	Custom message to insert after License Agreement for all
    	files. If running this code via piping the \"Text\" must
    	be included, code will be unable to catch error.

    -v[iew]
    	Displays the file name(s) and associated information about how
    	the file(s) were processed.
    \n\n");

	exit(1);
}
