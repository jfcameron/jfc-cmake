# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

function(jfc_add_dependencies)
    set(TAG "dependency")
    
    function(_add_dependency aName)
        if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${aName}.cmake)
            jfc_log(FATAL_ERROR ${TAG} "${CMAKE_CURRENT_SOURCE_DIR}/${aName}.cmake does not exist. This is required to instruct the loader how to build dependency \"${aName}\".")
        endif()

        set(JFC_DEPENDENCY_NAME "${aName}") # remove
        project(${aName})

        function(jfc_set_dependency_symbols)
            jfc_parse_arguments(${ARGV}
                REQUIRED_LISTS
                    INCLUDE_PATHS
                LISTS
                    LIBRARIES
            )

            set(${JFC_DEPENDENCY_NAME}_INCLUDE_DIR
                "${INCLUDE_PATHS}"
                CACHE PATH "${JFC_DEPENDENCY_NAME}_INCLUDE_DIR include directory" FORCE)

            set(${JFC_DEPENDENCY_NAME}_LIBRARIES
                "${LIBRARIES}"
                CACHE PATH "${JFC_DEPENDENCY_NAME}_LIBRARIES library object list" FORCE)

            set(_dependencies_are_set TRUE PARENT_SCOPE)
        endfunction()

        include("${aName}.cmake")

        if (NOT _dependencies_are_set)
            jfc_log(FATAL_ERROR ${TAG} "${aName}.cmake must call jfc_set_dependency_symbols with LIBRARIES and optional INCLUDE_PATHS.")
        endif()

        jfc_log(STATUS ${TAG} "Done processing submodule dependency \"${aName}\". ${aName}_INCLUDE_DIR: ${${aName}_INCLUDE_DIR}, ${aName}_LIBRARIES: ${${aName}_LIBRARIES}")
    endfunction()
    
    function(jfc_dependency_return_include_paths)
        set(${JFC_DEPENDENCY_NAME}_INCLUDE_DIR
            "${ARGV}"
            CACHE PATH "${JFC_DEPENDENCY_NAME}_INCLUDE_DIR include directory" FORCE)
    endfunction()

    function(jfc_dependency_return_libraries)
        set(${JFC_DEPENDENCY_NAME}_LIBRARIES
            ${ARGV}
            CACHE PATH "${JFC_DEPENDENCY_NAME}_LIBRARIES library object list" FORCE)
    endfunction()

    foreach(_dependency ${ARGV})
        _add_dependency("${_dependency}")
    endforeach()
endfunction()