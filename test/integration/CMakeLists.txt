# © Joseph Cameron - MIT License
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

get_target_property(_test_sources ${JFC_TEST_TARGET} SOURCES)

if (TARGET jfc_catch_main AND _test_links MATCHES "jfc_catch_main" AND NOT _test_sources MATCHES "catchconfig")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("catch2's main is a library the test target links, not a source compiled into it" ${_ok})

get_target_property(_test_options ${JFC_TEST_TARGET} COMPILE_OPTIONS)

if (_test_options MATCHES "-O0")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("test sources are compiled unoptimised" ${_ok})

get_target_property(_test_pch ${JFC_TEST_TARGET} PRECOMPILE_HEADERS)

if (_test_pch MATCHES "jfc/catch.hpp")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("catch2's header is precompiled, once a test target" ${_ok})

if (_test_options MATCHES "fno-pch-timestamp")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("on clang it is built without a timestamp, the same each time" ${_ok})

set(_first_test_target "${JFC_TEST_TARGET}")

jfc_add_tests(
    C++_STANDARD 17

    TEST_SOURCE_FILES
        "${CMAKE_CURRENT_LIST_DIR}/test/probe_test.cpp"

    LIBRARIES
        probe)

get_target_property(_second_links ${JFC_TEST_TARGET} LINK_LIBRARIES)
get_target_property(_main_sources jfc_catch_main SOURCES)
list(LENGTH _main_sources _main_source_count)

if (NOT JFC_TEST_TARGET STREQUAL _first_test_target AND _second_links MATCHES "jfc_catch_main" AND _main_source_count EQUAL 1)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("a second test target links the same main, compiled once" ${_ok})

message(STATUS "jfc_check_headers")

jfc_check_headers(probe)

if (TARGET probe_header_check)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("a header check is made, named after its target" ${_ok})

get_target_property(_check_sources probe_header_check SOURCES)
list(LENGTH _check_sources _check_source_count)

if (_check_source_count EQUAL 1)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("a source for each public header (${_check_source_count})" ${_ok})

if (_check_source_count EQUAL 1)
    file(READ "${_check_sources}" _check_text)
else()
    set(_check_text "")
endif()

if (_check_text STREQUAL "#include <probe/probe.h>\n")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("each includes its header by its public path, and nothing else" ${_ok})

get_target_property(_check_links probe_header_check LINK_LIBRARIES)

if (_check_links MATCHES "probe")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("it links the target, so it compiles as a consumer would" ${_ok})

# built: a library whose own sources include <string> before a header that uses it without
# including it. The library builds; its header check doesn't, until that header is excluded
set(_leaning "${CMAKE_CURRENT_BINARY_DIR}/leaning_probe")

file(WRITE "${_leaning}/include/leaning/fine.h" "#include <string>\ninline std::string fine() { return \"fine\"; }\n")
file(WRITE "${_leaning}/include/leaning/leaning.h" "inline std::string leaning() { return \"leaning\"; }\n")
file(WRITE "${_leaning}/src/leaning.cpp" "#include <string>\n#include <leaning/leaning.h>\n#include <leaning/fine.h>\n")
file(WRITE "${_leaning}/CMakeLists.txt"
    "cmake_minimum_required(VERSION 3.21)\n"
    "project(leaning_probe CXX)\n"
    "include(\"${CMAKE_CURRENT_LIST_DIR}/../../jfclib.cmake\")\n"
    "add_library(leaning STATIC src/leaning.cpp)\n"
    "target_include_directories(leaning PUBLIC \"$<BUILD_INTERFACE:\${CMAKE_CURRENT_SOURCE_DIR}/include>\")\n"
    "if (EXCLUDING)\n"
    "    jfc_check_headers(leaning EXCLUDE leaning/leaning.h)\n"
    "else()\n"
    "    jfc_check_headers(leaning)\n"
    "endif()\n")

