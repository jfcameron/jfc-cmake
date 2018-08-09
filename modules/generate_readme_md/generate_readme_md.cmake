#================================================================================================
# Documentation: Readme.md
#================================================================================================
set(JFC_README_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/README.md.in)

# Generates a readme.md, useful for github projects
# @DESCRIPTION required, description of the project
function(jfc_generate_readme_md)
    set(TAG "readme")
    
    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            BRIEF
        SINGLE_VALUES
            DESCRIPTION
        LISTS
            IMAGES
    )

    jfc_git(COMMAND rev-parse --show-toplevel
        OUTPUT JFC_PROJECT_ROOT_DIRECTORY)

    jfc_directory(BASENAME ${JFC_PROJECT_ROOT_DIRECTORY} REPO_NAME)

    foreach(_current_url ${IMAGES})
        string(CONFIGURE "<img src=\"@_current_url@\" width=\"100%\">" _currentImage)
        
        string(CONCAT IMAGES_OUTPUT "${IMAGES_OUTPUT}" "${_currentImage}")
    endforeach()
    
    configure_file(${JFC_README_TEMPLATE_ABSOLUTE_PATH} "${JFC_PROJECT_ROOT_DIRECTORY}/README.md" @ONLY)

endfunction()
