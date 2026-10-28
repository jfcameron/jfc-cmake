# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
run-on-android
--------------

.. code-block:: console

  cmake -P run-on-android.cmake -- <program> [<argument>...]

Pushes a program to the device adb is connected to, runs it there with the arguments, and exits with its
exit code. adb is found on the ``PATH`` or in the platform-tools of ``ANDROID_HOME`` or ``ANDROID_SDK_ROOT``.
#]=======================================================================]

set(_jfc_android_program "")
set(_jfc_android_arguments "")
set(_jfc_android_after_separator OFF)

math(EXPR _jfc_android_last "${CMAKE_ARGC} - 1")

foreach (_i RANGE ${_jfc_android_last})
    if (NOT _jfc_android_after_separator)
        if (CMAKE_ARGV${_i} STREQUAL "--")
            set(_jfc_android_after_separator ON)
        endif()
    elseif (_jfc_android_program STREQUAL "")
        set(_jfc_android_program "${CMAKE_ARGV${_i}}")
    else()
        string(REPLACE "'" "'\\''" _jfc_android_argument "${CMAKE_ARGV${_i}}")
        string(APPEND _jfc_android_arguments " '${_jfc_android_argument}'")
    endif()
endforeach()

if (_jfc_android_program STREQUAL "")
    message(FATAL_ERROR "run-on-android.cmake: usage: cmake -P run-on-android.cmake -- <program> [arguments...]")
endif()

find_program(_jfc_android_adb adb
    HINTS "$ENV{ANDROID_HOME}/platform-tools" "$ENV{ANDROID_SDK_ROOT}/platform-tools"
    NO_CACHE)

if (NOT _jfc_android_adb)
    message(FATAL_ERROR "run-on-android.cmake: no adb on the PATH or in ANDROID_HOME's platform-tools")
endif()

cmake_path(GET _jfc_android_program FILENAME _jfc_android_name)

set(_jfc_android_directory "/data/local/tmp/${_jfc_android_name}")

execute_process(
    COMMAND "${_jfc_android_adb}" shell "rm -rf ${_jfc_android_directory} && mkdir -p ${_jfc_android_directory}"
    COMMAND_ERROR_IS_FATAL ANY)

execute_process(
    COMMAND "${_jfc_android_adb}" push "${_jfc_android_program}" "${_jfc_android_directory}/${_jfc_android_name}"
    OUTPUT_QUIET
    COMMAND_ERROR_IS_FATAL ANY)

execute_process(
    COMMAND "${_jfc_android_adb}" shell
        "cd ${_jfc_android_directory} && chmod 755 ./${_jfc_android_name} && ./${_jfc_android_name}${_jfc_android_arguments}"
    RESULT_VARIABLE _jfc_android_result)

if (NOT _jfc_android_result EQUAL 0)
    if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.29 AND _jfc_android_result MATCHES "^[0-9]+$")
        cmake_language(EXIT ${_jfc_android_result})
    endif()

    message(FATAL_ERROR "run-on-android.cmake: ${_jfc_android_name} exited with ${_jfc_android_result}")
endif()
