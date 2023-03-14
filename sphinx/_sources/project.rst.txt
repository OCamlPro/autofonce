
.. _Project Configuration:

Project Configuration
=====================

The project configuration is specified in either the
:code:`autofonce.toml` file. or the :code:`.autofonce` file (chosen in
this order).

There are actually three parts in such a project configuration file:

* General variables, such as anchors to detect source and
  build directories

* Testsuites, describing the testsuites that are available
  in the project

* Environments, i.e. scripts parts to build the environment
  in which tests are executed

General Variables
-----------------

The general variables are:

* :code:`project.name`: the name of the project. This name is not
  currently used, but *known* projects come with this name, and the
  name is used to autodetect that the project should use this
  configuration.

* :code:`project.source_anchors`: a list of files. :code:`autofonce`
  uses this list to try to detect the source directory of the project
  (i.e. the project root or topdir), from where it is run. The source
  directory is the first directory found that contains an existing
  file at the specified path while moving to upper directories. If no
  directory is found for the first anchor, the second anchor is used,
  and so on. Finally, either a :code:`"!"` anchor is used and triggers
  a failure, or the current directory is used. :code:`autofonce`
  creates a variable :code:`AUTOFONCE_SOURCE_DIR` before the test
  environment with the value found for this directory.

* :code:`project.build_anchors`: a list of files. :code:`autofonce`
  must always be run from within the build directory or a
  sub-directory. It uses this variable similarly to
  :code:`source_anchors`.  :code:`autofonce` creates a variable
  :code:`AUTOFONCE_BUILD_DIR` before the test environment with the
  value found for this directory.

* :code:`project.build_dir_candidates`: a list of anchors from where
  to look for :code:`build_anchors`. By default, :code:`autofonce`
  uses the current directory and search for build anchors in upper
  directories.  This option can be used to run :code:`autofonce` from
  outside the build directory, by trying to detect the location of the
  build directory. Once one of the :code:`build_dir_candidates` has
  been found, the directory it points to will be used as the current
  directory to find the :code:`build_anchors`.

* :code:`project.run_from`: where the :code:`_autofonce/` directory will be
  created. This option can take 3 values: :code:`"build"` for the
  build directory, :code:`"source"` for the source directory, and
  :code:`"config"` for the directory containing the configuration
  file.

* :code:`project.captured_files`: a list of paths in the source
  directory. If one of the tests fails, :code:`autofonce` will try to
  include all these files into the generated
  :code:`_autofonce/results.log` file. These files should be text
  files, as `aufofonce` does not use any encoding mechanism.

For example, for :code:`gnucobol`, this section looks like::

  [project]
  name = "gnucobol"
  source_anchors = [ "tests/testsuite.at", "!" ]
  build_anchors = [ "cobc/cobc", "!" ]
  build_dir_candidates = [ "_build" ]
  run_from = "build"
  captured_files = [ "_build/atlocal", "_build/atconfig" ]

.. _Testsuite Descriptions:

Testsuite Descriptions
----------------------

A testsuite is described by 4 components:

* its name, used to refer to the testsuite with the :code:`-t
  <TESTSUITE>` option (by default, :code:`autofonce` uses the first
  testsuite described in this file).

* its file name, i.e. the file that contains the macros for the
  tests. The default file name is :code:`tests/testsuite.at`.

* its path, i.e. the path in which `m4_include(file)` will search for
  :code:`file`. The default path is :code:`[ "tests/testsuite.src" ]`.
  Note that the directory containing the testsuite file name will
  always be added to the path.

* its environment, i.e. the name of the environment (see next section)
  to use for the tests of this testsuite. The default environment is
  :code:`testsuite`.

Such a section looks like::

  [testsuites.testsuite]
  file = "tests/testsuite.at"
  path = [ "tests/testsuite.src"]
  env = "testsuite"

If your project contains several testsuites, you can define a section
for each of them, with different names, file names or environments for
example.

Note that, if a testsuite is not available in the project
configuration file, it is possible to specify one directly from the
command line by providing the following arguments:

* :code:`-T path/to/tests` (mandatory): path to the file or directory
  containing the testsuite
* :code:`-E path/to/env.sh` (optional): path to a script that can be
  used to specify the environment (ran from every test dir)
* :code:`-I subdir` (optional): path to a subdirectory where included
  tests should be search in

Environment Descriptions
------------------------

The environment of a test is a part of shell script, that is added at
the end of the file :code:`env_autofonce.sh` in each test directory.

Before, :code:`autofonce` defines a few environment variables:

* :code:`AUTOFONCE_TESTSUITE`, the name of the testsuite
* :code:`AUTOFONCE_RUN_DIR`, the directory from which tests are run
  (containing the :code:`_autotest/` sub-directory)
* :code:`AUTOFONCE_SOURCE_DIR`, the root directory of the project
* :code:`AUTOFONCE_BUILD_DIR`, the build directory of the project

The goal of the environment part is to use these variables to
translate them in variables that are used by tests to locate their
dependencies.

There are two ways to define environments, for example here, we define
the environment called :code:`testsuite`:

* inline environment: the environment is specified directly in this
  file::

    [envs]
    testsuite = """
    export PATH=${AUTOFONCE_BUILD_DIR}/bin:$PATH
    """

* outside files: the environment is defined in a project file, that is
  referenced from here::

    [envs]
    testsuite = "<tests/testsuite.env"

Note that environments can typically called the :code:`atconfig` and
:code:`atlocal` scripts created by GNU Autoconf tools.
