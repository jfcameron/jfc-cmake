# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

set(JFC_DOXY_CONFIG_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/doxy.config.in)

function(jfc_generate_documentation_doxygen)
    find_program(DOXYGEN_EXECUTABLE doxygen REQUIRED)

    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            README_PATH
        REQUIRED_LISTS
            INCLUDE_DIRECTORIES
        SINGLE_VALUES
            PROJECT_LOGO
        LISTS
            EXCLUDE_DIRECTORIES
    )

    list(JOIN INCLUDE_DIRECTORIES " " INCLUDE_DIRECTORIES)

    list(JOIN EXCLUDE_DIRECTORIES " " EXCLUDE_DIRECTORIES)

    cmake_path(GET CMAKE_CURRENT_LIST_DIR FILENAME CURRENT_DIR_BASENAME)

    execute_process(COMMAND git rev-parse HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    execute_process(COMMAND git rev-parse --show-toplevel
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE _path_to_repo_root OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    if (_path_to_repo_root)
        cmake_path(GET _path_to_repo_root FILENAME GIT_REPO_NAME)
    else()
        set(GIT_REPO_NAME "${PROJECT_NAME}")
    endif()

    configure_file(${JFC_DOXY_CONFIG_TEMPLATE_ABSOLUTE_PATH}
        ${CMAKE_BINARY_DIR}/${CURRENT_DIR_BASENAME}/doxy.config @ONLY)

    execute_process(COMMAND "${DOXYGEN_EXECUTABLE}" "${CMAKE_BINARY_DIR}/${CURRENT_DIR_BASENAME}/doxy.config"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        RESULT_VARIABLE DOXYGEN_RETURN_VALUE
        OUTPUT_VARIABLE DOXYGEN_ERRORS)

    if (DOXYGEN_RETURN_VALUE)
        message(FATAL_ERROR "jfc_generate_documentation_doxygen: Doxygen failed: ${DOXYGEN_ERRORS}")
    endif()
        
    file(REMOVE "${CMAKE_CURRENT_SOURCE_DIR}/${DOXY_CONFIG_FILENAME}")
endfunction()

