# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

#================================================================================================
# Documentation: Doxygen
#================================================================================================
set(JFC_DOXY_CONFIG_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/doxy.config.in)

# TODO: verify, consider changing
function(jfc_generate_documentation_doxygen)
    set(TAG "documentation")

    jfc_require_program("doxygen")

    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            README_PATH
            PROJECT_LOGO
        REQUIRED_LISTS
            INCLUDE_DIRECTORIES
    )

    jfc_list_to_string(INPUT ${INCLUDE_DIRECTORIES}
        DELIMITER " "
        OUTPUT INCLUDE_DIRECTORIES)
    
    jfc_directory(basename ${CMAKE_CURRENT_LIST_DIR} CURRENT_DIR_BASENAME)

    # calculated
    jfc_git(COMMAND rev-parse HEAD 
        OUTPUT GIT_COMMIT_HASH)

    jfc_git(COMMAND rev-parse --show-toplevel 
        OUTPUT _path_to_repo_root)
    jfc_directory(basename ${_path_to_repo_root} GIT_REPO_NAME)

    # work
    configure_file(${JFC_DOXY_CONFIG_TEMPLATE_ABSOLUTE_PATH}
        ${CMAKE_BINARY_DIR}/${CURRENT_DIR_BASENAME}/doxy.config @ONLY)

    execute_process(COMMAND ${DOXYGEN} "${CMAKE_BINARY_DIR}/${CURRENT_DIR_BASENAME}/doxy.config"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        RESULT_VARIABLE DOXYGEN_RETURN_VALUE
        OUTPUT_VARIABLE DOXYGEN_ERRORS)

    if (DOXYGEN_RETURN_VALUE)
        jfc_log(FATAL_ERROR ${TAG} "Doxygen failed: ${DOXYGEN_ERRORS}")
    endif()
        
    file(REMOVE "${CMAKE_CURRENT_SOURCE_DIR}/${DOXY_CONFIG_FILENAME}")
endfunction()