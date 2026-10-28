# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
jfc_embed_file
--------------

.. signature::
  jfc_embed_file(<symbol> <input file> <output header>)

  Writes a header defining ``static const unsigned char <symbol>[]``, holding the input file's bytes, for
  shipping a file inside a program. The header is written at configure time, and not again while the file's
  bytes are unchanged, so nothing that includes it rebuilds needlessly.
#]=======================================================================]

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

function(jfc_embed_file aSymbol aPathToInputFile aPathToOutputFile)
    file(READ "${aPathToInputFile}" _hex HEX)
    string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," _bytes "${_hex}")

    string(TOUPPER "${aSymbol}" _guard)
    string(REGEX REPLACE "[^A-Z0-9_]" "_" _guard "${_guard}")
    set(_guard "${_guard}_H")

    file(CONFIGURE OUTPUT "${aPathToOutputFile}" CONTENT
        "// GENERATED at configure time, do not edit directly.
        #ifndef ${_guard}
        #define ${_guard}
        static const unsigned char ${aSymbol}[] = {${_bytes}};
        #endif"
        @ONLY
    )
endfunction()
