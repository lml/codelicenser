codelicenser
============

Running codelicenser.pl
=======================
=======================

This script adds or removes license text from files in the codebase
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
