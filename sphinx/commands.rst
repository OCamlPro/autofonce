
Sub-commands and Arguments
==========================
Common arguments to all sub-commands:


* :code:`-q` or :code:`--quiet`   Set verbosity level to 0

* :code:`-v` or :code:`--verbose`   Increase verbosity level

Overview of sub-commands::
  
  config
    Print config of the current project
  
  init
    Initialize project to run the testsuite with autofonce
  
  list
    Print testsuite of the current project
  
  new
    Create a new test by running a command
  
  promote
    Promote tests results as expected results
  
  run
    Run testsuite of the current project


autofonce config
~~~~~~~~~~~~~~~~~~

Print config of the current project



**DESCRIPTION**


List the tests, with their numeric identifier, their name and their location in the testsuite files.

**USAGE**
::
  
  autofonce config ID [OPTIONS]

Where options are:


* :code:`ID`   Exec ending at test ID

* :code:`-E TESTSUITE.sh` or :code:`--env TESTSUITE.sh`   Env file for all tests

* :code:`-I DIR`   Add DIR to search path for tests

* :code:`-N KEYWORD` or :code:`--not KEYWORD`   Skip tests matching KEYWORD

* :code:`-T TESTSUITE.at` or :code:`--at TESTSUITE.at`   Path of the file containing the testsuite

* :code:`--after ID`   Exec starting at test ID

* :code:`--before ID`   Exec ending at test ID

* :code:`--failed`   Run only previously failed tests (among selected tests)

* :code:`--failures REASON`   Run failed tests with given failure

* :code:`-i ID` or :code:`--ids ID`   Run only test ID

* :code:`-k KEYWORD` or :code:`--keywords KEYWORD`   Run only tests matching KEYWORD

* :code:`-o TESTSUITE` or :code:`--output TESTSUITE`   Path of the output file (default: _autofonce/results.log)

* :code:`-t TESTSUITE` or :code:`--testsuite TESTSUITE`   Name of the testsuite to run (as specified in 'autofonce.toml')


autofonce init
~~~~~~~~~~~~~~~~

Initialize project to run the testsuite with autofonce



**DESCRIPTION**


