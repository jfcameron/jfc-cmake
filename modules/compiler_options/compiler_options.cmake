# © 2019 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

# PROBLEM WITH THIS IMPLEMENTATION: IT IS APPLIED UNIVERSALLY. 
# toolchain independent wrapper, forces compiles to be strictly iso compliant, verbose in errors etc.
# Only modifies compiler options IF "JFC_BUILD_TYPE" is defined.
# Valid types:
# RELEASE: slow build, best binary, extremely pedantic options (unused param etc)
# DEVELOP: optimized for compile speed. No symbols no optimization no safety. REPL
# DEBUG: develop with debug symbols
#[[function(jfc_compiler_options)
    set(TAG "compiler_options")

    list(LENGTH ARGV _s)
    if (_s EQUAL 1) 
        set(_options "")

        if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
            set(_options "-pedantic-errors")#;-Wall;-Wextra;-Werror") # force strict iso compliance
            set(_releaseOptions "${_options};-O2")
            set(_developOptions "${_options};-O1")
            set(_debugOptions   "${_developOptions};-Og;-g")
        elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
            set(_options "/W4;/WX") # force strict iso compliance
            set(_releaseOptions "")
            set(_developOptions "")
            set(_debugOptions "")
        else()
            JFC_LOG(WARNING "${TAG}" "${CMAKE_CXX_COMPILER_ID} is not supported by ${TAG}. Default compile options will be used.")
        endif()
        
        if ("${ARGV0}" STREQUAL "RELEASE") 
            set(_options "${_options};${_releaseOptions}")
        elseif("${ARGV0}" STREQUAL "DEVELOP" OR "DEBUG") 
            set(_options "${_options};${_developOptions}")
        elseif("${ARGV0}" STREQUAL "DEBUG") 
            set(_options "${_options};${_debugOptions}")
        else()
            JFC_LOG(FATAL_ERROR "${TAG}" "${ARGV0} is not a valid build type. Valid types are: RELEASE, DEVELOP, DEBUG")
        endif()

        add_compile_options(${_options})
    endif()
endfunction()
jfc_compiler_options("${JFC_BUILD_TYPE}")]]

function(jfc_apply_standard_compile_and_link_flags)
    set(TAG "compiler_options")

    list(LENGTH ARGV _s)
    if (_s EQUAL 2)
        set(_aProjectName "${ARGV0}")
        set(_aBuildType "${ARGV1}")

        set(_options "")

        if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
            set(_options "-pedantic-errors")#;-Wall;-Wextra;-Werror") # force strict iso compliance
            set(_releaseOptions "${_options};-O2")
            set(_developOptions "${_options};-O1")
            set(_debugOptions   "${_developOptions};-Og;-g")
        elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
            set(_options "/W4;/WX") # force strict iso compliance
            set(_releaseOptions "")
            set(_developOptions "")
            set(_debugOptions "")
        else()
            JFC_LOG(WARNING "${TAG}" "${CMAKE_CXX_COMPILER_ID} is not supported by ${TAG}. Default compile options will be used.")
        endif()
        
        if ("${_aBuildType}" STREQUAL "RELEASE") 
            set(_options "${_options};${_releaseOptions}")
        elseif("${_aBuildType}" STREQUAL "DEVELOP" OR "DEBUG") 
            set(_options "${_options};${_developOptions}")
        elseif("${_aBuildType}" STREQUAL "DEBUG") 
            set(_options "${_options};${_debugOptions}")
        else()
            JFC_LOG(FATAL_ERROR "${TAG}" "${_aBuildType} is not a valid build type. Valid types are: RELEASE, DEVELOP, DEBUG")
        endif()

        set_target_properties(${_aProjectName} PROPERTIES COMPILE_FLAGS "-pedantic-errors -Wall -Werror")
        #set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS    "-Wall;-Wextra;-Werror")
    endif()
endfunction()
#jfc_standard_compile_and_link_flags("${JFC_BUILD_TYPE}")

