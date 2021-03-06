codelicenser
============

This script adds or removes license text from files in the codebase containing the script, the code must be loaded on the top directory.

Running codelicenser.pl
-----------------------

**Recommended Usage:**

    curl -s https://raw.github.com/lml/codelicenser/master/codelicenser.pl | perl - [-r] [-h] [-n] [-m] ["Text"] [-v]

By default, the License Agreement found in the config.license_tool file on the *BASEDIR* will be used as the license text to be inserted or removed.

By default, the Regex-Param Pairs found in the config.license_tool will be used to determine the comment styles for each file. See config.license_tool file for usage details.

By default, the root directory of the codebase is assumed to be *BASEDIR* (this level's directory).

By default, the License Agreement will be inserted (per Regex-Param Pairs) into files in which it is not already present.

*The following command-line arguments can be given:*

+ **Removes** the License Agreement from files in the codebase, if present.

<pre><code>-r[emove]</code></pre>

+ **Help** function, pulls up this text.

<pre><code>-h[elp]</code></pre>

+ Generates a **New** config.license_tool file.

<pre><code>-n[ew]</code></pre>

+ Custom **Message** to insert after License Agreement for all files. If running this code via piping (as in the **Recommended Usage**) the "Text" must be included, code will be unable to catch error.

<pre><code>-m\[essage\] ["Text"]</code></pre>

+ **Views** the file name(s) and associated information about how the file(s) were processed.

<pre><code>-v[iew]</code></pre>


Modifying config.license_tool
-----------------------------

The config.license_tool has two features. It first includes the License Agreement followed by a table of perl regular expression and a parameter, these are called Regex-Param pairs.

Text after the **'#'** symbol is considered to be a comment and is ignored.

Blank lines are ignored.

Text after the **'@'** symbol is considered to be the License Agreement. Further note the first line of the License Agreement must include the phrase **'Copyright'**.

All other lines are considered to be Regex-Param pairs.

Whitespace before or after any line and the whitespace included in the Regex-Param pairs is ignored.

For each filename processed, this config.license_tool is scanned. The first Regex matching the current filename will cause the paired parameter to be passed into the Licenser appending the License Agreement to current filename.

Appropriate commenting and 'pretty' formatting is done to each filename processed.

###Regex-Param Pairs
*Making new patterns/parameters:*

    pass(Inline, BlockS, BlockI, BlockE, Skip, Before, After)
	
+ **Inline** is appended to every line of License Agreement
+ **BlockS** is appended to the first line of License Agreement
+ **BlockI** is appended to all lines that are not first of License Agreement
+ **BlockE** is appended after last line of License Agreement
+ **Skip** is number of lines to skip before any insertion
+ **Before** is number of lines to insert immediately before License Agreement
+ **After** is number of lines to insert immediately after License Agreement

*To Ignore filetypes:*

Use **'Noop'** instead of a **'pass()'** parameter.

*Sample parameters for filetypes:*
	
+ **Coffee**		use inline '# '

<pre><code>pass('# ', '', '', '', 0, 0, 2)</code></pre>

+ **Css**		use block '/* ... */' with intermediate ' * '

<pre><code>pass('', '/* ', ' * ', ' */', 0, 0, 2)</code></pre>

+ **Erb**		use block '<%# ... %>'

<pre><code>pass('', '&#60%# ', '', '%&#62', 0, 0, 2)</code></pre>

+ **JavsScript**		use inline '// '

<pre><code>pass('// ', '', '', '', 0, 0, 2)</code></pre>

+ **Latex**		use inline '% '

<pre><code>pass('% ', '', '', '', 0, 0, 2)</code></pre>

+ **PerlModule**		use inline '# '

<pre><code>pass('# ', '', '', '', 0, 0, 2)</code></pre>

+ **Rake**		use inline '# '

<pre><code>pass('# ', '', '', '', 0, 0, 2)</code></pre>

+ **Ruby**		use inline '# '

<pre><code>pass('# ', '', '', '', 0, 0, 2)</code></pre>

+ **Script**		use inline '# ' after skipping first line

<pre><code>pass('# ', '', '', '', 1, 2, 2)</code></pre>

+ **Scss**		use inline '// '

<pre><code>pass('// ', '', '', '', 0, 0, 2)</code></pre>

+ **Text**		use inline '# '

<pre><code>pass('# ', '', '', '', 0, 0, 2)</code></pre>

+ **Yaml**		use inline '# '

<pre><code>pass('# ', '', '', '', 0, 0, 2)</code></pre>