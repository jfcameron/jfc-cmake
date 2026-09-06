# © Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

include("${CMAKE_CURRENT_LIST_DIR}/modules/debug/debug.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/modules/add_dependencies/add_dependencies.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/add_fuzz_tests/add_fuzz_tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/add_tests/add_tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/compiler_options/compiler_options.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/directories/directories.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/emscripten_generate_index_html/emscripten_generate_index_html.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_buildinfo/generate_buildinfo.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/generate_documentation_doxygen/generate_documentation_doxygen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/git/git.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/parse_arguments/parse_arguments.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/project/project.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/require_program/require_program.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/modules/vulkan_compile_GLSL_to_SPIR-V/vulkan_compile_GLSL_to_SPIR-V.cmake")

#================================================================================================
# Fuzzing
#================================================================================================
option(JFC_BUILD_FUZZERS "Build coverage guided fuzz harnesses. Needs clang." OFF)

if (JFC_BUILD_FUZZERS)
    set(JFC_FUZZER_FLAGS -fsanitize=fuzzer,address,undefined -fno-omit-frame-pointer -g)

    add_compile_options(-fsanitize=fuzzer-no-link,address,undefined -fno-omit-frame-pointer -g)
    add_link_options(-fsanitize=address,undefined)

    message(STATUS "jfc: fuzzers on, with address and undefined behaviour sanitizers")
endif()

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

