# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
jfc_publish's check
-------------------

What a ``<name>_publish`` target runs on its zip, unpacked somewhere else, as :command:`jfc_publish` describes:

.. code-block:: shell

  cmake -DZIP=<zip> -DSETTINGS=<settings.cmake> -DSCRATCH=<directory> -P check.cmake

``SETTINGS`` is the script jfc_publish writes at configure time, with what it was given. Without a look at where a
program's libraries came from, this machine's own copies would make a broken folder seem to work.
#]=======================================================================]

cmake_minimum_required(VERSION 3.21)

foreach (needed ZIP SETTINGS SCRATCH)
    if (NOT ${needed})
        message(FATAL_ERROR "jfc_publish: -D${needed}= is needed")
    endif()
endforeach()

include("${SETTINGS}")

file(REMOVE_RECURSE "${SCRATCH}")
file(MAKE_DIRECTORY "${SCRATCH}")
file(ARCHIVE_EXTRACT INPUT "${ZIP}" DESTINATION "${SCRATCH}")

set(unpacked "${SCRATCH}/${FOLDER}")

if (NOT IS_DIRECTORY "${unpacked}")
    message(FATAL_ERROR "jfc_publish: ${ZIP} has no ${FOLDER}")
endif()

set(said_of_it "")

# --- Linux -----------------------------------------------------------------------------------------------------------

function(_jfc_publish_glibc_floor)
    if (NOT NM)
        message(FATAL_ERROR "jfc_publish: no nm to read what the programs ask of glibc")
    endif()

    file(GLOB _elves "${unpacked}/*" "${unpacked}/lib/*.so*")
    file(GLOB _carried_cxx "${unpacked}/lib/libstdc++.so*")
    set(_too_new "")

    foreach (elf IN LISTS _elves)
        if (IS_DIRECTORY "${elf}")
            continue()
        endif()

        file(READ "${elf}" _head LIMIT 4 HEX)

        if (NOT _head STREQUAL "7f454c46")
            continue()
        endif()

        execute_process(COMMAND "${NM}" -D --with-symbol-versions "${elf}"
            OUTPUT_VARIABLE _listed ERROR_VARIABLE _complaint RESULT_VARIABLE _failed)

        if (_failed)
            message(FATAL_ERROR "jfc_publish: ${NM} couldn't read ${elf}: ${_complaint}")
        endif()

        get_filename_component(_name "${elf}" NAME)
        string(REGEX MATCHALL "[^ \n]+@(GLIBCXX|CXXABI|GCC)_[0-9.]+" _cxx "${_listed}")
        string(REGEX MATCHALL "[^ \n]+@GLIBC_[0-9.]+" _asked "${_listed}")

        # the C++ runtime, asked of the machine's own: none, linked in or carried in lib/, whose own glibc is read here
        if (NOT _carried_cxx)
            foreach (symbol IN LISTS _cxx)
                list(APPEND _too_new "${_name}: ${symbol}")
            endforeach()
        endif()

        foreach (symbol IN LISTS _asked)
            string(REGEX REPLACE ".*@GLIBC_" "" _version "${symbol}")

            if (_version VERSION_GREATER GLIBC)
                list(APPEND _too_new "${_name}: ${symbol}")
            endif()
        endforeach()
    endforeach()

    if (_too_new)
        list(REMOVE_DUPLICATES _too_new)
        list(SORT _too_new)
        list(JOIN _too_new "\n    " _said)

        message(FATAL_ERROR "jfc_publish: asked for, and newer than glibc ${GLIBC}, so it won't start on a machine with it:\n"
            "    ${_said}\n"
            "a GLIBC one is bound back by glibc.h (glibc_floor.cmake, the preset's CMAKE_PROJECT_TOP_LEVEL_INCLUDES) or\n"
            "wrapped in glibc_wraps.c; a GLIBCXX, CXXABI or GCC one means -static-libstdc++ -static-libgcc didn't take")
    endif()
endfunction()

