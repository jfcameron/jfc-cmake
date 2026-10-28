# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
jfc_check_headers
-----------------

.. signature::
  jfc_check_headers(<target> [EXCLUDE <header>...])

  Checks that every public header of a target compiles alone, so that a header leaning on whatever its
  includer happened to include first fails here rather than in a user's code.

  Makes an object library, ``<target>_header_check``, with one source per header found under the target's
  interface include directories within this source directory. Each source includes only its header, by its
  public path, and the library links the target, so each compiles as a consumer would. Headers are named in
  ``EXCLUDE`` by their public path.

  It is a fatal error to name a target that does not exist, or one with no public headers.
#]=======================================================================]

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

function(jfc_check_headers aTarget)
    cmake_parse_arguments(PARSE_ARGV 1 _check "" "" "EXCLUDE")

    if (_check_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "jfc_check_headers(${aTarget}): unexpected arguments: ${_check_UNPARSED_ARGUMENTS}")
    endif()

    if (NOT TARGET ${aTarget})
        message(FATAL_ERROR "jfc_check_headers: there is no target ${aTarget}")
    endif()

    get_target_property(_directories ${aTarget} INTERFACE_INCLUDE_DIRECTORIES)

    if (NOT _directories)
        set(_directories)
    endif()

    set(_sources)

    foreach (_directory ${_directories})
        string(REGEX REPLACE "^\\$<BUILD_INTERFACE:(.*)>$" "\\1" _directory "${_directory}")

        if (NOT _directory MATCHES "^${CMAKE_CURRENT_SOURCE_DIR}/")
            continue()
        endif()

        file(GLOB_RECURSE _headers RELATIVE "${_directory}" "${_directory}/*.h")

        foreach (_header ${_headers})
            if (_header IN_LIST _check_EXCLUDE)
                continue()
            endif()

            string(MAKE_C_IDENTIFIER "${_header}" _name)

            set(_source "${CMAKE_CURRENT_BINARY_DIR}/${aTarget}_header_check/${_name}.cpp")

            file(CONFIGURE OUTPUT "${_source}" CONTENT "#include <${_header}>\n")

            list(APPEND _sources "${_source}")
        endforeach()
    endforeach()

    if (NOT _sources)
        message(FATAL_ERROR "jfc_check_headers(${aTarget}): no public headers under ${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    add_library(${aTarget}_header_check OBJECT ${_sources})

    target_link_libraries(${aTarget}_header_check PRIVATE ${aTarget})
endfunction()
