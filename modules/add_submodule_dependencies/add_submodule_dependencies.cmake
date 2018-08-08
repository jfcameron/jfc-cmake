# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

# build a dependant library project
#    @param aName: name of repository
#    Assumptions: 
#        - this is a git project
#        - a submodule to the repo {aName} has been added to this project and exists in {CMAKE_CURRENT_SOURCE_DIR}
#        - a file named {aName}.cmake exists in {CMAKE_CURRENT_SOURCE_DIR}. It should contain instructions to build the submodule.
#
#    Note: inside of {aName}.cmake the variable {JFC_DEPENDENCY_NAME} is defined with the value of {aName}
#    
#    Example usage:
#        {root}/extern/CMakeLists.txt
#            include("${CMAKE_SOURCE_DIR}/cmake/jfclib.cmake")
#            _add_dependency("MyCoolLib")
#
#        {root}/extern/MyCoolLib.cmake
#            set(MYCOOLLIB_BUILD_TESTS OFF CACHE BOOL "Disabled testing for ${JFC_DEPENDENCY_NAME}")
#            set(MYCOOLLIB_INSTALL OFF)
#
#            add_subdirectory(${JFC_DEPENDENCY_NAME})
#
#            set(${JFC_DEPENDENCY_NAME}_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/${JFC_DEPENDENCY_NAME}/include"
#                CACHE PATH "${JFC_DEPENDENCY_NAME} include directory" FORCE)
#
#            set(${JFC_DEPENDENCY_NAME}_LIBRARIES "${CMAKE_BINARY_DIR}/extern/MyCoolLib/src/libMyCoolLib.a"
#                CACHE PATH "${JFC_DEPENDENCY_NAME} library object list" FORCE) 
function(jfc_add_submodule_dependencies)      # jfc_build_submodule_dependencies
    function(_add_dependency aName)
        set(TAG "dependency")

        if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${aName}.cmake)
            jfc_log(FATAL_ERROR ${TAG} "${CMAKE_CURRENT_SOURCE_DIR}/${aName}.cmake does not exist. This is required to instruct the loader how to build dependency \"${aName}\".")
        endif()

        jfc_git(COMMAND submodule update --init -- ${CMAKE_CURRENT_SOURCE_DIR}/${aName})

        set(JFC_DEPENDENCY_NAME "${aName}")

        include("${aName}.cmake")

        # TODO: these should be promoted

        if (NOT DEFINED ${aName}_LIBRARIES)
            jfc_log(WARNING ${TAG} "${aName}.cmake did not define a variable \"${aName}_LIBRARIES\". Is it header only?")
        endif()

        if (NOT DEFINED ${aName}_INCLUDE_DIR)
            jfc_log(FATAL_ERROR ${TAG} "${aName}.cmake did not define a variable \"${aName}_INCLUDE_DIR\".")
        endif()

        jfc_log(STATUS ${TAG} "Done processing submodule dependency \"${aName}\". ${aName}_INCLUDE_DIR: ${${aName}_INCLUDE_DIR}, ${aName}_LIBRARIES: ${${aName}_LIBRARIES}")
    endfunction()

    MATH(EXPR ARGC "${ARGC}-1")

    foreach(_i RANGE ${ARGC})
        _add_dependency("${ARGV${_i}}")
    endforeach()
endfunction()