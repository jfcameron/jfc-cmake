# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

# Check if a program is installed on the system. Log and throw if it is not
function(jfc_require_program aProgramName)
    set(TAG "require program")

    string(TOUPPER "${aProgramName}" _UpperProgramName)

    find_program(${_UpperProgramName} NAMES "${aProgramName}")

    if (${_UpperProgramName} STREQUAL "${_UpperProgramName}-NOTFOUND")
        jfc_log(FATAL_ERROR ${TAG} "required program \"${aProgramName}\" could not be found!")
    endif()
endfunction()