foreach (_excluding OFF ON)
    set(_out "${_leaning}/out_${_excluding}")

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S "${_leaning}" -B "${_out}" -DEXCLUDING=${_excluding} -Wno-deprecated
        RESULT_VARIABLE _leaning_configured OUTPUT_QUIET ERROR_VARIABLE _leaning_error)

    if (NOT _leaning_configured EQUAL 0)
        message(STATUS "       ${_leaning_error}")
    endif()

    execute_process(COMMAND "${CMAKE_COMMAND}" --build "${_out}" --target leaning
        RESULT_VARIABLE _library_built OUTPUT_QUIET ERROR_QUIET)

    execute_process(COMMAND "${CMAKE_COMMAND}" --build "${_out}" --target leaning_header_check
        RESULT_VARIABLE _check_built OUTPUT_VARIABLE _check_output ERROR_VARIABLE _check_output)

    if (_excluding)
        if (_leaning_configured EQUAL 0 AND _check_built EQUAL 0)
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("with the leaning header excluded, the check builds" ${_ok})
    else()
        if (_leaning_configured EQUAL 0 AND _library_built EQUAL 0)
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("a library whose header leans on its includer builds" ${_ok})

        if (NOT _check_built EQUAL 0 AND _check_output MATCHES "leaning\\.h")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("but its header check doesn't, and says which header" ${_ok})
    endif()
endforeach()

execute_process(
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_LIST_DIR}/../fixtures/check_headers_no_target.cmake"
    RESULT_VARIABLE _no_target OUTPUT_QUIET ERROR_VARIABLE _no_target_error)

if (NOT _no_target EQUAL 0 AND _no_target_error MATCHES "there is no target nothing")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("a target that isn't there is refused, by name" ${_ok})

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

file(TIMESTAMP "${_buildinfo}" _written "%s")
execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 1)
jfc_generate_build_info(INCLUDE_PATH gdk/probe)
file(TIMESTAMP "${_buildinfo}" _rewritten "%s")

if (_written STREQUAL _rewritten)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("generated again with nothing changed, it is not written again" ${_ok})

jfc_generate_build_info()

if (EXISTS "${PROJECT_BINARY_DIR}/generated_include/jfc/cmake/build_info.h")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("with no arguments the path is derived from the repository name (jfc-cmake -> jfc/cmake)" ${_ok})

add_subdirectory(hyphen)

expect("a hyphenated path segment yields compilable identifiers" ${JFC_HYPHEN_PROBE_OK})

message(STATUS "jfc_embed_file")

set(_embedded "${PROJECT_BINARY_DIR}/generated/embedded_probe.h")

jfc_embed_file(EMBEDDED_PROBE "${CMAKE_CURRENT_LIST_DIR}/src/probe.cpp" "${_embedded}")

if (EXISTS "${_embedded}")
    file(READ "${_embedded}" _embedded_text)
else()
    set(_embedded_text "")
endif()

if (_embedded_text MATCHES "static const unsigned char EMBEDDED_PROBE\\[\\] = {0x")
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("a file is embedded as an array of its bytes" ${_ok})

file(TIMESTAMP "${_embedded}" _written "%s")
execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 1)
jfc_embed_file(EMBEDDED_PROBE "${CMAKE_CURRENT_LIST_DIR}/src/probe.cpp" "${_embedded}")
file(TIMESTAMP "${_embedded}" _rewritten "%s")

if (_written STREQUAL _rewritten)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("embedded again unchanged, it is not written again" ${_ok})

message(STATUS "jfc_generate_documentation_doxygen")

find_program(DOXYGEN_EXECUTABLE doxygen)

if (NOT DOXYGEN_EXECUTABLE)
    message(STATUS "  skip doxygen is not installed")
