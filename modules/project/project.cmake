# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

#================================================================================================
# Projects
#================================================================================================
set(JFC_LIBRARY_PROJECT_TEMPLATE_ABSOLUTE_PATH    ${CMAKE_CURRENT_LIST_DIR}/library_project_template.cmake.in)
set(JFC_EXECUTABLE_PROJECT_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/executable_project_template.cmake.in)

# TODO: Simplify implementation: make use of jfc_parse_arguments
# Generates a library or executable project.
# See the options in the _required* sets below
# See the output formats in the *_PROJECT_TEMPLATE_ABSOLUTE_PATHs above
# Example usage:
#   jfc_project(executable
#       NAME MyExecutable
#       SOURCE_LIST
#           ${CMAKE_CURRENT_SOURCE_DIR}/main.c
#   )
function(jfc_project aType) # library | executable
    set(TAG "PROJECT")

    set(_required_simple_fields
        "NAME"                        # name of the project
        "VERSION"                     # version of the project (no enforced foramt)
        "DESCRIPTION"                 # description of the project
        "C++_STANDARD"                # minimum ISO language standard required by the C++ compiler.
        "C_STANDARD"                  # minimum ISO language standard required by the C compiler.
    )
    set(_optional_simple_fields 
        ""
    )
    set(_required_list_fields
        "SOURCE_LIST"                 # list of source files
    )
    set(_optional_list_fields
        "PRIVATE_INCLUDE_DIRECTORIES" # Header paths hidden from downstream projects (internal use only)
        "PUBLIC_INCLUDE_DIRECTORIES"  # Header paths accessible (and needed) by downstream projects 
        "LIBRARIES"                   # binary lib files needed by this project (and therefore downstream projects)
    )

    macro(_library_project)
        list(APPEND _required_simple_fields 
            "TYPE"                    # STATIC | DYNAMIC
        )
        set(_project_template_absolute_path "${JFC_LIBRARY_PROJECT_TEMPLATE_ABSOLUTE_PATH}")

        #[[jfc_parse_arguments(${ARGV} # Not begin used.. should change to this instead of the by-hand stuff below
            REQUIRED_SINGLE_VALUES ${_required_simple_fields} 
            SINGLE_VALUES          ${_optional_simple_fields} 
            REQUIRED_LISTS         ${_required_list_fields}   
            LISTS                  ${_optional_list_fields}
        )]]

        #jfc_print_all_variables()

        #jfc_log(STATUS ${TAG} "== Current project: ${NAME} ==")

        _jfc_project_implementation()
    endmacro()

    macro(_executable_project)
        list(APPEND _optional_list_fields 
            "EXECUTABLE_PARAMETERS"   # list of params. see cmake built in function add_executable
        )
        set(_project_template_absolute_path "${JFC_EXECUTABLE_PROJECT_TEMPLATE_ABSOLUTE_PATH}")

        _jfc_project_implementation()
    endmacro()

    macro(_jfc_project_implementation)
        list(APPEND _all_simple_fields ${_required_simple_fields} ${_optional_simple_fields})
        list(APPEND _all_list_fields   ${_required_list_fields}   ${_optional_list_fields})
        list(APPEND _all_fields        ${_all_simple_fields}      ${_all_list_fields})

        set(_parse_mode "PARSE_SIMPLE_FIELDS") # PARSE_SIMPLE_FIELDS | any member of _all_list_fields

        macro(_pop_front)
            list(REMOVE_AT ARGV 0)
            list(LENGTH ARGV _s)
        endmacro()

        list(LENGTH ARGV _s)
        while(_s GREATER 0)
            list(LENGTH ARGV _s)
            list(GET ARGV 0 _item)

            if (_parse_mode STREQUAL "PARSE_SIMPLE_FIELDS")
                list(FIND _required_simple_fields ${_item} _item_is_a_required_field)
                if (_item_is_a_required_field GREATER_EQUAL 0)
                    if (${_s} GREATER 1)
                        list(GET ARGV 1 _value)

                        list(FIND _all_fields ${_value} _value_is_a_field)
                        if (_value_is_a_field GREATER_EQUAL 0)
                            jfc_log(FATAL_ERROR ${TAG} "The field ${_item} requires a value")
                        endif()
                
                        set("${_item}_value" ${_value})

                        _pop_front()
                    else()
                        jfc_log(FATAL_ERROR ${TAG} "${ARGV${_found_index}} requires a value")
                    endif()
                else()
                    list(FIND _all_list_fields ${_item} _item_is_a_list_field)
                    if (_item_is_a_list_field GREATER_EQUAL 0)
                        set(_parse_mode ${_item})
                    else()
                        jfc_log(FATAL_ERROR ${TAG} "\"${_item}\" is a value without a field!")
                    endif()
                endif()

                _pop_front()
            else() # Parsing a list field
                list(FIND _all_fields ${_item} _item_is_a_field)
                if (_item_is_a_field GREATER_EQUAL 0)
                    set(_parse_mode "PARSE_SIMPLE_FIELDS")
                else()
                    list(APPEND "${_parse_mode}" "${_item}")

                    _pop_front()
                endif()
            endif()
        endwhile()

        foreach(_field ${_required_simple_fields})
            if ("${${_field}_value}" STREQUAL "")
                jfc_log(FATAL_ERROR ${TAG} "${_field} is a required field")
            endif()
        endforeach()

        foreach(list ${_required_list_fields})
            set (list_values ${list})
            list(LENGTH ${list_values} _s)

            if ("${_s}" EQUAL 0)
                jfc_log(FATAL_ERROR ${TAG} "${list} is a required list field and is missing or has no entries")
            endif() 
        endforeach()    
        
        foreach(list ${_all_list_fields})
            set (list_values ${list})
            list(LENGTH ${list_values} _s)

            set(_i "0")
            while(${_i} LESS ${_s})
                list(GET "${list_values}" ${_i} value)

                if (NOT ${list}_value)
                    set(${list}_value "${value}")
                else()
                    string(CONCAT ${list}_value "${${list}_value}\n\t" "${value}")
                endif()
            
                MATH(EXPR _i "${_i}+1")
            endwhile()
        endforeach()

        configure_file(${_project_template_absolute_path} "${CMAKE_BINARY_DIR}/${NAME_value}.cmake" @ONLY)

        include("${CMAKE_BINARY_DIR}/${NAME_value}.cmake")

        # TODO: think about how to promote all project_* variables.
        set(PROJECT_NAME       "${PROJECT_NAME}"       PARENT_SCOPE) # Project vars must be promoted to be accessible in call scope
        set(PROJECT_BINARY_DIR "${PROJECT_BINARY_DIR}" PARENT_SCOPE)
    endmacro()

    list(REMOVE_AT ARGV 0)

    if ("${aType}" STREQUAL "library")
        _library_project("${ARGV}")
    elseif ("${aType}" STREQUAL "executable")
        _executable_project("${ARGV}")
    else()
        jfc_log(FATAL_ERROR ${TAG} "jfc_project unrecognized type: ${aType}. Must be library | executable")
    endif()
endfunction()
