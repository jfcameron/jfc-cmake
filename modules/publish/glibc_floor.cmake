# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
glibc floor
-----------

For a published Linux build, as a preset's ``CMAKE_PROJECT_TOP_LEVEL_INCLUDES``:

.. code-block:: json

  "cacheVariables": {
    "CMAKE_PROJECT_TOP_LEVEL_INCLUDES": "${sourceDir}/cmake/jfc-cmake/modules/publish/glibc_floor.cmake",
    "CMAKE_EXE_LINKER_FLAGS": "-static-libstdc++ -static-libgcc"
  }

It forces ``glibc.h`` into everything the project compiles, C, C++ and assembly (LuaJIT's virtual machine
included), binding each glibc function that changed version since 2.34 back to its oldest, so a program built on a
new Linux starts on any with glibc 2.34 or newer: Ubuntu 22.04, Debian 12, Fedora 35. :command:`jfc_publish`'s
``GLIBC`` checks it, and links the programs with ``glibc_wraps.c`` for what the C++ runtime calls that's newer.
Wants binutils 2.36 or newer.
#]=======================================================================]

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    add_compile_options("$<$<COMPILE_LANGUAGE:C,CXX,ASM>:SHELL:-include ${CMAKE_CURRENT_LIST_DIR}/glibc.h>")
endif()
