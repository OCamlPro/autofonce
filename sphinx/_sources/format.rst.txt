Writing Tests for Autofonce
===========================

Though :code:`autofonce` was originally developed to run the Autoconf
Testsuite of GnuCOBOL, it provides a convenient way to write tests for
any project, especially as it provides additionnal macros (that have
no equivalent in the Autoconf world). Here is a description of how to
write tests for :code:`autofonce`.

Example of a Simple Test
------------------------

Here is a very simple example of test::

  # Start of a test, and the name that will be displayed
  AT_SETUP([Example test])
  
  # can be used to select tests to run:
  AT_KEYWORDS([example test autofonce]) 
  
  # create a file `file` with its content
  AT_DATA([file], [
  content of file
  on multiple lines
  ])
  
  # call some command, check its exit code, stdout, stderr
  AT_CHECK([cat file], [0], [stdout of my command], [stderr of my command])
  # you can do more, ignore some results, run more tests in case of failure, etc.
  
  # end of the test
  AT_CLEANUP

Structure of a Test Suite
-------------------------

A testsuite is usually composed of many tests in different files.
:code:`autofonce` has two behavior to handle collections of test:

* You can provide the directory containing the tests.
  :code:`autofonce` will scan the directory and recursively all
  sub-directories, looking for files ending with `.at` suffix.  It will
  also consider any file within a test directory as a file that should
  be copied to run the corresponding tests (:code:`AT_COPY_ALL` mode).

* You can provide a master file, that contains the list of all the
  tests to include. Such a file would look like this::

    AT_INIT([Autofonce tests])
    AT_COLOR_TESTS
    AT_TESTED([autofonce])
    
    AT_BANNER([Simple tests])
    m4_include([simple_tests.at])
    
    AT_BANNER([Tests with copies])
    m4_include([copy_tests.at])

  Notice the use of :code:`m4_include` to include specific
  files. These files are searched in a path, specified in the
  configuration file or on the command-line.

Test Format Specification
-------------------------

Autoconf defines all its macros starting with the :code:`AT_` prefix,
and expect users to define additional macros with other prefixes. So,
for :code:`autofonce` additional macros, the :code:`AF_` prefix can be
used. However, :code:`autofonce` will always understand both prefixes
for any of its macros, but will use the previous naming scheme during
promotion (i.e. :code:`AT_` for Autoconf Standard macros, and
:code:`AF_` for its own extension macros).

Escaping within arguments
~~~~~~~~~~~~~~~~~~~~~~~~~

Arguments can be parsed using two different passes:

* Most arguments are converted to strings using the two passes
* As an exception, the *run-if-fail* and *run-if-pass* arguments of
  :code:`AT_CHECK()` (4th and 5th arguments) go only through the first
  pass and then their content is interpreted as a list of macros.

The two passes can be described as follows:

* Brackets must always match each-other, i.e. a left bracket must
  always be matched by a right bracket
  (:code:`...[...]...`). Quadrigraphs (during the second pass) should
  be used for isolated brackets.

* During the first pass:

  * Spaces before the first non space character of the argument are
    skipped
  * Brackets at the first level are removed: :code:`A[B]C[D]E` becomes
    :code:`ABCDE`
  * Other levels of brackets are kept until the second
    pass::code:`A[B[C]D]E` becomes :code:`AB[C]DE`
  * Parentheses outside of the first level of brackets must match
    each-other. A non-matched left parenthesis fails as the argument
    never terminates, while a non-matched right parenthesis finishes
    the last argument of the macro.
  * :code:`#` is interpreted as a simple character and not a comment

* During the second pass:

  * Brackets at the first level are removed: :code:`A[B]C[D]E` becomes
    :code:`ABCDE`. Since these brackets were formerly the second level
    of bracket of the first pass, it means that an initial
    :code:`A[B[C]D]E` argument becomes :code:`ABCDE` after the two
    passes.
  * Other levels of brackets are kept
  * Parenthesis are not interpreted as special characters
  * The following list of escape sequences (quadrigraphs) are translated:

    * :code:`@<:@` becomes :code:`[`
    * :code:`@:>@` becomes :code:`]`
    * :code:`@$|@` becomes :code:`$`
    * :code:`@%:@` becomes :code:`#`
    * :code:`@&t@` becomes :code:`` (empty)
    * :code:`@{:@` becomes :code:`(` (version > 0.8)
    * :code:`@:}@` becomes :code:`)` (version > 0.8)


