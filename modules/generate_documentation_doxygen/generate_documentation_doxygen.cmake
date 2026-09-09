# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

set(JFC_DOXY_CONFIG_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/doxy.config.in)

function(jfc_generate_documentation_doxygen)
    set(TAG "documentation")

    find_program(DOXYGEN_EXECUTABLE doxygen REQUIRED)

    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            README_PATH
            PROJECT_LOGO
        REQUIRED_LISTS
            INCLUDE_DIRECTORIES
        LISTS
            EXCLUDE_DIRECTORIES
    )

    list(JOIN INCLUDE_DIRECTORIES " " INCLUDE_DIRECTORIES)

    list(JOIN EXCLUDE_DIRECTORIES " " EXCLUDE_DIRECTORIES)

    cmake_path(GET CMAKE_CURRENT_LIST_DIR FILENAME CURRENT_DIR_BASENAME)

    jfc_git(COMMAND rev-parse HEAD 
        OUTPUT GIT_COMMIT_HASH)

    jfc_git(COMMAND rev-parse --show-toplevel 
        OUTPUT _path_to_repo_root)
    cmake_path(GET _path_to_repo_root FILENAME GIT_REPO_NAME)

    configure_file(${JFC_DOXY_CONFIG_TEMPLATE_ABSOLUTE_PATH}
        ${CMAKE_BINARY_DIR}/${CURRENT_DIR_BASENAME}/doxy.config @ONLY)

    execute_process(COMMAND "${DOXYGEN_EXECUTABLE}" "${CMAKE_BINARY_DIR}/${CURRENT_DIR_BASENAME}/doxy.config"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        RESULT_VARIABLE DOXYGEN_RETURN_VALUE
        OUTPUT_VARIABLE DOXYGEN_ERRORS)

    if (DOXYGEN_RETURN_VALUE)
        jfc_log(FATAL_ERROR ${TAG} "Doxygen failed: ${DOXYGEN_ERRORS}")
    endif()
        
    file(REMOVE "${CMAKE_CURRENT_SOURCE_DIR}/${DOXY_CONFIG_FILENAME}")
endfunction()

