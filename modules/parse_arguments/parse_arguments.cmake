# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

function(jfc_parse_arguments)
    set(_spec_keywords OPTIONS SINGLE_VALUES LISTS REQUIRED_SINGLE_VALUES REQUIRED_LISTS)

    set(_argv)
    set(_spec)
    set(_reading_spec FALSE)

    foreach (_arg IN LISTS ARGV)
        if (NOT _reading_spec)
            list(FIND _spec_keywords "${_arg}" _index)

            if (_index GREATER_EQUAL 0)
                set(_reading_spec TRUE)
            endif()
        endif()

        if (_reading_spec)
            list(APPEND _spec "${_arg}")
        else()
            list(APPEND _argv "${_arg}")
        endif()
    endforeach()

    cmake_parse_arguments(_SPEC "" "" "${_spec_keywords}" ${_spec})

    set(_options       ${_SPEC_OPTIONS})
    set(_single_values ${_SPEC_SINGLE_VALUES} ${_SPEC_REQUIRED_SINGLE_VALUES})
    set(_lists         ${_SPEC_LISTS} ${_SPEC_REQUIRED_LISTS})
    set(_required      ${_SPEC_REQUIRED_SINGLE_VALUES} ${_SPEC_REQUIRED_LISTS})

    list(LENGTH _argv _argv_length)

    if (_argv_length EQUAL 0 AND _required)
        message(FATAL_ERROR "jfc_parse_arguments: nothing to parse! Did you forget to prepend $\{ARGV\} to your list of requirements?")
    endif()

    cmake_parse_arguments(_ARG "${_options}" "${_single_values}" "${_lists}" ${_argv})

    if (_ARG_UNPARSED_ARGUMENTS)
        list(JOIN _ARG_UNPARSED_ARGUMENTS " " _unrecognised)

        message(FATAL_ERROR "jfc_parse_arguments: unrecognised argument(s): ${_unrecognised}")
    endif()

    if (_ARG_KEYWORDS_MISSING_VALUES)
        list(JOIN _ARG_KEYWORDS_MISSING_VALUES " " _valueless)

        message(FATAL_ERROR "jfc_parse_arguments: keyword(s) supplied with no value: ${_valueless}")
    endif()

    foreach (_name IN LISTS _required)
        if (NOT DEFINED _ARG_${_name} OR "${_ARG_${_name}}" STREQUAL "")
            message(FATAL_ERROR "jfc_parse_arguments: Required arg \"${_name}\" is missing or contains no values!")
        endif()
    endforeach()

    foreach (_name IN LISTS _options _single_values _lists)
        set(${_name} "${_ARG_${_name}}" PARENT_SCOPE)
    endforeach()
endfunction()
