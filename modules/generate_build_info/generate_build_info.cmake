# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

set(JFC_BUILD_INFO_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/build_info.h.in)

function(jfc_generate_build_info)
    cmake_parse_arguments(PARSE_ARGV 0 _ARG "" "INCLUDE_PATH" "")

    set(JFC_BUILD_INFO_INCLUDE_PATH "${_ARG_INCLUDE_PATH}")

    if (NOT JFC_BUILD_INFO_INCLUDE_PATH)
        execute_process(COMMAND git rev-parse --show-toplevel
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            OUTPUT_VARIABLE _repo_root OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

        if (_repo_root)
            cmake_path(GET _repo_root FILENAME _repo_name)
        else()
            set(_repo_name "${PROJECT_NAME}")
        endif()

        if (_repo_name MATCHES "^([^-]+)-(.+)$")
            set(JFC_BUILD_INFO_INCLUDE_PATH "${CMAKE_MATCH_1}/${CMAKE_MATCH_2}")
        else()
            set(JFC_BUILD_INFO_INCLUDE_PATH "${_repo_name}")
        endif()
    endif()

    string(REPLACE "/" ";" _segments "${JFC_BUILD_INFO_INCLUDE_PATH}")

    set(_namespace_segments)
    foreach (_segment IN LISTS _segments)
        string(MAKE_C_IDENTIFIER "${_segment}" _segment)

        list(APPEND _namespace_segments "${_segment}")
    endforeach()

    list(APPEND _namespace_segments "build_info")

    list(JOIN _namespace_segments "::" JFC_BUILD_INFO_NAMESPACE)
    list(JOIN _namespace_segments "_" JFC_BUILD_INFO_GUARD)

    string(TOUPPER "${JFC_BUILD_INFO_GUARD}_H" JFC_BUILD_INFO_GUARD)

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

    configure_file(${JFC_BUILD_INFO_TEMPLATE_ABSOLUTE_PATH}
        ${PROJECT_BINARY_DIR}/generated_include/${JFC_BUILD_INFO_INCLUDE_PATH}/build_info.h @ONLY)
endfunction()
