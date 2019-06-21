# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

# Call git commands, throwing if there is an error
# @COMMAND the command to run e.g: status
# @OUTPUT the symbol this function will assign the standard out result of the git command to
# example usage:
# jfc_git(COMMAND rev-parse HEAD
#   OUTPUT theCurrentCommitHash)
#
# message(STATUS "${theCurrentCommitHash}") # the current commit's hash
#
function(jfc_git)
    set(TAG "git")

    jfc_require_program("git")

    jfc_parse_arguments(${ARGV}
        REQUIRED_LISTS
            COMMAND
        SINGLE_VALUES
            OUTPUT
            WORKING_DIRECTORY
    )

    if (NOT WORKING_DIRECTORY)
        set(WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    execute_process(COMMAND git ${COMMAND}
        WORKING_DIRECTORY ${WORKING_DIRECTORY}
        RESULT_VARIABLE _return_value
        OUTPUT_VARIABLE _output_value
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    if (NOT _return_value EQUAL 0)
        string(REPLACE ";" " " aGitCommand "${COMMAND}")

        jfc_log(FATAL_ERROR ${TAG} "the command \"git ${aGitCommand}\" failed with return value of \"${_return_value}\"")
    endif()

    set(${OUTPUT} "${_output_value}" PARENT_SCOPE)
endfunction()
