Compatibility with Autoconf
===========================

Syntax of GNU Autoconf Testuites
--------------------------------

:code:`autofonce` can only read testsuites that are in a subset of what
GNU Autoconf allows. Indeed, testsuites for Autoconf are shell scripts
with M4 macros inside. Instead, :code:`autofonce` can only read a subset
of known builtin M4 macros with a simpler syntax.

For the syntax, :code:`autofonce` has the following limitations:

* Macros should never appear inside brackets. Indeed, data within
  brackets is interpreted as a string.

* Scripts commands are only accepted within a test sequence (i.e. after
  :code:`AT_SETUP` and before :code:`AT_CLEANUP`), and should never
  exceed one line.

See the next section for advices on how to translate existing testsuites to
be used by :code:`autofonce`.

The following macros are understood at toplevel by :code:`autofonce`:

* :code:`AT_COPYRIGHT([copyright])`: copyright notice of the testsuite
* :code:`AT_INIT([testsuite-name])`: name of the testsuite
* :code:`AT_COLOR_TESTS`: discarded
* :code:`AT_TESTED([executables])`: list of space separated commands
* :code:`AT_BANNER([banner])`: a banner separating tests
* :code:`m4_include([file.at])`: include macros from a file.
  :code:`autofonce` will try to find the file withing a directory
  :code:`testsuite.src` in the same directory.
* :code:`AT_SETUP([test-name])`: beginning of a test

The following macros are understood within a test (after :code:`AT_SETUP`):

* :code:`AT_KEYWORDS([keywords])`: list of space separating keywords to
  select the test
* :code:`AT_SKIP_IF([shell-condition])`: currently, :code:`autofonce`
  always skip such tests to avoid running the condition.
* :code:`AT_DATA([file-name], [file-content])`: create the corresponding file
* :code:`AT_CAPTURE_FILE([file-name])`: capture file in case of failure
* :code:`AT_CHECK([shell-command], [retcode], [stdout], [stderr], [run-if-fail], [run-if-pass])`: all arguments are optional except for the first one.
  *run-if-fail* and *run-if-pass* should always be specified within brackets
  (as otherwise, brackets will be removed).
* :code:`AT_CLEANUP`: end of test

Advices to port testsuites to :code:`autofonce`
-----------------------------------------------

In general, using shell outside of macros should be
avoided. :code:`autofonce` has some support for single line shell
commands, and :code:`if ... ; then` / :code:`else` / :code:`fi`
on different lines.

* Toplevel shell commands: such commands should be completely avoided

* Shell commands within tests: use :code:`AT_CHECK` macros to execute such
  commands. For example::

    sort < file1 > file2

  should be translated into::

    AT_CHECK([sort < file1 > file2])

* Shell conditional execution. use :code:`AT_CHECK` and its *run-of-fail* and
  *run-if-pass* parts to encode :code:`if ... then ... else`.

  For example::

    if test "x" != "y" ; then
      ...THEN_MACROS...
    else
      ...ELSE_MACROS...
    fi

  should be translated into::

    AT_CHECK([test "x" != "y"], [1], [], [],
      ...THEN_MACROS...
    ,
      ...ELSE_MACROS...
    )

  Pay attention to the fact that the order of fail/pass is the opposite
  for :code:`if-then-else` and :code:`AT_CHECK`, so we have to expect
  a result of :code:`[1]` (failed :code:`test`) to keep the same order.
