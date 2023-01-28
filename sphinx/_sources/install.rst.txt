Installation
============

Install from binaries
---------------------

We try to provide portable Linux executables on x86_64.
Such binaries are available from the Release page at:

https://github.com/OCamlPro/autofonce/releases

To use them, you can use for example::

  wget https://github.com/OCamlPro/autofonce/releases/download/v0.1.0/autofonce-v0.1.linux-x86_66.bin
  chmod +x autofonce-v0.1.linux-x86_66.bin
  sudo mv autofonce-v0.1.linux-x86_66.bin /usr/local/bin/autofonce

Install with :code:`opam`
-------------------------

If :code:`autofonce` is available in your opam repository, you can just call::

  opam install autofonce

Build and install with :code:`dune`
-----------------------------------

Checkout the sources of :code:`autofonce` in a directory.

You need a switch with at least version :code:`4.07.0` of OCaml,
you can for example create it with::

  opam switch create 4.10.0

Then, you need to install all the dependencies::

  opam install --deps-only .

Finally, you can build the package and install it::

  eval $(opam env)
  dune build
  dune install

Note that a :code:`Makefile` is provided, it contains the following
targets:

* :code:`build`: build the code
* :code:`install`: install the generated files
* :code:`build-deps`: install opam dependencies
* :code:`sphinx`: build sphinx documentation (from the :code:`sphinx/` directory)
* :code:`dev-deps`: build development dependencies, in particular
  :code:`ocamlformat`, :code:`odoc` and :code:`merlin`
* :code:`doc`: build documentation with :code:`odoc`
* :code:`fmt`: format the code using :code:`ocamlformat`
* :code:`test`: run tests
