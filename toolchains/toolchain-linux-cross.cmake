# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
toolchain-linux-cross
---------------------

A toolchain file for a Debian or Ubuntu gcc cross compiler, ``<triple>-gcc`` and ``<triple>-g++``. Tests run
under qemu-user when it is installed, and are only built when it is not.

.. variable:: JFC_CROSS_TRIPLE

  Required: the target triple, eg ``arm-linux-gnueabihf``.

.. variable:: JFC_CROSS_SYSROOT

  Where the target's libraries are found. ``/usr/<triple>`` unless given.

.. variable:: JFC_CROSS_QEMU

  The emulator that runs the tests. ``qemu-<architecture>`` unless given.
#]=======================================================================]

if (NOT JFC_CROSS_TRIPLE)
    message(FATAL_ERROR "toolchain-linux-cross.cmake: set JFC_CROSS_TRIPLE, e.g. arm-linux-gnueabihf")
endif()

list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES JFC_CROSS_TRIPLE JFC_CROSS_SYSROOT JFC_CROSS_QEMU)

if (NOT JFC_CROSS_SYSROOT)
    set(JFC_CROSS_SYSROOT "/usr/${JFC_CROSS_TRIPLE}")
endif()

string(REGEX MATCH "^[^-]+" _jfc_cross_architecture "${JFC_CROSS_TRIPLE}")

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR "${_jfc_cross_architecture}")

set(CMAKE_C_COMPILER "${JFC_CROSS_TRIPLE}-gcc")
set(CMAKE_CXX_COMPILER "${JFC_CROSS_TRIPLE}-g++")

set(CMAKE_FIND_ROOT_PATH "${JFC_CROSS_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

if (NOT JFC_CROSS_QEMU)
    if (_jfc_cross_architecture MATCHES "^i[3-6]86$")
        set(JFC_CROSS_QEMU qemu-i386)
    elseif (_jfc_cross_architecture MATCHES "^powerpc(.*)$")
        set(JFC_CROSS_QEMU "qemu-ppc${CMAKE_MATCH_1}")
    else()
        set(JFC_CROSS_QEMU "qemu-${_jfc_cross_architecture}")
    endif()
endif()

find_program(_jfc_cross_qemu_program NAMES "${JFC_CROSS_QEMU}" NO_CACHE)

if (_jfc_cross_qemu_program)
    set(CMAKE_CROSSCOMPILING_EMULATOR "${_jfc_cross_qemu_program};-L;${JFC_CROSS_SYSROOT}")
else()
    message(STATUS "toolchain-linux-cross.cmake: no ${JFC_CROSS_QEMU}, so the tests are built but cannot run here")
endif()
