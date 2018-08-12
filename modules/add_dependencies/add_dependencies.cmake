# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

function(jfc_add_dependencies) # jfc_build_submodule_dependencies
    jfc_parse_arguments(${ARGV}
        LISTS
            GIT_SUBMODULES
            RELEASES
    )

    set(TAG "dependency")
    
    function(_add_submodule aName)
        if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${aName}.cmake)
            jfc_log(FATAL_ERROR ${TAG} "${CMAKE_CURRENT_SOURCE_DIR}/${aName}.cmake does not exist. This is required to instruct the loader how to build dependency \"${aName}\".")
        endif()

        #jfc_git(COMMAND submodule update --init -- ${CMAKE_CURRENT_SOURCE_DIR}/${aName}) 

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

    foreach(_submodule ${GIT_SUBMODULES})
        _add_submodule("${_submodule}")
    endforeach()

    foreach(_release ${RELEASES})
        _add_release("${_release}")
    endforeach()
endfunction()