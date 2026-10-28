# © Joseph Cameron - MIT License
#
# Tests for toolchains/toolchain-linux-cross.cmake
#
#     cmake -P test/toolchain_linux_cross_test.cmake
#
cmake_minimum_required(VERSION 3.21)

if (CMAKE_HOST_WIN32)
    message(STATUS "skip toolchain-linux-cross.cmake is for unix hosts")
    return()
endif()

set(_toolchain "${CMAKE_CURRENT_LIST_DIR}/../toolchains/toolchain-linux-cross.cmake")
set(_work "${CMAKE_CURRENT_BINARY_DIR}/toolchain_linux_cross_test")
set(_compilers "${_work}/compilers")
set(_qemus "${_work}/qemus")
set(_probe "${_work}/probe")

file(REMOVE_RECURSE "${_work}")

set(_failures 0)

macro(expect_equal aDescription aActual aExpected)
    if ("${aActual}" STREQUAL "${aExpected}")
        message(STATUS "  ok   ${aDescription}")
    else()
        message(SEND_ERROR "  FAIL ${aDescription}\n       expected [${aExpected}]\n       actual   [${aActual}]")
        math(EXPR _failures "${_failures}+1")
    endif()
endmacro()

function(_executable aPath aText)
    file(WRITE "${aPath}" "#!/bin/sh\n${aText}\n")
    file(CHMOD "${aPath}" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)
endfunction()

foreach (_triple arm-fake-linux-gnueabihf powerpc64le-fake-linux-gnu i686-fake-linux-gnu x86_64-fake-linux-gnu
        nosucharch-fake-linux-gnu)
    _executable("${_compilers}/${_triple}-gcc" "exec cc \"$@\"")
    _executable("${_compilers}/${_triple}-g++" "exec c++ \"$@\"")
endforeach()

foreach (_qemu qemu-arm qemu-ppc64le qemu-i386 qemu-x86_64 qemu-custom)
    _executable("${_qemus}/${_qemu}"
        "[ \"$1\" = -L ] || exit 99\necho \"$2\" > \"${_work}/${_qemu}.ran\"\nshift 2\nexec \"$@\"")
endforeach()

file(WRITE "${_probe}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.21)
project(cross_probe CXX)
file(WRITE "${CMAKE_BINARY_DIR}/found.cmake"
    "set(EMULATOR \"${CMAKE_CROSSCOMPILING_EMULATOR}\")\n"
    "set(PROCESSOR \"${CMAKE_SYSTEM_PROCESSOR}\")\n"
    "set(ROOT \"${CMAKE_FIND_ROOT_PATH}\")\n")
enable_testing()
file(WRITE "${CMAKE_BINARY_DIR}/probe.cpp" "int main() { return 0; }\n")
add_executable(probe "${CMAKE_BINARY_DIR}/probe.cpp")
add_test(NAME probe COMMAND probe)
]=])

function(_configure aName aWithQemus)
    set(_path "${_compilers}")

    if (aWithQemus)
        string(APPEND _path ":${_qemus}")
    endif()

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E env "PATH=${_path}:$ENV{PATH}"
            "${CMAKE_COMMAND}" -S "${_probe}" -B "${_work}/${aName}" "--toolchain" "${_toolchain}" ${ARGN}
        RESULT_VARIABLE _result OUTPUT_VARIABLE _output ERROR_VARIABLE _output)

    set(EMULATOR "")
    set(PROCESSOR "")
    set(ROOT "")

    if (EXISTS "${_work}/${aName}/found.cmake")
        include("${_work}/${aName}/found.cmake")
    endif()

    set(RESULT "${_result}" PARENT_SCOPE)
    set(OUTPUT "${_output}" PARENT_SCOPE)
    set(EMULATOR "${EMULATOR}" PARENT_SCOPE)
    set(PROCESSOR "${PROCESSOR}" PARENT_SCOPE)
    set(ROOT "${ROOT}" PARENT_SCOPE)
endfunction()

message(STATUS "toolchain-linux-cross.cmake")

_configure(arm TRUE -DJFC_CROSS_TRIPLE=arm-fake-linux-gnueabihf)
expect_equal("it configures for a triple" "${RESULT}" "0")
expect_equal("the processor is the triple's architecture" "${PROCESSOR}" "arm")
expect_equal("the target's libraries are in /usr/<triple>" "${ROOT}" "/usr/arm-fake-linux-gnueabihf")
expect_equal("the tests run under the qemu named for the architecture" "${EMULATOR}"
    "${_qemus}/qemu-arm;-L;/usr/arm-fake-linux-gnueabihf")

_configure(ppc64le TRUE -DJFC_CROSS_TRIPLE=powerpc64le-fake-linux-gnu)
expect_equal("powerpc is qemu's ppc" "${EMULATOR}" "${_qemus}/qemu-ppc64le;-L;/usr/powerpc64le-fake-linux-gnu")

_configure(i686 TRUE -DJFC_CROSS_TRIPLE=i686-fake-linux-gnu)
expect_equal("i686 is qemu's i386" "${EMULATOR}" "${_qemus}/qemu-i386;-L;/usr/i686-fake-linux-gnu")

_configure(chosen TRUE -DJFC_CROSS_TRIPLE=x86_64-fake-linux-gnu -DJFC_CROSS_SYSROOT=/opt/sysroot
    -DJFC_CROSS_QEMU=qemu-custom)
expect_equal("a sysroot can be given" "${ROOT}" "/opt/sysroot")
expect_equal("and a qemu, which runs against it" "${EMULATOR}" "${_qemus}/qemu-custom;-L;/opt/sysroot")

_configure(no_qemu FALSE -DJFC_CROSS_TRIPLE=nosucharch-fake-linux-gnu)
expect_equal("without qemu it still configures" "${RESULT}" "0")
expect_equal("with no emulator" "${EMULATOR}" "")

if (OUTPUT MATCHES "no qemu-nosucharch, so the tests are built but cannot run here")
    set(_said TRUE)
else()
    set(_said FALSE)
endif()
expect_equal("and says so" "${_said}" "TRUE")

_configure(no_triple TRUE)

if (NOT RESULT EQUAL 0 AND OUTPUT MATCHES "set JFC_CROSS_TRIPLE")
    set(_refused TRUE)
else()
    set(_refused FALSE)
endif()
expect_equal("with no triple it refuses, and says what to set" "${_refused}" "TRUE")

_configure(run TRUE -DJFC_CROSS_TRIPLE=x86_64-fake-linux-gnu)

execute_process(COMMAND "${CMAKE_COMMAND}" -E env "PATH=${_compilers}:${_qemus}:$ENV{PATH}"
    "${CMAKE_COMMAND}" --build "${_work}/run" RESULT_VARIABLE _built OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${_work}/run" RESULT_VARIABLE _tested OUTPUT_QUIET ERROR_QUIET)

if (EXISTS "${_work}/qemu-x86_64.ran")
    file(STRINGS "${_work}/qemu-x86_64.ran" _ran_against)
else()
    set(_ran_against "")
endif()
expect_equal("ctest runs a test under qemu" "${_built} ${_tested}" "0 0")
expect_equal("against the sysroot" "${_ran_against}" "/usr/x86_64-fake-linux-gnu")

file(REMOVE_RECURSE "${_work}")

if (_failures GREATER 0)
    message(FATAL_ERROR "${_failures} toolchain-linux-cross.cmake assertions failed")
endif()

message(STATUS "toolchain-linux-cross.cmake assertions passed")
