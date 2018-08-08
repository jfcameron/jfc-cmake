# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

include("${CMAKE_CURRENT_LIST_DIR}/modules/add_submodule_dependencies/add_submodule_dependencies.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/debug/debug.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/directories/directories.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/emscripten_generate_index_html/emscripten_generate_index_html.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_buildinfo/generate_buildinfo.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_readme_md/generate_readme_md.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/git/git.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/parse_arguments/parse_arguments.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/project/project.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/require_program/require_program.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/vulkan_compile_GLSL_to_SPIR-V/vulkan_compile_GLSL_to_SPIR-V.cmake")

#================================================================================================
# Unit tests
#================================================================================================
# @TEST_SOURCE_LIST
# @C++_STANDARD required iso langauge standard for C++ 
# @C_STANDARD required iso language standard for C
function(jfc_add_tests)
    set(TAG "TEST")

    jfc_log(STATUS ${TAG} "this is not completed at all")

    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            C++_STANDARD
            C_STANDARD
        REQUIRED_LISTS
            TEST_SOURCE_LIST
    )

    # get catch2 -> this is dictated by jfccmake, not up to the using project
    # generate the tests.cpp file somehwere in bin dir by grabbing and populating tests.cpp.in in jfccmake module
endfunction()

#================================================================================================
# Documentation: Doxygen
#================================================================================================
# TODO: verify, consider changing
function(jfc_generate_documentation_doxygen)
    set(TAG "documentation")

    find_program(DOXYGEN doxygen)

    if(NOT DOXYGEN)
        jfc_log(FATAL_ERROR ${TAG} "doxygen not found! It is required to generate documentation.")
    else()
        set(DOXY_CONFIG_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
        set(DOXY_RESOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/resources")
        set(DOXY_CONFIG_FILENAME "doxy.config")

        jfc_directory(basename ${CMAKE_CURRENT_LIST_DIR} CURRENT_DIR_BASENAME)

        configure_file(${DOXY_CONFIG_DIR}/${DOXY_CONFIG_FILENAME}.in 
            ${CMAKE_CURRENT_SOURCE_DIR}/${DOXY_CONFIG_FILENAME} @ONLY)

        execute_process(COMMAND ${DOXYGEN} ${DOXY_CONFIG_FILENAME}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            RESULT_VARIABLE DOXYGEN_RETURN_VALUE
            OUTPUT_VARIABLE DOXYGEN_ERRORS)

        if (DOXYGEN_RETURN_VALUE)
            jfc_log(FATAL_ERROR ${TAG} "Doxygen failed: ${DOXYGEN_ERRORS}")
        else()
            jfc_log(STATUS ${TAG} "Doxygen successfully completed")
        endif()
        
        file(REMOVE "${CMAKE_CURRENT_SOURCE_DIR}/${DOXY_CONFIG_FILENAME}")
    endif()
endfunction()

#jfc_generate_documentation_doxygen()

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
