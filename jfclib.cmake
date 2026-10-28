# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
jfclib
------

Includes every module of jfc-cmake. A project vendors jfc-cmake as a submodule and includes this one file:

.. code-block:: cmake

  include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/jfc-cmake/jfclib.cmake")

Each module is also usable alone, by including its own file.
#]=======================================================================]

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

include("${CMAKE_CURRENT_LIST_DIR}/modules/add_fuzz_tests/add_fuzz_tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/add_tests/add_tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/check_headers/check_headers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/embed_file/embed_file.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_build_info/generate_build_info.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_documentation_doxygen/generate_documentation_doxygen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/parse_arguments/parse_arguments.cmake")
