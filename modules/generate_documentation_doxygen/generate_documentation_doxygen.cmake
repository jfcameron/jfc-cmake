# © Joseph Cameron - MIT License

#[=======================================================================[.rst:
jfc_generate_documentation_doxygen
----------------------------------

.. signature::
  jfc_generate_documentation_doxygen(README_PATH <readme> OUTPUT_DIRECTORY <directory>
                                     INCLUDE_DIRECTORIES <directory>...
                                     [PROJECT_LOGO <image>] [EXCLUDE_DIRECTORIES <directory>...])

  Runs Doxygen at configure time, over the include directories with the readme as the main page, writing
  the HTML to ``OUTPUT_DIRECTORY``. Relative paths are from the calling directory, and a relative
  ``OUTPUT_DIRECTORY`` is from its build directory. Doxygen's warnings are errors, except for undocumented
  declarations, which are allowed. The project is named after the git repository, or after
  ``PROJECT_NAME`` outside one. Needs ``doxygen``; it is a fatal error if Doxygen fails.
#]=======================================================================]

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

set(JFC_DOXY_CONFIG_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/doxy.config.in)

function(jfc_generate_documentation_doxygen)
    find_program(DOXYGEN_EXECUTABLE doxygen REQUIRED)

    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            README_PATH
            OUTPUT_DIRECTORY
        REQUIRED_LISTS
            INCLUDE_DIRECTORIES
        SINGLE_VALUES
            PROJECT_LOGO
        LISTS
            EXCLUDE_DIRECTORIES
    )

    list(JOIN INCLUDE_DIRECTORIES " " INCLUDE_DIRECTORIES)

    list(JOIN EXCLUDE_DIRECTORIES " " EXCLUDE_DIRECTORIES)

    cmake_path(ABSOLUTE_PATH OUTPUT_DIRECTORY BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

    file(MAKE_DIRECTORY "${OUTPUT_DIRECTORY}")

    execute_process(COMMAND git rev-parse HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    execute_process(COMMAND git rev-parse --show-toplevel
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE _path_to_repo_root OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    if (_path_to_repo_root)
        cmake_path(GET _path_to_repo_root FILENAME GIT_REPO_NAME)
    else()
        set(GIT_REPO_NAME "${PROJECT_NAME}")
    endif()

    configure_file(${JFC_DOXY_CONFIG_TEMPLATE_ABSOLUTE_PATH}
        ${CMAKE_CURRENT_BINARY_DIR}/doxy.config @ONLY)

    execute_process(COMMAND "${DOXYGEN_EXECUTABLE}" "${CMAKE_CURRENT_BINARY_DIR}/doxy.config"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        RESULT_VARIABLE DOXYGEN_RETURN_VALUE
        OUTPUT_VARIABLE DOXYGEN_ERRORS)

    if (DOXYGEN_RETURN_VALUE)
        message(FATAL_ERROR "jfc_generate_documentation_doxygen: Doxygen failed: ${DOXYGEN_ERRORS}")
    endif()
endfunction()

