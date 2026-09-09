# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

set(JFC_BUILDINFO_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/buildinfo.h.in)

function(jfc_generate_cmake_header)
    string(RANDOM LENGTH 22 JFC_RANDOM_128BITS)

    execute_process(COMMAND git rev-parse HEAD 
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
        OUTPUT_VARIABLE JFC_GIT_COMMIT_HASH OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    execute_process(COMMAND git log -1 --format=%cd --date=local HEAD 
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
        OUTPUT_VARIABLE JFC_GIT_COMMIT_DATE OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    execute_process(COMMAND git remote get-url origin
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
        OUTPUT_VARIABLE JFC_GIT_REMOTE_URL OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    configure_file(${JFC_BUILDINFO_TEMPLATE_ABSOLUTE_PATH}
        ${PROJECT_BINARY_DIR}/generated_include/${PROJECT_NAME}/buildinfo.h @ONLY)
endfunction()