else()
    jfc_generate_documentation_doxygen(
        README_PATH      "${CMAKE_CURRENT_LIST_DIR}/README.md"
        OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/any_name"
        PROJECT_LOGO     "${CMAKE_CURRENT_LIST_DIR}/logo.png"
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_LIST_DIR}/include")

    if (EXISTS "${CMAKE_CURRENT_BINARY_DIR}/doxy.config")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("the doxy config is written to the calling directory's build directory" ${_ok})

    if (_ok)
        file(READ "${CMAKE_CURRENT_BINARY_DIR}/doxy.config" _doxy)
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

    if (EXISTS "${CMAKE_BINARY_DIR}/any_name/index.html")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("the html is written to OUTPUT_DIRECTORY" ${_ok})

    if (NOT EXISTS "${CMAKE_BINARY_DIR}/any_name/doxy.config")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("OUTPUT_DIRECTORY holds nothing but the site" ${_ok})

    set(_nogit "${CMAKE_CURRENT_BINARY_DIR}/nogit_probe")

    execute_process(COMMAND git rev-parse --show-toplevel
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        RESULT_VARIABLE _enclosing_repo OUTPUT_QUIET ERROR_QUIET)

    if (_enclosing_repo EQUAL 0)
        message(STATUS "  skip the binary directory is inside a git repository")
    else()
        file(MAKE_DIRECTORY "${_nogit}/include")
        file(WRITE "${_nogit}/README.md" "# probe\n\ntext\n")
        file(WRITE "${_nogit}/include/thing.h" "namespace probe { /// doc\nstruct thing { int x; };\n}\n")
        file(WRITE "${_nogit}/logo.png" "")
        file(WRITE "${_nogit}/CMakeLists.txt"
            "cmake_minimum_required(VERSION 3.21)\n"
            "project(tarball_probe)\n"
            "include(\"${CMAKE_CURRENT_LIST_DIR}/../../jfclib.cmake\")\n"
            "jfc_generate_documentation_doxygen(\n"
            "    PROJECT_LOGO \"\${CMAKE_CURRENT_LIST_DIR}/logo.png\"\n"
            "    README_PATH README.md\n"
            "    OUTPUT_DIRECTORY site\n"
            "    INCLUDE_DIRECTORIES include/)\n")

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

        if (EXISTS "${_nogit}/out/site/index.html" AND NOT EXISTS "${_nogit}/site")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("a relative OUTPUT_DIRECTORY is in the build, not the source" ${_ok})

        file(READ "${_nogit}/out/doxy.config" _nogit_doxy)

        if (_nogit_doxy MATCHES "PROJECT_NAME[ \t]*=[ \t]*tarball_probe")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("with no repository the project name stands in for the repo name" ${_ok})

        file(WRITE "${_nogit}/CMakeLists.txt"
            "cmake_minimum_required(VERSION 3.21)\n"
            "project(tarball_probe)\n"
            "include(\"${CMAKE_CURRENT_LIST_DIR}/../../jfclib.cmake\")\n"
            "jfc_generate_documentation_doxygen(\n"
            "    README_PATH README.md\n"
            "    OUTPUT_DIRECTORY site\n"
            "    INCLUDE_DIRECTORIES include/)\n")

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

        file(WRITE "${_nogit}/CMakeLists.txt"
            "cmake_minimum_required(VERSION 3.21)\n"
            "project(tarball_probe)\n"
            "include(\"${CMAKE_CURRENT_LIST_DIR}/../../jfclib.cmake\")\n"
            "jfc_generate_documentation_doxygen(\n"
            "    README_PATH README.md\n"
            "    INCLUDE_DIRECTORIES include/)\n")

        execute_process(
            COMMAND "${CMAKE_COMMAND}" -S "${_nogit}" -B "${_nogit}/out_nowhere" -Wno-deprecated
            RESULT_VARIABLE _nowhere_result OUTPUT_QUIET ERROR_VARIABLE _nowhere_error)

        if (NOT _nowhere_result EQUAL 0 AND _nowhere_error MATCHES "\"OUTPUT_DIRECTORY\" is missing")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
            message(STATUS "       ${_nowhere_error}")
        endif()
        expect("OUTPUT_DIRECTORY is required, so the module picks no place itself" ${_ok})
    endif()
endif()

message(STATUS "")

if (_failures GREATER 0)
    message(FATAL_ERROR "${_failures} integration assertions failed")
endif()

message(STATUS "integration assertions passed")

