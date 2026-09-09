# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

function(jfc_git)
    set(TAG "git")

    find_program(GIT_EXECUTABLE git REQUIRED)

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

    execute_process(COMMAND "${GIT_EXECUTABLE}" ${COMMAND}
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
