# © Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

# aSymbol: the variable name for the embedded data
# aPathToInputFile: path to the file to be embedded
# aPathToOutputFile: path to the generated header file containing the embedded data
function(jfc_embed_file aSymbol aPathToInputFile aPathToOutputFile)
    file(READ "${aPathToInputFile}" _hex HEX)
    string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," _bytes "${_hex}")

    string(TOUPPER "${aSymbol}" _guard)
    string(REGEX REPLACE "[^A-Z0-9_]" "_" _guard "${_guard}")
    set(_guard "${_guard}_H")

    file(WRITE "${aPathToOutputFile}"
        "// GENERATED at configure time, do not edit directly.
        #ifndef ${_guard}
        #define ${_guard}
        static const unsigned char ${aSymbol}[] = {${_bytes}};
        #endif"
    )
endfunction()
