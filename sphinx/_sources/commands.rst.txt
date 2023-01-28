
Sub-commands and Arguments
==========================
Common arguments to all sub-commands:


* :code:`-q` or :code:`--quiet`   Set verbosity level to 0

* :code:`-v` or :code:`--verbose`   Increase verbosity level

Overview of sub-commands::
  
  init
    Initialize project to run the testsuite with autofonce
  
  list
    Print testsuite of the current project
  
  new
    Create a new test by running a command
  
  run
    Run testsuite of the current project


autofonce init
~~~~~~~~~~~~~~~~

Initialize project to run the testsuite with autofonce



**DESCRIPTION**


To run tests with **autofonce**, tests typically require
some environment variables to be set. For that, **autofonce** uses a
file named **autofonce.env** in the project. **autofonce** will also
use this file to create a directory **_autotest/** where tests are
run and results are kept.

This command can be used to create the file **autofonce.env**
in the current directory. By default, the file is empty, and you will
need to fill it from inspecting files in the project, such as **atconfig**
and **atlocal**, typically used by GNU Autoconf testsuites.

Yet, in some cases, **autofonce** knows the project in which
you are and can provide you will an example of **autofonce.env** for that
particular project.

You can use the following command to list known projects:
::

  $ autofonce init --list


You can then select the project using:
::

  $ autofonce init -p gnucobol


**autofonce** will also inspect the path to see if it
recognize the name of a project it knows. In such cases, you won't need
to provide the project name, as it is automatically detected.

**USAGE**
::
  
  autofonce init [OPTIONS]

Where options are:


* :code:`-f` or :code:`--force-update`   Force update of the environment file

* :code:`-l` or :code:`--list-known`   List known projects with environment files

* :code:`-p PROJECT` or :code:`--project PROJECT`   Use environment file from known project


autofonce list
~~~~~~~~~~~~~~~~

Print testsuite of the current project



**DESCRIPTION**


List the tests, with their numeric identifier, their name and their location in the testsuite files.

**USAGE**
::
  
  autofonce list ID [OPTIONS]

Where options are:


* :code:`ID`   Exec ending at test ID

* :code:`--after ID`   Exec starting at test ID

* :code:`--before ID`   Exec ending at test ID

* :code:`--ids ID`   Run only test ID

* :code:`-k KEYWORD` or :code:`--keywords KEYWORD`   Run only tests matching KEYWORD

* :code:`-t FILE` or :code:`--testsuite FILE`   File to lookup (default to 'tests/testsuite.at')


autofonce new
~~~~~~~~~~~~~~~

Create a new test by running a command



**DESCRIPTION**


Runs the command, captures its retcode, stdout and stderr
and generates the corresponding autoconf testsuite file.

**USAGE**
::
  
  autofonce new ARGUMENTS [OPTIONS]

Where options are:


* :code:`ARGUMENTS`   List of arguments

* :code:`-c FILE`   Capture file in AT_CAPTURE_FILE(...)

* :code:`-f FILE`   Store file in AT_DATA(...)

* :code:`-k KEYWORD`   Store keyword in AT_KEYWORDS(...)

* :code:`--name NAME`   Store name in AT_SETUP(...)

* :code:`-o FILE` or :code:`--output FILE`   Name of generated file


autofonce run
~~~~~~~~~~~~~~~

Run testsuite of the current project



**DESCRIPTION**


Run the testsuite.

**autofonce** expects the existence of two files: **autofonce.env** and **tests/testsuite.at**.

**autofonce.env** is required to configure the tests that will be run. Check the following command for more information:
::

  $ autofonce init --help


**tests/testsuite.at** contains the descriptions of the tests, as expected by the GNU Autoconf testsuite. Check the following command for more information:
::

  $ autofonce list --help


To run tests, **autofonce** will create a directory **_autotest/** in the directory containing the file **autofonce.env**.

Every test is run independantly in a test directory with its number in the **_autotest/** directory. The test directory is removed if the test does not fail, or if it was expected to fail. Use the **--keep-more** argument to keep directories of tests that have been skipped or were expected to fail. Use the **--keep-all** argument to keep all directories.

You can select which tests to run, by selecting a range of tests using **--after TEST** or **--before TEST**, by selecting individual tests identifiers using **--id NUM** or by selecting keywords using **--keyword KEYWORD**.

**autofonce** will only display failed tests on its output. You can use the argument **--print-all** to display all tests that were not OK, or just read the generated file **_autotests/results.log**.

**USAGE**
::
  
  autofonce run ID [OPTIONS]

Where options are:


* :code:`ID`   Exec ending at test ID

* :code:`-S` or :code:`--keep-all`   Keep all directories of tests

* :code:`--after ID`   Exec starting at test ID

* :code:`--before ID`   Exec ending at test ID

* :code:`-e` or :code:`--stop-on-failure`   Stop on first failure

* :code:`--ids ID`   Run only test ID

* :code:`-j NJOBS`   Set maximal parallelism

* :code:`--j1`   Use Sequential scheduling of tests

* :code:`-k KEYWORD` or :code:`--keywords KEYWORD`   Run only tests matching KEYWORD

* :code:`--no-clean`   Do not clean _autotest/ dir on startup

* :code:`--print-all`   Print also expected failures

* :code:`-s` or :code:`--keep-more`   Keep directories of skipped and expected failed

* :code:`-t FILE` or :code:`--testsuite FILE`   File to lookup (default to 'tests/testsuite.at')
