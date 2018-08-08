# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

#
# namespace for directory manipulation
# contained commands are selected via value of ARGV0
# e.g: jfc_directory(basename "/the/path/to/dir" currentdirectorybasename)
#
function(jfc_directory)
    set(TAG "directory")

    #
    # given a directory path @aPath, writes the name of the current directory to identifier with name @aOutput
    # (think: basename BSD utility)
    # eg:
    # jfc_directory(basename "/path/to/mydirectory" output)
    # message(STATUS "${output}")
    # result:
    # mydirectory
    #
    macro(_basename aPath aOutput)
        set(TAG "basename")

        string(FIND ${aPath} "/" _i REVERSE) # There maybe a posix assumption here!

        if (_i EQUAL -1)
            jfc_log(FATAL_ERROR ${TAG} "Path is malformed. Could not determine basename")
        endif()

        math(EXPR _i "${_i}+1")

        string(SUBSTRING ${aPath} ${_i} -1 ${aOutput})

        set (${aOutput} ${${aOutput}} PARENT_SCOPE)
    endmacro()

    if (ARGN LESS_EQUAL 0)
        jfc_log(FATAL_ERROR ${TAG} "requires at least one param to determine command to run")
    endif()

    list(REMOVE_AT ARGV 0)

    string(TOLOWER "${ARGV0}" ARGV0)

    if ("${ARGV0}" STREQUAL "basename")
        _basename(${ARGV})
    endif()
endfunction()
