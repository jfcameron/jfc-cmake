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

set(_siblings "${CMAKE_CURRENT_BINARY_DIR}/sibling_probes")

foreach (_sibling first second)
    file(WRITE "${_siblings}/${_sibling}/CMakeLists.txt"
        "jfc_add_tests(C++_STANDARD 20 TEST_SOURCE_FILES \"${CMAKE_CURRENT_LIST_DIR}/test/probe_test.cpp\" LIBRARIES probe)\n"
        "set(JFC_SIBLING_${_sibling} \"\${JFC_TEST_TARGET}\" PARENT_SCOPE)\n")

    add_subdirectory("${_siblings}/${_sibling}" "${_siblings}/${_sibling}_out")
endforeach()

if (TARGET "${JFC_SIBLING_first}" AND TARGET "${JFC_SIBLING_second}"
    AND NOT JFC_SIBLING_first STREQUAL JFC_SIBLING_second)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("two directories of one project make differently named test targets (${JFC_SIBLING_first}, ${JFC_SIBLING_second})" ${_ok})

jfc_add_tests(
    C++_STANDARD 20

    TEST_SOURCE_FILES
        "${CMAKE_CURRENT_LIST_DIR}/test/probe_test.cpp"

    LIBRARIES
        probe)

if (TARGET "${JFC_TEST_TARGET}" AND NOT JFC_TEST_TARGET STREQUAL JFC_SIBLING_second)
    set(_ok TRUE)
else()
    set(_ok FALSE)
endif()
expect("and a test target made after them counts on from theirs (${JFC_TEST_TARGET})" ${_ok})

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

message(STATUS "jfc_publish")

# built: a little C program, published, with a file of its project's own and a licence to notice; it loads a shared
# library of the project's, which the folder has to carry: on Windows from a directory of its own, found by
# LIBRARY_DIRECTORIES (unless UNFOUND). Each case configures it again and publishes it
set(_published "${CMAKE_CURRENT_BINARY_DIR}/publish_probe")

file(WRITE "${_published}/greeting.c"
    "#ifdef _WIN32\n"
    "__declspec(dllexport)\n"
    "#endif\n"
    "const char *greeting(void) { return \"probe ran\"; }\n")
file(WRITE "${_published}/probe.c"
    "#include <stdio.h>\n"
    "const char *greeting(void);\n"
    "int main(int argc, char **argv) {\n"
    "    if (argc > 1 && argv[1][0] == 'f') return 3;\n"
    "    puts(greeting());\n"
    "    return 0;\n"
    "}\n")
file(WRITE "${_published}/data.txt" "a project's own file\n")
file(WRITE "${_published}/extern/thing/LICENSE" "The thing licence, word for word.\n")
file(WRITE "${_published}/extern/thing/tests/LICENSE" "A test's licence, never noticed.\n")
file(WRITE "${_published}/check.cmake" "file(WRITE \"\${MARKER}\" \"\${unpacked}\")\n")
file(WRITE "${_published}/CMakeLists.txt"
    "cmake_minimum_required(VERSION 3.21)\n"
    "project(publish_probe C)\n"
    "include(\"${CMAKE_CURRENT_LIST_DIR}/../../jfclib.cmake\")\n"
    "set(_asked \"\")\n"
    "if (CMAKE_SYSTEM_NAME STREQUAL \"Linux\" OR WIN32)\n"
    "    add_library(greeting SHARED greeting.c)\n"
    "else()\n"
    "    add_library(greeting STATIC greeting.c)\n"
    "endif()\n"
    "if (WIN32)\n"
    "    set_target_properties(greeting PROPERTIES RUNTIME_OUTPUT_DIRECTORY \"$<1:\${CMAKE_BINARY_DIR}/elsewhere>\")\n"
    "    if (NOT UNFOUND)\n"
    "        list(APPEND _asked LIBRARY_DIRECTORIES \"\${CMAKE_BINARY_DIR}/elsewhere\")\n"
    "    endif()\n"
    "endif()\n"
    "add_executable(probe probe.c)\n"
    "target_link_libraries(probe PRIVATE greeting)\n"
    "install(FILES data.txt DESTINATION . COMPONENT probe)\n"
    "if (SAYS)\n"
    "    list(APPEND _asked RUN_SAYS \"\${SAYS}\")\n"
    "endif()\n"
    "if (FLOOR)\n"
    "    list(APPEND _asked GLIBC \"\${FLOOR}\")\n"
    "endif()\n"
    "jfc_publish(NAME probe VERSION 1.2 PLATFORM here PROGRAMS probe RUN \${RUN} \${_asked}\n"
    "    NOTICES \"\${CMAKE_CURRENT_SOURCE_DIR}/extern\" CHECK check.cmake CHECK_DEFINITIONS \"MARKER=\${MARKER}\")\n")

set(_marker "${_published}/checked")

