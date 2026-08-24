# © Joseph Cameron - All Rights Reserved

if (DEFINED ENV{MSVC_WINE_ROOT})
    set(_msvc_wine_root "$ENV{MSVC_WINE_ROOT}")
else()
    set(_msvc_wine_root "/opt/msvc")
endif()

if (NOT EXISTS "${_msvc_wine_root}/cmake/toolchain-x64.cmake")
    message(FATAL_ERROR "no msvc-wine at ${_msvc_wine_root}: install it there, or set MSVC_WINE_ROOT")
endif()

include("${_msvc_wine_root}/cmake/toolchain-x64.cmake")

set(CMAKE_CROSSCOMPILING_EMULATOR wine)

