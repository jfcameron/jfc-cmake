# © Joseph Cameron - All Rights Reserved

include("${CMAKE_CURRENT_LIST_DIR}/../../modules/debug/debug.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../../modules/parse_arguments/parse_arguments.cmake")

function(needs_two)
    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            FIRST
            SECOND
    )
endfunction()

needs_two(FIRST a)
