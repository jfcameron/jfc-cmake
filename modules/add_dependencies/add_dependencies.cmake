# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

# 
# \brief the add_dependency module provides a way for THIS project to include external code according to a recepie maintained in THIS project.
# It it the way to pull in external projects that do not make use of the jfc_project module. In the jfc_project case, all that needs to be done is to
# include that directory.
#
# add_dependency is more flexible and can be used to pull in any kind of dependency including submodules, archived releases, downloads, plain source, etc.
#
# the same directory in which add_dependecies is called must include files in the same directory that instruct how to build/include that project.
# e.g: dependency "mydependency" requires a file "mydependency.cmake" to exist in the same dir and that file must define library and include path symbols like
# "mydependency_LIBRARIES" and "mydependency_INCLUDE_PATH". Everything else is up to the script and will vary grealty based on the type of dependency etc.
#
# TODO: MUTLIPLE INCLUSION GUARD:
# TODO: Check if this dependency has already been added somewhere else in the dep graph: create a toplevel symbol and check if it exists. if so, log and skip
# TODO: Add a manditory PUBLIC/PRIVATE flag, which decides where to pass along this dependency (does this make sense? dangerous in case of .as)
#
function(jfc_add_dependencies)
    set(TAG "dependency")
    
    function(_add_dependency aName)
        if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${aName}.cmake)
            jfc_log(FATAL_ERROR ${TAG} "${CMAKE_CURRENT_SOURCE_DIR}/${aName}.cmake does not exist. This is required to instruct the loader how to build dependency \"${aName}\".")
        endif()

        set(JFC_DEPENDENCY_NAME "${aName}") # Rename. its a local. Actually try replacing this with aName then renaming aName if possible.
        set(JFC_PROJECT_NAME "${PROJECT_NAME}") # see above line 
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

        #jfc_log(FATAL_ERROR "BLIPBLAPLOP" "${${JFC_PROJECT_NAME}_INCLUDE_DIRECTORIES}") # <- This shows 
        #set("${JFC_PROJECT_NAME}_INCLUDE_DIRECTORIES" 
        #    "${${JFC_PROJECT_NAME}_INCLUDE_DIRECTORIES};${${PROJECT_NAME}_INCLUDE_PATHS}") # This is not working
        
        #set("${JFC_PROJECT_NAME}_LIBRARIES"
        #    "${${JFC_PROJECT_NAME}_LIBRARIES};${${PROJECT_NAME}_LIBRARIES}" FORCE) # This is not working. probably order of operations

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
