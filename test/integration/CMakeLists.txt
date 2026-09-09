# © Joseph Cameron - All Rights Reserved
#
# Configure-time integration test for jfc_add_tests.
#
#     cmake -S test/integration -B <somewhere>
#
cmake_minimum_required(VERSION 3.21)

project(jfc_cmake_integration)

include("${CMAKE_CURRENT_LIST_DIR}/../../jfclib.cmake")

set(_failures 0)

macro(expect aDescription aTruth)
    if (${aTruth})
        message(STATUS "  ok   ${aDescription}")
    else()
        message(SEND_ERROR "  FAIL ${aDescription}")
        math(EXPR _failures "${_failures}+1")
    endif()
endmacro()

message(STATUS "jfc_add_tests")

add_library(probe STATIC "${CMAKE_CURRENT_LIST_DIR}/src/probe.cpp")

target_include_directories(probe PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>")

target_compile_features(probe PUBLIC cxx_std_20)

if (TARGET probe)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the fixture library is created" ${_ok})

jfc_add_tests(
    C++_STANDARD 20
    C_STANDARD 11

    TEST_SOURCE_FILES
        "${CMAKE_CURRENT_LIST_DIR}/test/probe_test.cpp"

    LIBRARIES
        probe)

set(_test_target "${PROJECT_NAME}")

if (TARGET ${_test_target})
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("a test target is generated" ${_ok})

if (_test_target MATCHES "probe_test_|jfc_cmake_integration_test_")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the test target is named after its project (${_test_target})" ${_ok})

get_target_property(_test_includes ${_test_target} INCLUDE_DIRECTORIES)

if (_test_includes MATCHES "add_tests/include")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the test target receives catch2" ${_ok})

get_target_property(_test_links ${_test_target} LINK_LIBRARIES)

if (_test_links MATCHES "probe")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the test target links the library under test" ${_ok})

message(STATUS "jfc_generate_cmake_header")

jfc_generate_cmake_header()

set(_buildinfo "${PROJECT_BINARY_DIR}/generated_include/${PROJECT_NAME}/buildinfo.h")

if (EXISTS "${_buildinfo}")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the header is generated at generated_include/<project>/buildinfo.h" ${_ok})

if (_ok)
    file(READ "${_buildinfo}" _buildinfo_text)
else()
    set(_buildinfo_text "")
endif()

if (_buildinfo_text MATCHES "JFC_TARGET_PLATFORM_")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("it defines JFC_TARGET_PLATFORM_<system>" ${_ok})

if (_buildinfo_text MATCHES "${PROJECT_NAME}_BuildInfo_TargetPlatform")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("its symbols are prefixed with the project name" ${_ok})

string(REGEX MATCH "Random_bits128 = \"([^\"]*)\"" _m "${_buildinfo_text}")
string(LENGTH "${CMAKE_MATCH_1}" _random_length)

if (_random_length GREATER_EQUAL 22)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the random field is long enough to be 128 bits (${_random_length} chars)" ${_ok})

message(STATUS "jfc_generate_documentation_doxygen")

jfc_require_program("doxygen")

if (NOT DOXYGEN_FOUND)
    message(STATUS "  skip doxygen is not installed")
else()
    jfc_generate_documentation_doxygen(
        README_PATH  "${CMAKE_CURRENT_LIST_DIR}/README.md"
        PROJECT_LOGO "${CMAKE_CURRENT_LIST_DIR}/logo.png"
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_LIST_DIR}/include")

    if (EXISTS "${CMAKE_BINARY_DIR}/integration/doxy.config")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("the doxy config is written to a directory named after the source directory" ${_ok})

    if (_ok)
        file(READ "${CMAKE_BINARY_DIR}/integration/doxy.config" _doxy)
    else()
        set(_doxy "")
    endif()

    if (_doxy MATCHES "PROJECT_NAME =[ ]+[^ \n][^\n]*")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("PROJECT_NAME is resolved and not empty" ${_ok})

    if (_doxy MATCHES "\nINPUT =[^\n]*integration/include" AND NOT _doxy MATCHES "\nINPUT =[^\n]*;")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("INPUT is a space separated list, not a cmake ;-list" ${_ok})

    if (EXISTS "${CMAKE_BINARY_DIR}/integration/index.html")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("doxygen produced html" ${_ok})
endif()

message(STATUS "")

if (_failures GREATER 0)
    message(FATAL_ERROR "${_failures} integration assertions failed")
endif()

message(STATUS "integration assertions passed")
