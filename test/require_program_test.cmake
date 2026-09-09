# © Joseph Cameron - All Rights Reserved
#
# Tests for jfc_require_program. Run it directly, from anywhere:
#
#     cmake -P test/require_program_test.cmake
#
cmake_minimum_required(VERSION 3.21)

include("${CMAKE_CURRENT_LIST_DIR}/../modules/debug/debug.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../modules/require_program/require_program.cmake")

set(_jfc_test_failures 0)
set(_jfc_test_count 0)

function(jfc_expect_equal aDescription aActual aExpected)
    math(EXPR _jfc_test_count "${_jfc_test_count}+1")
    set(_jfc_test_count "${_jfc_test_count}" PARENT_SCOPE)

    if (NOT "${aActual}" STREQUAL "${aExpected}")
        message(SEND_ERROR "  FAIL ${aDescription}\n       expected [${aExpected}]\n       actual   [${aActual}]")

        math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
        set(_jfc_test_failures "${_jfc_test_failures}" PARENT_SCOPE)
    else()
        message(STATUS "  ok   ${aDescription}")
    endif()
endfunction()

function(jfc_expect_true aDescription aActual)
    math(EXPR _jfc_test_count "${_jfc_test_count}+1")
    set(_jfc_test_count "${_jfc_test_count}" PARENT_SCOPE)

    if (aActual)
        message(STATUS "  ok   ${aDescription}")
    else()
        message(SEND_ERROR "  FAIL ${aDescription}\n       expected a true value, got [${aActual}]")

        math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
        set(_jfc_test_failures "${_jfc_test_failures}" PARENT_SCOPE)
    endif()
endfunction()

message(STATUS "jfc_require_program")

jfc_require_program("cmake")

jfc_expect_equal("a present program is found" "${CMAKE_FOUND}" "TRUE")
jfc_expect_true("its executable path is returned" "${CMAKE_EXECUTABLE}")

if (EXISTS "${CMAKE_EXECUTABLE}")
    message(STATUS "  ok   the returned path exists on disk")
else()
    message(SEND_ERROR "  FAIL the returned path exists on disk\n       [${CMAKE_EXECUTABLE}]")
    math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
endif()
math(EXPR _jfc_test_count "${_jfc_test_count}+1")

jfc_require_program("jfc_no_such_program_anywhere_xyzzy")

jfc_expect_equal("a missing program is not fatal, and reports FALSE"
    "${JFC_NO_SUCH_PROGRAM_ANYWHERE_XYZZY_FOUND}" "FALSE")
jfc_expect_equal("a missing program returns no path"
    "${JFC_NO_SUCH_PROGRAM_ANYWHERE_XYZZY_EXECUTABLE}" "")

if (DEFINED CACHE{CMAKE})
    message(SEND_ERROR "  FAIL the bare program name is not squatted in the cache\n       CACHE{CMAKE} is set")
    math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
else()
    message(STATUS "  ok   the bare program name is not squatted in the cache")
endif()
math(EXPR _jfc_test_count "${_jfc_test_count}+1")

jfc_expect_true("the cache entry it does create is namespaced" "${JFC_PROGRAM_CMAKE}")

jfc_require_program("cmake")
jfc_expect_equal("a repeated query is stable" "${CMAKE_FOUND}" "TRUE")

message(STATUS "")

if (_jfc_test_failures GREATER 0)
    message(FATAL_ERROR "${_jfc_test_failures} of ${_jfc_test_count} assertions failed")
endif()

message(STATUS "all ${_jfc_test_count} assertions passed")