# configures and publishes it: RUN, RUN_SAYS and GLIBC as given, and UNFOUND if a fourth is. The result, and what was
# said
function(_publish_probe aRun aSays aFloor)
    file(REMOVE "${_marker}")

    # built as this is: for another machine too, if this is
    set(_as_this "")

    foreach (passed CMAKE_TOOLCHAIN_FILE JFC_CROSS_TRIPLE)
        if (DEFINED ${passed})
            list(APPEND _as_this "-D${passed}=${${passed}}")
        endif()
    endforeach()

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S "${_published}" -B "${_published}/out" -Wno-deprecated ${_as_this}
            -DCMAKE_BUILD_TYPE=Release "-DRUN=${aRun}" "-DSAYS=${aSays}" "-DFLOOR=${aFloor}" "-DUNFOUND=${ARGV3}" "-DMARKER=${_marker}"
        RESULT_VARIABLE _configured OUTPUT_VARIABLE _said ERROR_VARIABLE _said)

    if (_configured EQUAL 0)
        execute_process(COMMAND "${CMAKE_COMMAND}" --build "${_published}/out" --target probe_publish --config Release
            RESULT_VARIABLE _configured OUTPUT_VARIABLE _said ERROR_VARIABLE _said)
    endif()

    set(_publish_result "${_configured}" PARENT_SCOPE)
    set(_publish_said "${_said}" PARENT_SCOPE)
endfunction()

if (CMAKE_CROSSCOMPILING AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    _publish_probe("probe" "" "")

    if (NOT _publish_result EQUAL 0 AND _publish_said MATCHES "not cross built")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("a cross built Linux program is refused, as this machine can't run it" ${_ok})
elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux" OR WIN32)
    _publish_probe("probe" "probe ran" "")

    if (_publish_result EQUAL 0)
        set(_ok TRUE)
    else()
        set(_ok FALSE)
        message(STATUS "       ${_publish_said}")
    endif()
    expect("a program is published, its zip checked, and run from it" ${_ok})

    set(_zip "${_published}/out/publish/probe-1.2-here.zip")

    if (EXISTS "${_zip}")
        file(ARCHIVE_EXTRACT INPUT "${_zip}" DESTINATION "${_published}/unzipped")
        set(_folder "${_published}/unzipped/probe-1.2-here")
        file(GLOB_RECURSE _carried RELATIVE "${_folder}" "${_folder}/*")
    else()
        set(_carried "")
    endif()

    if (("probe" IN_LIST _carried OR "probe.exe" IN_LIST _carried) AND "data.txt" IN_LIST _carried
            AND "THIRD_PARTY_NOTICES.txt" IN_LIST _carried)
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("its folder, named for it, has the program, the project's own file and the notices (${_carried})" ${_ok})

    if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
        if (_carried MATCHES "lib/libgreeting\\.so")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("on Linux, the shared library it loads is carried in lib/" ${_ok})
    else()
        if (_carried MATCHES "(^|;)greeting\\.dll(;|$)")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("on Windows, the DLL it loads, from LIBRARY_DIRECTORIES, is beside it" ${_ok})
    endif()

    if (EXISTS "${_folder}/THIRD_PARTY_NOTICES.txt")
        file(READ "${_folder}/THIRD_PARTY_NOTICES.txt" _notices)
    else()
        set(_notices "")
    endif()

    if (_notices MATCHES "The thing licence, word for word." AND _notices MATCHES "extern/thing" AND NOT _notices MATCHES "A test's")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("the notices have each licence with where it came from, and none of a test's" ${_ok})

    if (EXISTS "${_marker}")
        file(READ "${_marker}" _checked_in)
    else()
        set(_checked_in "")
    endif()

    if (_checked_in MATCHES "probe-1\\.2-here$")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("the project's own check runs, on the unpacked folder, with its definitions" ${_ok})

    _publish_probe("probe;fail" "" "")

    if (NOT _publish_result EQUAL 0 AND _publish_said MATCHES "didn't run from the zip")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("a program that fails from the zip fails the publish" ${_ok})

    _publish_probe("probe" "something else" "")

    if (NOT _publish_result EQUAL 0 AND _publish_said MATCHES "didn't say something else")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("and one that doesn't say what it should" ${_ok})

    if (WIN32)
        _publish_probe("probe" "" "" ON)

        if (NOT _publish_result EQUAL 0 AND _publish_said MATCHES "greeting\\.dll \\(probe\\.exe\\)")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("on Windows, a DLL found nowhere it's looked for fails the publish" ${_ok})
    endif()

    if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
        _publish_probe("probe" "" "2.0")

        if (NOT _publish_result EQUAL 0 AND _publish_said MATCHES "newer than glibc 2.0")
            set(_ok TRUE)
        else()
            set(_ok FALSE)
        endif()
        expect("on Linux, a program asking for a newer glibc than the floor fails it" ${_ok})

        _publish_probe("probe" "" "99")

        if (_publish_result EQUAL 0)
            set(_ok TRUE)
        else()
            set(_ok FALSE)
            message(STATUS "       ${_publish_said}")
        endif()
        expect("and with a floor it's within, it publishes" ${_ok})
    endif()
else()
    _publish_probe("probe" "" "")

    if (NOT _publish_result EQUAL 0 AND _publish_said MATCHES "programs are published for Linux and Windows")
        set(_ok TRUE)
    else()
        set(_ok FALSE)
    endif()
    expect("programs are refused where they aren't published (${CMAKE_SYSTEM_NAME})" ${_ok})
endif()

message(STATUS "")

if (_failures GREATER 0)
    message(FATAL_ERROR "${_failures} integration assertions failed")
endif()

message(STATUS "integration assertions passed")

