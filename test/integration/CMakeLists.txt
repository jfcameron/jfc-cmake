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

    TEST_SOURCE_FILES
        "${CMAKE_CURRENT_LIST_DIR}/test/probe_test.cpp"

    LIBRARIES
        probe)

set(_test_target "${JFC_TEST_TARGET}")

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

if (PROJECT_NAME STREQUAL "jfc_cmake_integration")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("it leaves PROJECT_NAME alone" ${_ok})

if (DEFINED JFC_TEST_TARGET AND JFC_TEST_TARGET STREQUAL "jfc_cmake_integration_test_0")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("and publishes the test target as JFC_TEST_TARGET" ${_ok})

get_target_property(_cxx_required ${JFC_TEST_TARGET} CXX_STANDARD_REQUIRED)

if (_cxx_required)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the requested C++ standard is required, not merely requested" ${_ok})

get_target_property(_c_std ${JFC_TEST_TARGET} C_STANDARD)

if (NOT _c_std)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("C_STANDARD is left unset when it is not asked for" ${_ok})

message(STATUS "jfc_generate_build_info")

jfc_generate_build_info(INCLUDE_PATH gdk/probe)

set(_buildinfo "${PROJECT_BINARY_DIR}/generated_include/gdk/probe/build_info.h")

if (EXISTS "${_buildinfo}")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the header is generated at generated_include/<vendor>/<module>/build_info.h" ${_ok})

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

if (_buildinfo_text MATCHES "namespace gdk::probe::build_info")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("its symbols live in a namespace matching the include path" ${_ok})

if (_buildinfo_text MATCHES "BuildInfo_")
    set(_ok FALSE)
else()
    set(_ok TRUE)
endif()
expect("no symbol carries the old <project>_BuildInfo_ prefix" ${_ok})

if (_buildinfo_text MATCHES "inline constexpr const char \\*target_platform")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("its constants are snake_case and inline constexpr" ${_ok})

string(REGEX MATCH "random_bits128 = \"([^\"]*)\"" _m "${_buildinfo_text}")
string(LENGTH "${CMAKE_MATCH_1}" _random_length)

if (_random_length GREATER_EQUAL 22)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("the random field is long enough to be 128 bits (${_random_length} chars)" ${_ok})

jfc_generate_build_info()

if (EXISTS "${PROJECT_BINARY_DIR}/generated_include/jfc/cmake/build_info.h")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("with no arguments the path is derived from the repository name (jfc-cmake -> jfc/cmake)" ${_ok})

add_subdirectory(hyphen)

expect("a hyphenated path segment yields compilable identifiers" ${JFC_HYPHEN_PROBE_OK})



message(STATUS "jfc_generate_documentation_doxygen")

find_program(DOXYGEN_EXECUTABLE doxygen)

if (NOT DOXYGEN_EXECUTABLE)
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

    if (_doxy MATCHES "PROJECT_NAME[ \t]*=[ \t]*[^ \t\n][^\n]*")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("PROJECT_NAME is resolved and not empty" ${_ok})

    if (_doxy MATCHES "\nINPUT[ \t]*=[^\n]*integration/include" AND NOT _doxy MATCHES "\nINPUT[ \t]*=[^\n]*;")
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

    set(_nogit "${CMAKE_CURRENT_BINARY_DIR}/nogit_probe")

    execute_process(COMMAND git rev-parse --show-toplevel
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        RESULT_VARIABLE _enclosing_repo OUTPUT_QUIET ERROR_QUIET)

    if (_enclosing_repo EQUAL 0)
        message(STATUS "  skip the binary directory is inside a git repository")
    else()
        file(MAKE_DIRECTORY "${_nogit}/include" "${_nogit}/docs")
        file(WRITE "${_nogit}/README.md" "# probe\n\ntext\n")
        file(WRITE "${_nogit}/include/thing.h" "namespace probe { /// doc\nstruct thing { int x; };\n}\n")
        file(WRITE "${_nogit}/docs/icon.png" "")
        file(WRITE "${_nogit}/docs/CMakeLists.txt"
            "jfc_generate_documentation_doxygen(\n"
            "    PROJECT_LOGO \"\${CMAKE_CURRENT_LIST_DIR}/icon.png\"\n"
            "    README_PATH \"\${CMAKE_SOURCE_DIR}/README.md\"\n"
            "    INCLUDE_DIRECTORIES \"\${CMAKE_SOURCE_DIR}/include\")\n")
        file(WRITE "${_nogit}/CMakeLists.txt"
            "cmake_minimum_required(VERSION 3.21)\n"
            "project(tarball_probe)\n"
            "include(\"${CMAKE_CURRENT_LIST_DIR}/../../jfclib.cmake\")\n"
            "add_subdirectory(docs)\n")

        execute_process(
            COMMAND "${CMAKE_COMMAND}" -S "${_nogit}" -B "${_nogit}/out" -Wno-deprecated
            RESULT_VARIABLE _nogit_result OUTPUT_QUIET ERROR_VARIABLE _nogit_error)

        if (_nogit_result EQUAL 0)
            set(_ok TRUE)
        else()
            set(_ok FALSE)
            message(STATUS "       ${_nogit_error}")
        endif()
        expect("documentation generates outside a git repository" ${_ok})

        file(READ "${_nogit}/out/docs/doxy.config" _nogit_doxy)

        if (_nogit_doxy MATCHES "PROJECT_NAME[ \t]*=[ \t]*tarball_probe")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("with no repository the project name stands in for the repo name" ${_ok})

        file(WRITE "${_nogit}/docs/CMakeLists.txt"
            "jfc_generate_documentation_doxygen(\n"
            "    README_PATH \"\${CMAKE_SOURCE_DIR}/README.md\"\n"
            "    INCLUDE_DIRECTORIES \"\${CMAKE_SOURCE_DIR}/include\")\n")

        execute_process(
            COMMAND "${CMAKE_COMMAND}" -S "${_nogit}" -B "${_nogit}/out_nologo" -Wno-deprecated
            RESULT_VARIABLE _nologo_result OUTPUT_QUIET ERROR_VARIABLE _nologo_error)

        if (_nologo_result EQUAL 0)
            set(_ok TRUE)
        else()
            set(_ok FALSE)
            message(STATUS "       ${_nologo_error}")
        endif()
        expect("documentation generates with no PROJECT_LOGO" ${_ok})

        file(GLOB_RECURSE _nologo_html "${_nogit}/out_nologo/*.html")
        list(LENGTH _nologo_html _nologo_html_count)

        if (_nologo_html_count GREATER 0)
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("and doxygen still produced html without one" ${_ok})
    endif()
endif()

message(STATUS "")

if (_failures GREATER 0)
    message(FATAL_ERROR "${_failures} integration assertions failed")
endif()

message(STATUS "integration assertions passed")
