# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

function(jfc_require_program aProgramName)
    set(TAG "require program")

    string(TOUPPER "${aProgramName}" _upper)

    find_program(JFC_PROGRAM_${_upper} NAMES "${aProgramName}")

    if (JFC_PROGRAM_${_upper})
        set(${_upper}_FOUND TRUE PARENT_SCOPE)
        set(${_upper}_EXECUTABLE "${JFC_PROGRAM_${_upper}}" PARENT_SCOPE)
    else()
        set(${_upper}_FOUND FALSE PARENT_SCOPE)
        set(${_upper}_EXECUTABLE "" PARENT_SCOPE)
    endif()
endfunction()
