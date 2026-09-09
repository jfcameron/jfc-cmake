# © Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

include("${CMAKE_CURRENT_LIST_DIR}/modules/debug/debug.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/modules/add_fuzz_tests/add_fuzz_tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/add_tests/add_tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_buildinfo/generate_buildinfo.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_documentation_doxygen/generate_documentation_doxygen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/git/git.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/parse_arguments/parse_arguments.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/require_program/require_program.cmake")
