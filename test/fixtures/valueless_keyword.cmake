# © Joseph Cameron - All Rights Reserved

include("${CMAKE_CURRENT_LIST_DIR}/../../modules/parse_arguments/parse_arguments.cmake")

function(takes_files)
    jfc_parse_arguments(${ARGV}
        SINGLE_VALUES
            NAME
        LISTS
            FILES
    )
endfunction()

takes_files(NAME a FILES)
