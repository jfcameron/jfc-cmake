# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
jfc_publish
-----------

.. signature::
  jfc_publish(NAME <name> VERSION <version>
              [PLATFORM <platform>] [TARGET <target>] [COMPONENT <component>]
              [PROGRAMS <target>...] [LIBRARY_DIRECTORIES <directory>...]
              [RUN <program> [<argument>...]] [RUN_SAYS <regex>]
              [SYSTEM_LIBRARIES <regex>...] [GLIBC <version>]
              [NOTICES <directory>...] [NOTICES_EXCLUDE <regex>...]
              [CHECK <script>] [CHECK_DEFINITIONS <name>=<value>...])

  A target, ``<name>_publish`` (or ``TARGET``), that makes a folder for people to unzip and run, zips it, and checks
  the zip, unpacked somewhere else. The folder is ``<name>-<version>-<platform>`` (``<name>-<version>`` with no
  ``PLATFORM``), made from the ``COMPONENT`` install component (``<name>`` by default) in ``publish/`` in the build
  directory, its zip beside it. What goes in it besides the programs, a project says with its own ``install()``
  rules for that component: its data, a README.

  ``PROGRAMS`` are installed at the folder's top, with what each needs to start on a machine that has nothing
  installed for it, as the configuration being built (Release, say, of a Visual Studio build); Linux programs from a
  build for the machine building them, Windows ones from Windows or cross built (msvc-wine), macOS's not yet:

  - **Linux**: every shared library a program loads, in ``lib/``, found through an ``RPATH`` of ``$ORIGIN/lib``,
    but for the machine's own: its C library always, and whatever matches a ``SYSTEM_LIBRARIES`` regular expression
    (GL, which belongs to its driver, say).
  - **Windows**: every DLL a program imports, and those import, beside it: but Windows' own, and MSVC's runtime, which
    goes in as msvc-wine has it (``MSVC_WINE_ROOT``, else ``/opt/msvc``) when cross built, else as
    InstallRequiredSystemLibraries finds it.

  A library is looked for where the build put it (beside the program, or where Linux's linker recorded), then in
  ``LIBRARY_DIRECTORIES``: a Windows DLL that isn't the project's own, which nothing records the way of, is found there.

  ``NOTICES`` gathers the licence files (``LICENSE*``, ``COPYING*``) under each directory into the folder's
  ``THIRD_PARTY_NOTICES.txt``, each text once, with where it came from: but those under what isn't built into what's
  published (``test``, ``tests``, ``docs``, ``examples``, ``benchmarks``, ``contrib``, a build tree's ``out`` or
  ``build``, ``jfc-cmake``, ``Catch2``), and those whose path matches a ``NOTICES_EXCLUDE`` regular expression.

  The check, on the zip unpacked somewhere else:

  - **Linux**: with ``GLIBC``, that no program or library in it asks for a glibc newer than that (see
    *The glibc floor* below); with ``RUN``, that the program runs from it, in a home of its own, and loads no library
    from anywhere but the zip and the machine's own.
  - **Windows**: that no program or DLL in it imports a DLL that's neither in it nor part of Windows; with ``RUN``,
    that the program runs from it: under wine, in a Windows of its own and with no display, on a host that isn't
    Windows.
  - ``RUN`` names the program, as its target names it, and its arguments: it has to stop by itself, and succeed,
    and with ``RUN_SAYS``, say something matching that.
  - ``CHECK``, a script of the project's own, run last, with ``unpacked`` the unpacked folder and each
    ``CHECK_DEFINITIONS`` name set to its value.

  **The glibc floor.** A program built on a new Linux asks for that machine's glibc, and won't start anywhere older.
  ``glibc_floor.cmake``, as a preset's ``CMAKE_PROJECT_TOP_LEVEL_INCLUDES``, forces ``glibc.h`` into everything the
  project compiles, binding what changed version since glibc 2.34 back to its oldest; with ``GLIBC``, the programs
  are linked with ``glibc_wraps.c`` for what the C++ library calls that's newer, which wants the preset's
  ``-static-libstdc++ -static-libgcc``. Libraries built some other way (by their own configure script) aren't
  compiled with the header: build them against an older glibc, or leave ``GLIBC`` out.
#]=======================================================================]

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

include("${CMAKE_CURRENT_LIST_DIR}/../parse_arguments/parse_arguments.cmake")

set(_JFC_PUBLISH_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

function(jfc_publish)
    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES NAME VERSION
        SINGLE_VALUES PLATFORM TARGET COMPONENT RUN_SAYS GLIBC CHECK
        LISTS PROGRAMS LIBRARY_DIRECTORIES RUN SYSTEM_LIBRARIES NOTICES NOTICES_EXCLUDE CHECK_DEFINITIONS)

    if (NOT TARGET)
        set(TARGET "${NAME}_publish")
    endif()

    if (NOT COMPONENT)
        set(COMPONENT "${NAME}")
    endif()

    if (PLATFORM)
        set(_folder "${NAME}-${VERSION}-${PLATFORM}")
    else()
        set(_folder "${NAME}-${VERSION}")
    endif()

    if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(_system Linux)
    elseif (WIN32)
        set(_system Windows)
    else()
        set(_system Other)
    endif()

    if (PROGRAMS AND _system STREQUAL "Other")
        message(FATAL_ERROR "jfc_publish: programs are published for Linux and Windows, not ${CMAKE_SYSTEM_NAME}")
    endif()

    # what a Linux program loads is found, and it's run, by this machine: one built for another can't be. A Windows one
    # cross built is run under wine
    if (PROGRAMS AND _system STREQUAL "Linux" AND CMAKE_CROSSCOMPILING)
        message(FATAL_ERROR "jfc_publish: Linux programs are published from a build for the machine building them, "
            "not cross built")
    endif()

    if (GLIBC AND NOT _system STREQUAL "Linux")
        message(FATAL_ERROR "jfc_publish: GLIBC is a Linux build's")
    endif()

    set(_stage "${CMAKE_BINARY_DIR}/publish")
    set(_made "${CMAKE_CURRENT_BINARY_DIR}/jfc_publish_${TARGET}")
    set(_zip "${_stage}/${_folder}.zip")

    # where the target works, made now: nothing else need put anything there first
    file(MAKE_DIRECTORY "${_stage}")

    # the machine's own C library, which a program has to take as it finds it
    set(_system_libraries "ld-linux" "libc\\.so" "libm\\.so" "libdl\\.so" "libpthread\\.so" "librt\\.so" "libresolv\\.so"
        "libutil\\.so" ${SYSTEM_LIBRARIES})

    foreach (program IN LISTS PROGRAMS)
        if (NOT TARGET "${program}")
            message(FATAL_ERROR "jfc_publish: PROGRAMS names ${program}, which isn't a target")
        endif()
    endforeach()

    if (PROGRAMS)
        install(TARGETS ${PROGRAMS} RUNTIME DESTINATION . COMPONENT "${COMPONENT}")
    endif()

    # what reads programs, and runs them for the check: this machine's own, not the one being built for
    find_program(JFC_PUBLISH_NM NAMES nm NO_CMAKE_FIND_ROOT_PATH)
    find_program(JFC_PUBLISH_OBJDUMP NAMES objdump llvm-objdump NO_CMAKE_FIND_ROOT_PATH)

    if (NOT CMAKE_HOST_WIN32)
        find_program(JFC_PUBLISH_WINE NAMES wine NO_CMAKE_FIND_ROOT_PATH)
    endif()

    foreach (program IN LISTS PROGRAMS)
        list(APPEND _executables "$<TARGET_FILE:${program}>")
    endforeach()

    string(REPLACE ";" "\" \"" _executables "${_executables}")

    if (LIBRARY_DIRECTORIES)
        string(REPLACE ";" "\" \"" _directories "${LIBRARY_DIRECTORIES}")
        set(_directories "DIRECTORIES \"${_directories}\"")
    else()
        set(_directories "")
    endif()

    if (PROGRAMS AND _system STREQUAL "Linux")
        foreach (program IN LISTS PROGRAMS)
            # RPATH rather than RUNPATH, which a library's own dependencies don't look through
            set_target_properties("${program}" PROPERTIES INSTALL_RPATH "$ORIGIN/lib")
            target_link_options("${program}" PRIVATE "-Wl,--disable-new-dtags")

            if (GLIBC)
                target_sources("${program}" PRIVATE "${_JFC_PUBLISH_DIRECTORY}/glibc_wraps.c")
                target_link_options("${program}" PRIVATE
                    "LINKER:--wrap=_dl_find_object,--wrap=arc4random,--wrap=__isoc23_strtoul")
            endif()
        endforeach()

        string(REPLACE ";" "|" _excluded "${_system_libraries}")

        install(CODE "
            file(GET_RUNTIME_DEPENDENCIES
                EXECUTABLES \"${_executables}\"
                ${_directories}
                RESOLVED_DEPENDENCIES_VAR _resolved
                UNRESOLVED_DEPENDENCIES_VAR _unresolved
                POST_EXCLUDE_REGEXES \"${_excluded}\")

            if (_unresolved)
                message(FATAL_ERROR \"${TARGET}: not found: \${_unresolved}\")
            endif()

            if (_resolved)
                file(INSTALL \${_resolved} DESTINATION \"\${CMAKE_INSTALL_PREFIX}/lib\" FOLLOW_SYMLINK_CHAIN)
            endif()
        " COMPONENT "${COMPONENT}")
    elseif (PROGRAMS AND _system STREQUAL "Windows")
        if (NOT CMAKE_HOST_WIN32)
            if (DEFINED ENV{MSVC_WINE_ROOT})
                set(_msvc "$ENV{MSVC_WINE_ROOT}")
            else()
                set(_msvc "/opt/msvc")
            endif()

            file(GLOB _runtime "${_msvc}/VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT/*.dll")

            if (NOT _runtime)
                message(FATAL_ERROR "jfc_publish: no MSVC runtime under ${_msvc}/VC/Redist to pack")
            endif()

            install(FILES ${_runtime} DESTINATION . COMPONENT "${COMPONENT}")
        else()
            set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION .)
            set(CMAKE_INSTALL_SYSTEM_RUNTIME_COMPONENT "${COMPONENT}")
            include(InstallRequiredSystemLibraries)
        endif()

        # read with objdump where it's found, which reads a Windows program on any machine; else dumpbin, on Windows
        if (JFC_PUBLISH_OBJDUMP)
            set(_reader "
                set(CMAKE_GET_RUNTIME_DEPENDENCIES_TOOL objdump)
                set(CMAKE_GET_RUNTIME_DEPENDENCIES_COMMAND \"${JFC_PUBLISH_OBJDUMP}\")")
        elseif (NOT CMAKE_HOST_WIN32)
            message(FATAL_ERROR "jfc_publish: no objdump to read what Windows programs import")
        else()
            set(_reader "")
        endif()

        # what isn't found is Windows' own, or MSVC's runtime, or missing: the check tells which
        install(CODE "
            set(CMAKE_GET_RUNTIME_DEPENDENCIES_PLATFORM windows+pe)
            ${_reader}

            file(GET_RUNTIME_DEPENDENCIES
                EXECUTABLES \"${_executables}\"
                ${_directories}
                RESOLVED_DEPENDENCIES_VAR _resolved
                UNRESOLVED_DEPENDENCIES_VAR _unresolved
                PRE_EXCLUDE_REGEXES \"^[Aa][Pp][Ii]-[Mm][Ss]-\" \"^[Ee][Xx][Tt]-[Mm][Ss]-\"
                POST_EXCLUDE_REGEXES \"^[A-Za-z]:[/\\\\\\\\][Ww][Ii][Nn][Dd][Oo][Ww][Ss][/\\\\\\\\]\")

            if (_resolved)
                file(INSTALL \${_resolved} DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")
            endif()
        " COMPONENT "${COMPONENT}")
    endif()

    if (NOTICES)
        _jfc_publish_notices("${_made}/THIRD_PARTY_NOTICES.txt" "${NOTICES}" "${NOTICES_EXCLUDE}")
        install(FILES "${_made}/THIRD_PARTY_NOTICES.txt" DESTINATION . COMPONENT "${COMPONENT}")
    endif()

    if (CHECK AND NOT IS_ABSOLUTE "${CHECK}")
        set(CHECK "${CMAKE_CURRENT_SOURCE_DIR}/${CHECK}")
    endif()

    # what the check is told, as a script it includes: a list's semicolons and a regular expression's backslashes as
    # they are, which a command line wouldn't keep
    set(FOLDER "${_folder}")
    set(SYSTEM "${_system}")
    set(SYSTEM_LIBRARIES ${_system_libraries})
    set(_settings "# GENERATED by jfc_publish at configure time, do not edit directly.\n")

    foreach (setting IN ITEMS FOLDER SYSTEM RUN RUN_SAYS GLIBC CHECK SYSTEM_LIBRARIES)
        _jfc_publish_quoted(_value "${${setting}}")
        string(APPEND _settings "set(${setting} ${_value})\n")
    endforeach()

    foreach (tool IN ITEMS NM OBJDUMP WINE)
        _jfc_publish_quoted(_value "${JFC_PUBLISH_${tool}}")
        string(APPEND _settings "set(${tool} ${_value})\n")
    endforeach()

    foreach (definition IN LISTS CHECK_DEFINITIONS)
        if (NOT definition MATCHES "^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
            message(FATAL_ERROR "jfc_publish: CHECK_DEFINITIONS takes <name>=<value>, not ${definition}")
        endif()

        _jfc_publish_quoted(_value "${CMAKE_MATCH_2}")
        string(APPEND _settings "set(${CMAKE_MATCH_1} ${_value})\n")
    endforeach()

    _jfc_publish_write("${_made}/settings.cmake" "${_settings}")

    add_custom_target("${TARGET}"
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${_stage}/${_folder}" "${_zip}"
        COMMAND "${CMAKE_COMMAND}" --install "${CMAKE_BINARY_DIR}" --component "${COMPONENT}" --prefix "${_stage}/${_folder}"
            --config "$<CONFIG>"
        COMMAND "${CMAKE_COMMAND}" -E tar cf "${_zip}" --format=zip "${_folder}"
        COMMAND "${CMAKE_COMMAND}" "-DZIP=${_zip}" "-DSETTINGS=${_made}/settings.cmake" "-DSCRATCH=${_stage}/${_folder}.check"
            -P "${_JFC_PUBLISH_DIRECTORY}/check.cmake"
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${_stage}/${_folder}.check"
        WORKING_DIRECTORY "${_stage}"
        VERBATIM)

    if (PROGRAMS)
        add_dependencies("${TARGET}" ${PROGRAMS})
    endif()
endfunction()

# each licence text once, with every place it came from
function(_jfc_publish_notices aOutput aDirectories aExcluded)
    set(_texts "")

    foreach (directory IN LISTS aDirectories)
        file(GLOB_RECURSE _licences LIST_DIRECTORIES false
            "${directory}/[Ll][Ii][Cc][Ee][Nn][CcSs][Ee]*" "${directory}/[Cc][Oo][Pp][Yy][Ii][Nn][Gg]*")
        list(SORT _licences)

        foreach (licence IN LISTS _licences)
            file(RELATIVE_PATH _where "${directory}" "${licence}")

            # what isn't built into what's published: tests and their frameworks, docs, examples, benchmarks, others'
            # contributions, and build trees left in a checkout
            if (_where MATCHES "(^|/)(test|tests|docs|examples|benchmarks|contrib|out|build|jfc-cmake|Catch2|catch2)/")
                continue()
            endif()

            set(_skip FALSE)

            foreach (excluded IN LISTS aExcluded)
                if (_where MATCHES "${excluded}")
                    set(_skip TRUE)
                endif()
            endforeach()

            if (_skip)
                continue()
            endif()

            get_filename_component(_where "${_where}" DIRECTORY)
            get_filename_component(_root "${directory}" NAME)
            set(_where "${_root}/${_where}")

            file(READ "${licence}" _text)
            string(STRIP "${_text}" _text)
            string(SHA1 _hash "${_text}")

            if (NOT _hash IN_LIST _texts)
                list(APPEND _texts ${_hash})
                set(_text_${_hash} "${_text}")
            endif()

            list(APPEND _where_${_hash} "${_where}")
        endforeach()
    endforeach()

    string(REPEAT "=" 100 _bar)
    set(_notices "Other people's software this is built with, and the licence each is under.\n")

    foreach (hash IN LISTS _texts)
        list(REMOVE_DUPLICATES _where_${hash})
        list(SORT _where_${hash})
        list(JOIN _where_${hash} ", " _where)
        string(APPEND _notices "\n${_bar}\n${_where}\n${_bar}\n\n${_text_${hash}}\n")
    endforeach()

    _jfc_publish_write("${aOutput}" "${_notices}")
endfunction()

# a value as a quoted argument that reads back as it was
function(_jfc_publish_quoted aOutput aValue)
    string(REPLACE "\\" "\\\\" aValue "${aValue}")
    string(REPLACE "\"" "\\\"" aValue "${aValue}")
    string(REPLACE "$" "\\$" aValue "${aValue}")
    set(${aOutput} "\"${aValue}\"" PARENT_SCOPE)
endfunction()

# the text as it is, and only if it changed, so nothing that depends on the file runs again for nothing
function(_jfc_publish_write aPath aText)
    if (EXISTS "${aPath}")
        file(READ "${aPath}" _was)

        if (_was STREQUAL aText)
            return()
        endif()
    endif()

    file(WRITE "${aPath}" "${aText}")
endfunction()
