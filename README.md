# jfc-cmake

CMake modules shared by the C++ projects on this account: Catch2 test targets, fuzz harnesses, header checks, embedded files, build info, Doxygen, publishing (a program's folder for people to unzip and run, zipped and checked, with a glibc floor for Linux), and toolchains for cross compiling.

Reference documentation: https://jfcameron.github.io/jfc-cmake/

Vendor it as a submodule and include `jfclib.cmake`, which includes every module.

The reference is generated from the `.rst` block at the head of each module. To build it locally:
```
pip install sphinx sphinxcontrib-moderncmakedomain
sphinx-build docs docs/_build
```