function(_jfc_publish_run_linux)
    list(POP_FRONT RUN _program)

    execute_process(COMMAND "${CMAKE_COMMAND}" -E env --unset=LD_LIBRARY_PATH --unset=LD_PRELOAD
            "HOME=${SCRATCH}/home" "XDG_CONFIG_HOME=${SCRATCH}/home/config" "XDG_DATA_HOME=${SCRATCH}/home/data"
            "XDG_CACHE_HOME=${SCRATCH}/home/cache" "LD_DEBUG=libs" "LD_DEBUG_OUTPUT=${SCRATCH}/loaded"
            "${unpacked}/${_program}" ${RUN}
        WORKING_DIRECTORY "${unpacked}"
        TIMEOUT 300
        OUTPUT_VARIABLE _said ERROR_VARIABLE _said
        RESULT_VARIABLE _failed)

    if (_failed)
        message(FATAL_ERROR "jfc_publish: ${_program} didn't run from the zip (${_failed}):\n${_said}")
    endif()

    if (RUN_SAYS AND NOT _said MATCHES "${RUN_SAYS}")
        message(FATAL_ERROR "jfc_publish: ${_program} ran from the zip, but didn't say ${RUN_SAYS}:\n${_said}")
    endif()

    file(GLOB _logs "${SCRATCH}/loaded.*")

    if (NOT _logs)
        message(FATAL_ERROR "jfc_publish: the loader said nothing of ${_program}, so nothing was checked")
    endif()

    set(_from_the_zip 0)
    set(_from_elsewhere "")

    foreach (log IN LISTS _logs)
        file(STRINGS "${log}" _lines REGEX "calling init: ")

        foreach (line IN LISTS _lines)
            string(REGEX REPLACE ".*calling init: " "" _library "${line}")

            if (_library MATCHES "^${unpacked}/")
                math(EXPR _from_the_zip "${_from_the_zip} + 1")
                continue()
            endif()

            set(_allowed FALSE)

            foreach (system IN LISTS SYSTEM_LIBRARIES)
                if (_library MATCHES "${system}")
                    set(_allowed TRUE)
                endif()
            endforeach()

            if (NOT _allowed)
                list(APPEND _from_elsewhere "${_library}")
            endif()
        endforeach()
    endforeach()

    if (_from_elsewhere)
        list(REMOVE_DUPLICATES _from_elsewhere)
        list(JOIN _from_elsewhere "\n    " _listed)

        message(FATAL_ERROR "jfc_publish: libraries came from outside the zip, which a machine won't have:\n    ${_listed}\n"
            "one that's the machine's own goes in SYSTEM_LIBRARIES")
    endif()

    set(said_of_it "ran from it, ${_from_the_zip} libraries from it" PARENT_SCOPE)
endfunction()

# --- Windows ---------------------------------------------------------------------------------------------------------

function(_jfc_publish_imports)
    if (NOT OBJDUMP)
        message(FATAL_ERROR "jfc_publish: no objdump to read what the programs import")
    endif()

    set(_windows_has
        advapi32.dll avrt.dll bcrypt.dll cfgmgr32.dll comctl32.dll comdlg32.dll crypt32.dll d3d11.dll d3d12.dll
        d3dcompiler_47.dll dbghelp.dll dinput8.dll dsound.dll dwmapi.dll dxgi.dll gdi32.dll hid.dll imm32.dll
        iphlpapi.dll kernel32.dll mfplat.dll msvcrt.dll ncrypt.dll ntdll.dll ole32.dll oleaut32.dll opengl32.dll
        normaliz.dll powrprof.dll psapi.dll rpcrt4.dll secur32.dll setupapi.dll shell32.dll shlwapi.dll ucrtbase.dll
        user32.dll userenv.dll uxtheme.dll version.dll winhttp.dll wldap32.dll winmm.dll ws2_32.dll wtsapi32.dll
        xinput1_4.dll)

    file(GLOB _packed RELATIVE "${unpacked}" "${unpacked}/*.dll")
    string(TOLOWER "${_packed}" _packed)
    file(GLOB _portable "${unpacked}/*.exe" "${unpacked}/*.dll")
    set(_missing "")
    set(_asked 0)

    foreach (each IN LISTS _portable)
        execute_process(COMMAND "${OBJDUMP}" -p "${each}"
            OUTPUT_VARIABLE _listed ERROR_VARIABLE _complaint RESULT_VARIABLE _failed)

        if (_failed)
            message(FATAL_ERROR "jfc_publish: ${OBJDUMP} couldn't read ${each}: ${_complaint}")
        endif()

        get_filename_component(_name "${each}" NAME)
        string(REGEX MATCHALL "DLL Name: [^\n]+" _imports "${_listed}")

        foreach (import IN LISTS _imports)
            string(REGEX REPLACE "^DLL Name: " "" _dll "${import}")
            string(STRIP "${_dll}" _dll)
            string(TOLOWER "${_dll}" _dll)
            math(EXPR _asked "${_asked} + 1")

            if (NOT _dll IN_LIST _packed AND NOT _dll IN_LIST _windows_has AND NOT _dll MATCHES "^api-ms-win-")
                list(APPEND _missing "${_dll} (${_name})")
            endif()
        endforeach()
    endforeach()

    if (_missing)
        list(REMOVE_DUPLICATES _missing)
        list(SORT _missing)
        list(JOIN _missing "\n    " _said)

        message(FATAL_ERROR "jfc_publish: these DLLs are asked for, and neither in the zip nor part of Windows:\n    ${_said}\n"
            "one not found goes in jfc_publish's LIBRARY_DIRECTORIES, or is linked statically; one every Windows has goes "
            "in check.cmake's list")
    endif()

    set(said_of_it "${_asked} imports, each in it or Windows'" PARENT_SCOPE)
