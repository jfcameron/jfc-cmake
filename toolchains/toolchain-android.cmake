# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
toolchain-android
-----------------

A toolchain file wrapping the Android NDK's own, found at the ``ANDROID_NDK_HOME`` environment variable (r23
or later). Tests run on the device adb is connected to, through ``run-on-android.cmake``.
#]=======================================================================]

if (NOT DEFINED ENV{ANDROID_NDK_HOME})
    message(FATAL_ERROR "toolchain-android.cmake: set ANDROID_NDK_HOME to an NDK (r23 or later)")
endif()

include("$ENV{ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake")

set(CMAKE_CROSSCOMPILING_EMULATOR "${CMAKE_COMMAND};-P;${CMAKE_CURRENT_LIST_DIR}/run-on-android.cmake;--")
