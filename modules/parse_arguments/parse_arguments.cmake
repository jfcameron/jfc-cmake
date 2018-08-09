# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

# @OPTIONS : booleans
# @SINGLE_VALUES : single values that may be unset
# @REQUIRED_SINGLE_VALUES : single values that must be set
# @LISTS : lists that may be unset
# @REQUIRED_LISTS : lists that must be set
# Wrapper for cmake_parse_arguments that does the busy work of asserting the existence of required args.
# FATAL_ERROR if a required is missing
# the parsed arg list generates a series of variables with names matching your input e.g:
# jfc_parse_arguments(${ARGV}
#   OPTIONS
#       blar
#       blam
#   SINGLE_VALUES
#       zip
#   REQUIRED_SINGLE_VALUES blar
#   LISTS etcetc
#   REQUIRED_LISTS etc
# )
# generates the following variables:
# booleans: blar, blam (TRUE if present in ARGV, FALSE if not)
# single value: zip (may be any value or unset if not present in argv)
# single value: blar (any value, guaranteed to be set after successful call to parse_arguments)
# list: etcetc (must use LIST family of functions to interact with content. unset if not present in ARGV)
# list: etc (must use LIST family of functions to interact with content. guaranteed to be set after successful call to parse_arguments)
function(jfc_parse_arguments)
    set(TAG "jfc_parse_arguments")

    set(NULL)
    set(_MULTI_VALUE_ARGS
            OPTIONS    
            SINGLE_VALUES          
            LISTS 
            REQUIRED_SINGLE_VALUES 
            REQUIRED_LISTS
    )

    set(_argv_passthrough)
    foreach(_arg ${ARGV})
        list(FIND _MULTI_VALUE_ARGS ${_arg} _item_is_a_name)

        if (_item_is_a_name GREATER_EQUAL 0)
            break()
        endif()

        list(APPEND _argv_passthrough ${_arg})
    endforeach()

    list (LENGTH _argv_passthrough _s)
    if (_s EQUAL 0)
        jfc_log(FATAL_ERROR ${TAG} "nothing to parse! Did you forget to prepend $\{ARGV\} to your list of requirements?")
    endif()

    cmake_parse_arguments("_ARG" "${NULL}" "${NULL}" "${_MULTI_VALUE_ARGS}" ${ARGN})

    set(all_required_args ${_ARG_REQUIRED_SINGLE_VALUES}${_ARG_REQUIRED_LISTS})
    set(all_optional_args ${_ARG_OPTIONS}${_ARG_SINGLE_VALUES}${_ARG_LISTS})

    set(_required_only_argv_passthrough)
    set(_optional_only_argv_passthrough)

    set(_mode "required") # required | optional
    foreach(_arg ${_argv_passthrough})
        set(type "value")

        foreach(_required ${all_required_args})
            if ("${_required}" STREQUAL "${_arg}")
                set(type "required")
                set(_mode "required")
            endif()
        endforeach()

        if ("${type}" STREQUAL "value")
            foreach(_optional ${all_optional_args})
                if ("${_optional}" STREQUAL "${_arg}")
                    set(type "optional" )
                    set(_mode "optional")
                endif()
            endforeach()
        endif()

        if ("${_mode}" STREQUAL "required")
            list(APPEND _required_only_argv_passthrough "${_arg}")
        elseif ("${_mode}" STREQUAL "optional")
            list(APPEND _optional_only_argv_passthrough "${_arg}")
        endif()
    endforeach()

    macro(_promote_args_to_parent_scope argType bNoPrefix)
        if (NOT ${bNoPrefix})
            set(_prefix "_ARG_")
        endif()

        foreach(name ${${argType}})
            list(LENGTH _ARG_${name} _s)

            if (_s GREATER 0)
                set(${_prefix}${name} "${_ARG_${name}}" PARENT_SCOPE)
            endif()
        endforeach()
    endmacro()

    function(_required_args_imp)
        set(_OPTIONS_ARGS     "")
        set(_ONE_VALUE_ARGS   "${_ARG_REQUIRED_SINGLE_VALUES}")
        set(_MULTI_VALUE_ARGS "${_ARG_REQUIRED_LISTS}"        )

        set(_ONE_VALUE_ARGS   "${_ARG_REQUIRED_SINGLE_VALUES}" PARENT_SCOPE)
        set(_MULTI_VALUE_ARGS "${_ARG_REQUIRED_LISTS}"         PARENT_SCOPE)

        cmake_parse_arguments("_ARG" "${_OPTIONS_ARGS}" "${_ONE_VALUE_ARGS}" "${_MULTI_VALUE_ARGS}" ${ARGN})

        macro(_validate_and_promote_args_to_parent_scope argType)
            foreach(name ${${argType}})
                list(LENGTH _ARG_${name} _s)

                if (_s GREATER 0)
                    set(_i "0")

                    while(${_i} LESS ${_s})
                        list(GET "_ARG_${name}" ${_i} value)

                        MATH(EXPR _i "${_i}+1")
                    endwhile()
                else()
                    jfc_log(FATAL_ERROR ${TAG} "Required arg \"${name}\" is missing or contains no values!")
                endif()
            endforeach()

            _promote_args_to_parent_scope("${argType}" FALSE)
        endmacro()

        _validate_and_promote_args_to_parent_scope(_ONE_VALUE_ARGS FALSE)
        _validate_and_promote_args_to_parent_scope(_MULTI_VALUE_ARGS FALSE)
    endfunction()
    _required_args_imp(${_required_only_argv_passthrough})

    _promote_args_to_parent_scope(_ONE_VALUE_ARGS TRUE)
    _promote_args_to_parent_scope(_MULTI_VALUE_ARGS TRUE)

    function(_optional_args_imp)
        set(_OPTIONS_ARGS     "${_ARG_OPTIONS}")
        set(_ONE_VALUE_ARGS   "${_ARG_SINGLE_VALUES}")
        set(_MULTI_VALUE_ARGS "${_ARG_LISTS}")

        set(_OPTIONS_ARGS     "${_ARG_OPTIONS}"       PARENT_SCOPE)
        set(_ONE_VALUE_ARGS   "${_ARG_SINGLE_VALUES}" PARENT_SCOPE)
        set(_MULTI_VALUE_ARGS "${_ARG_LISTS}"         PARENT_SCOPE)

        cmake_parse_arguments("_ARG" "${_OPTIONS_ARGS}" "${_ONE_VALUE_ARGS}" "${_MULTI_VALUE_ARGS}" ${ARGN})

        _promote_args_to_parent_scope(_OPTIONS_ARGS FALSE)
        _promote_args_to_parent_scope(_ONE_VALUE_ARGS FALSE)
        _promote_args_to_parent_scope(_MULTI_VALUE_ARGS FALSE)
    endfunction()
    _optional_args_imp(${_optional_only_argv_passthrough})

    _promote_args_to_parent_scope(_OPTIONS_ARGS TRUE)
    _promote_args_to_parent_scope(_ONE_VALUE_ARGS TRUE)
    _promote_args_to_parent_scope(_MULTI_VALUE_ARGS TRUE)
endfunction()
