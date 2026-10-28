# © Joseph Cameron - MIT License

if (NOT DEFINED ENV{ANDROID_NDK_HOME})
    message(FATAL_ERROR "toolchain-android.cmake: set ANDROID_NDK_HOME to an NDK (r23 or later)")
endif()

include("$ENV{ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake")

set(CMAKE_CROSSCOMPILING_EMULATOR "${CMAKE_COMMAND};-P;${CMAKE_CURRENT_LIST_DIR}/run-on-android.cmake;--")