Toplevel Macros
~~~~~~~~~~~~~~~

These macros should only be used outside of a test.

* :code:`AT_COPYRIGHT([copyright])`: copyright notice of the testsuite
* :code:`AT_INIT([testsuite-name])`: name of the testsuite
* :code:`AT_COLOR_TESTS`: discarded
* :code:`AT_TESTED([executables])`: list of space separated commands
* :code:`AT_BANNER([banner])`: a banner separating tests
* :code:`m4_include([file.at])`: include macros from a file.
  :code:`autofonce` will try to find the file withing a directory
  :code:`testsuite.src` in the same directory. Note that behaviors specified
  in the included file have a scope limited to this included file.

Additionnal macros understood only by :code:`autofonce`. These macros
impact tests following them, and have a scope that finishes at the end
of the file containing them:

* :code:`AF_ENV([shell code])`: this shell code will be included in
  the script run before running any check in a test;
* :code:`AF_COPY_ALL([true/false])`: if true, copy all files in the
  directory of the test file in the test directory when they are run;
* :code:`AF_LINK_ALL([true/false])`: if true, link all files in the
  directory of the test file in the test directory when they are run
  (i.e. same as :code:`AF_COPY_ALL`, but link instead of copy, often to
  save space);
* :code:`AF_SUBST([env-variables])`: a list of space-separated environment
  variables in :code:`autofonce` environment, that should be substituted
  back in the stdout and stderr output of commands run in checks.

  For example, :code:`AF_SUBST([HOME])` would replace
  :code:`/home/user` by :code:`${HOME}` in all following commands. It
  can be used to check the output of a command that could include
  absolute paths corresponding to environment variables.

  Use :code:`AF_SUBST([])` to disable any substitution in following
  commands (can be useful as substitutions are expensive on big outputs).

  Use the special :code:`AUTOFONCE` name to specify that the run dir,
  build dir and source dirs should be substituted too, respectively by
  :code:`${AUTOFONCE_RUN_DIR}/${TEST_ID}`,
  :code:`${AUTOFONCE_BUILD_DIR}` and :code:`${AUTOFONCE_SOURCE_DIR}`.


Test Macros
~~~~~~~~~~~

Typical Autoconf macros are:

* :code:`AT_SETUP([test-name])`: beginning of a test
* :code:`AT_KEYWORDS([keywords])`: list of space separating keywords to
  select the test
* :code:`AT_DATA([file-name], [file-content])`: create the corresponding file
* :code:`AT_CHECK([shell-command], [retcode], [stdout], [stderr], [run-if-fail], [run-if-pass])`: all arguments are optional except for the first one.
  *run-if-fail* and *run-if-pass* should always be specified within brackets
  (as otherwise, brackets within them would be removed).
  :code:`[ignore]` can be used in the *retcode*, *stdout* or *stderr* places
  to ignore any difference there.
* :code:`AT_CLEANUP`: end of test
* :code:`AT_SKIP_IF([shell-condition])`: test should be skipped
  if shell-condition is true
* :code:`AT_XFAIL_IF([shell-condition])`: failure of test is expected
  if shell-condition is true
* :code:`AT_FAIL_IF([shell-condition])`: make test fail if shell-condition is
  true
* :code:`AT_CAPTURE_FILE([file-name])`: capture file in case of failure

Autofonce additional macros are:

* :code:`AF_ENV([shell])`: shell code to include before running checks
  (typically to specify environment variables)
* :code:`AF_COPY([files])`: copy this space-separated  list of files from the
  test directory to the directory where the test will be run
* :code:`AF_LINK([files])`: link this space-separated list of files to the test
  directory to link from the directory where the test will be run

  
Autoconf Documentation
----------------------

Read
https://www.gnu.org/software/autoconf/manual/autoconf-2.67/html_node/Writing-Testsuites.html
for a detailed description of Autoconf test macros.
