# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

include("${CMAKE_CURRENT_LIST_DIR}/modules/debug/debug.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/modules/add_dependencies/add_dependencies.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/add_tests/add_tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/compiler_options/compiler_options.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/directories/directories.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/emscripten_generate_index_html/emscripten_generate_index_html.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_buildinfo/generate_buildinfo.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_documentation_doxygen/generate_documentation_doxygen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_readme_md/generate_readme_md.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/git/git.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/parse_arguments/parse_arguments.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/project/project.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/require_program/require_program.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/vulkan_compile_GLSL_to_SPIR-V/vulkan_compile_GLSL_to_SPIR-V.cmake")

#================================================================================================
# Utilities
#================================================================================================
# Convert a list to a string.
# @INPUT the list
# @OUTPUT the name of the output string
# @DELIMITER char|char sequence used to render the item delimiter (;)
function(jfc_list_to_string)
    jfc_parse_arguments(${ARGV}
        REQUIRED_LISTS
            INPUT
        REQUIRED_SINGLE_VALUES
            OUTPUT
            DELIMITER
    )

    set(_output)
    
    foreach(_item ${INPUT})
        string(CONCAT _output "${_output}" "${DELIMITER}" "${_item}")
    endforeach()

    set(${OUTPUT} ${_output} PARENT_SCOPE)
endfunction()

#[[
# TODO : This function has a logic error
# Convert a string to a list.
# @INPUT the string
# @OUTPUT the name of the output list
# @DELIMITER char|char sequence that separates each item in the string (e.g: , or ; etc)
function(jfc_string_to_list)
    jfc_parse_arguments(${ARGV}
        REQUIRED_LISTS
            INPUT
        REQUIRED_SINGLE_VALUES
            OUTPUT
            DELIMITER
    )

    set(_output)

    while(TRUE)
        string(FIND "${INPUT}" "${DELIMITER}" _i)

        if(${_i} LESS 0)
            break()
        endif()

        string(SUBSTRING "${INPUT}" 0 ${_i} _item)

        math(EXPR _i "${_i}+1")

        string(SUBSTRING "${INPUT}" ${_i} -1 INPUT)

        list(APPEND _output ${_item})
    endwhile()

    set(${OUTPUT} ${_output} PARENT_SCOPE)
endfunction()]]

#================================================================================================
# Formatting: uncrustify
#================================================================================================
# TODO: type list with default fallback
# TODO: where should the uncrustify settings come from? fallback + override?
function(jfc_format_code_uncrustify aDirectory)
    set(TAG "format")

    if (NOT IS_DIRECTORY ${aDirectory})
        jfc_log(FATAL_ERROR ${TAG} "${aDirectory} does not exist or is not a directory.")
    endif()

    set(FORMATTER_NAME "uncrustify")

    find_program(FORMATTER "${FORMATTER_NAME}")

    if(NOT FORMATTER)
        jfc_log(FATAL_ERROR ${TAG} "${FORMATTER_NAME} not found! It is required to format the source code.")
    else()
        file(GLOB_RECURSE JFC_SOURCES
            ${aDirectory}/*.h   ${aDirectory}/*.hpp
            ${aDirectory}/*.cpp ${aDirectory}/*.cxx
            ${aDirectory}/*.c)

    execute_process(COMMAND ${FORMATTER} files ${JFC_SOURCES} --no-backup -c ${CMAKE_SOURCE_DIR}/.uncrustify #-l CPP
        WORKING_DIRECTORY ${aDirectory}
        RESULT_VARIABLE FORMATTER_RETURN_VALUE
        OUTPUT_VARIABLE FORMATTER_ERRORS)
    endif()
endfunction()

#================================================================================================
# Formatting: Clang
#================================================================================================
# TODO: where should the clang settings come from? fallback + override?
function(jfc_format_code_clang) 
    set(TAG "format")

    jfc_require_program("uncrustify")

    jfc_log(STATUS ${TAG} "this is not completed at all")
endfunction()

#================================================================================================
# Resource loader
#================================================================================================
#
function(jfc_resource)
    jfc_log(FATAL_ERROR "blarblar" "resource must be implemented")

    #
    function(jfc_export_resource aResourceDirectory)
        set(TAG "Resource exporter")

        #[[if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${aResourceDirectory}" AND IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${aResourceDirectory}")
            jfc_log(STATUS ${TAG} "Exporting ${aResourceDirectory}")

            file(COPY "${aResourceDirectory}" 
                DESTINATION ${CMAKE_SOURCE_DIR}/build/)
        else()
            jfc_log(FATAL_ERROR ${TAG} "\"${aResourceDirectory}\" does not exist or is not a directory.")
        endif()]]

        jfc_log(FATAL_ERROR ${TAG} "This is not implemented.")
    endfunction()

    #
    function(jfc_compile_resources)
        jfc_parse_arguments(${ARGV}
            REQUIRED_LISTS
                FILES
        )

        set(TAG "resource compile")

        function(_compile_resource aFile)
            file(READ "${aFile}" bytes HEX)
    
            string(REGEX REPLACE "(..)" "0x\\1, " bytes "${bytes}")

            string(FIND "${bytes}" ", " _i REVERSE)

            string(SUBSTRING "${bytes}" 0 ${_i} bytes)
    
            message("${bytes}")
        endfunction()

        foreach(_file ${FILES})
            _compile_resource("${_file}")
        endforeach()

        jfc_log(FATAL_ERROR ${TAG} "This is not implemented.")
    endfunction()
endfunction()