To run tests with **autofonce**, tests typically require
some environment variables to be set. For that, **autofonce** uses a
file named **autofonce.toml** in the project (or **.autofonce**).
**autofonce** will also use this file to create a directory **_autofonce/**
where tests are run and results are kept.

This command can be used to create the file **autofonce.toml**
in the current directory. 

Yet, in some cases, **autofonce** knows the project in which
you are and can provide you with an example of **autofonce.toml** for that
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


* :code:`-f` or :code:`--force-update`   Force creation/update if file already exists

* :code:`-l` or :code:`--list-known`   List known projects with environment files

* :code:`-p PROJECT` or :code:`--project PROJECT`   Set project name to infer config


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

* :code:`-E TESTSUITE.sh` or :code:`--env TESTSUITE.sh`   Env file for all tests

* :code:`-I DIR`   Add DIR to search path for tests

* :code:`-N KEYWORD` or :code:`--not KEYWORD`   Skip tests matching KEYWORD

* :code:`-T TESTSUITE.at` or :code:`--at TESTSUITE.at`   Path of the file containing the testsuite

* :code:`--after ID`   Exec starting at test ID

* :code:`--before ID`   Exec ending at test ID

* :code:`--failed`   Run only previously failed tests (among selected tests)

* :code:`--failures REASON`   Run failed tests with given failure

* :code:`-i ID` or :code:`--ids ID`   Run only test ID

* :code:`-k KEYWORD` or :code:`--keywords KEYWORD`   Run only tests matching KEYWORD

* :code:`-o TESTSUITE` or :code:`--output TESTSUITE`   Path of the output file (default: _autofonce/results.log)

* :code:`-t TESTSUITE` or :code:`--testsuite TESTSUITE`   Name of the testsuite to run (as specified in 'autofonce.toml')


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


autofonce promote
~~~~~~~~~~~~~~~~~~~

Promote tests results as expected results



**DESCRIPTION**


After an unsucessful testsuite run, use this command to promote the results of tests to expected status.

**USAGE**
::
  
  autofonce promote ID [OPTIONS]

Where options are:


* :code:`ID`   Exec ending at test ID

* :code:`-E TESTSUITE.sh` or :code:`--env TESTSUITE.sh`   Env file for all tests

* :code:`-I DIR`   Add DIR to search path for tests

* :code:`-N KEYWORD` or :code:`--not KEYWORD`   Skip tests matching KEYWORD

* :code:`-T TESTSUITE.at` or :code:`--at TESTSUITE.at`   Path of the file containing the testsuite

* :code:`--after ID`   Exec starting at test ID

* :code:`--apply`   Apply promotion (default is to diff)

* :code:`--auto-run INT`   Promote and run until all tests have been promoted

* :code:`--before ID`   Exec ending at test ID

* :code:`--diff`   Diff promotion (default)

* :code:`--failed`   Run only previously failed tests (among selected tests)

* :code:`--failures REASON`   Run failed tests with given failure

* :code:`--fake .EXT`   Apply promotion to create new files with extension .EXT

* :code:`-i ID` or :code:`--ids ID`   Run only test ID

* :code:`-k KEYWORD` or :code:`--keywords KEYWORD`   Run only tests matching KEYWORD

* :code:`--no-comment`   Do not add a comment with the promotion date

* :code:`--not-exit`   Do not promote exit code

* :code:`-o TESTSUITE` or :code:`--output TESTSUITE`   Path of the output file (default: _autofonce/results.log)

* :code:`-t TESTSUITE` or :code:`--testsuite TESTSUITE`   Name of the testsuite to run (as specified in 'autofonce.toml')


autofonce run
~~~~~~~~~~~~~~~

Run testsuite of the current project



**DESCRIPTION**


Run the testsuite.

**autofonce** expects the existence of either **autofonce.toml** or **.autofonce**.

**autofonce.toml** is required to configure the tests that will be run, depending on the project. Check the following command for more information:
::

  $ autofonce init --help


Before running the tests, you may want to list the test in the current testsuite with:
::

  $ autofonce list --help


To run tests, **autofonce** will create a directory **_autofonce/** in the directory containing the file **autofonce.env**.

Every test is run independantly in a test directory with its number in the **_autofonce/** directory. The test directory is removed if the test does not fail, or if it was expected to fail. Use the **--keep-more** argument to keep directories of tests that have been skipped or were expected to fail. Use the **--keep-all** argument to keep all directories.

You can select which tests to run, by selecting a range of tests using **--after TEST** or **--before TEST**, by selecting individual tests identifiers using **--id NUM** or by selecting keywords using **--keyword KEYWORD**.

**autofonce** will only display failed tests on its output. You can use the argument **--print-all** to display all tests that were not OK, or just read the generated file **_autofonce/results.log**.

**USAGE**
::
  
  autofonce run ID [OPTIONS]

Where options are:


* :code:`ID`   Exec ending at test ID

* :code:`-E TESTSUITE.sh` or :code:`--env TESTSUITE.sh`   Env file for all tests

* :code:`-I DIR`   Add DIR to search path for tests

* :code:`-N KEYWORD` or :code:`--not KEYWORD`   Skip tests matching KEYWORD

* :code:`-S` or :code:`--keep-all`   Keep all directories of tests

* :code:`-T TESTSUITE.at` or :code:`--at TESTSUITE.at`   Path of the file containing the testsuite

* :code:`--after ID`   Exec starting at test ID

* :code:`--auto-promote INT`   Promote and run until all tests have been promoted

* :code:`--before ID`   Exec ending at test ID

* :code:`-e` or :code:`--stop-on-failure`   Stop on first failure

* :code:`--failed`   Run only previously failed tests (among selected tests)

* :code:`--failures REASON`   Run failed tests with given failure

* :code:`-i ID` or :code:`--ids ID`   Run only test ID

* :code:`-j NJOBS`   Set maximal parallelism

* :code:`--j1`   Use Sequential scheduling of tests

* :code:`-k KEYWORD` or :code:`--keywords KEYWORD`   Run only tests matching KEYWORD

* :code:`--no-clean`   Do not clean _autofonce/ dir on startup

* :code:`--no-comment`   Do not add a comment with the promotion date

* :code:`--not-exit`   Do not promote exit code

* :code:`-o TESTSUITE` or :code:`--output TESTSUITE`   Path of the output file (default: _autofonce/results.log)

* :code:`--print-all`   Print also expected failures

* :code:`-s` or :code:`--keep-more`   Keep directories of skipped and expected failed

* :code:`-t TESTSUITE` or :code:`--testsuite TESTSUITE`   Name of the testsuite to run (as specified in 'autofonce.toml')