endfunction()

function(_jfc_publish_run_windows)
    list(POP_FRONT RUN _program)
    set(_command "${unpacked}/${_program}.exe" ${RUN})

    if (NOT CMAKE_HOST_WIN32)
        if (NOT WINE)
            set(said_of_it "${said_of_it}; not run, as there's no wine" PARENT_SCOPE)
            return()
        endif()

        # in a Windows of its own: no display, so nothing shows on this machine's, no WINEPATH, which would find a DLL
        # the zip lacks, and no Mono or Gecko, which a new one would otherwise stop to offer
        set(_command "${CMAKE_COMMAND}" -E env --unset=DISPLAY --unset=WAYLAND_DISPLAY --unset=WINEPATH
            "WINEPREFIX=${SCRATCH}/wine"
            "WINEDEBUG=-all" "WINEDLLOVERRIDES=mscoree,mshtml=" "${WINE}" ${_command})
    endif()

    execute_process(COMMAND ${_command}
        WORKING_DIRECTORY "${unpacked}"
        TIMEOUT 300
        OUTPUT_VARIABLE _said ERROR_VARIABLE _said
        RESULT_VARIABLE _failed)

    if (_failed)
        message(FATAL_ERROR "jfc_publish: ${_program} didn't run from the zip (${_failed}):\n${_said}")
    endif()

    if (RUN_SAYS AND NOT _said MATCHES "${RUN_SAYS}")
        message(FATAL_ERROR "jfc_publish: ${_program} ran from the zip, but didn't say ${RUN_SAYS}:\n${_said}")
    endif()

    if (CMAKE_HOST_WIN32)
        set(said_of_it "${said_of_it}; ran from it" PARENT_SCOPE)
    else()
        set(said_of_it "${said_of_it}; ran from it under wine" PARENT_SCOPE)
    endif()
endfunction()

# --- the checks ------------------------------------------------------------------------------------------------------

if (SYSTEM STREQUAL "Linux")
    if (GLIBC)
        _jfc_publish_glibc_floor()
    endif()

    if (RUN)
        _jfc_publish_run_linux()
    endif()
elseif (SYSTEM STREQUAL "Windows")
    _jfc_publish_imports()

    if (RUN)
        _jfc_publish_run_windows()
    endif()
endif()

if (CHECK)
    include("${CHECK}")
endif()

file(SIZE "${ZIP}" _size)
get_filename_component(_zip_name "${ZIP}" NAME)

if (said_of_it)
    message(STATUS "jfc_publish: ${_zip_name}, ${_size} bytes: ${said_of_it}")
else()
    message(STATUS "jfc_publish: ${_zip_name}, ${_size} bytes")
endif()
