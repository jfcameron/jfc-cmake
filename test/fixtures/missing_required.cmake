# © Joseph Cameron - MIT License

include("${CMAKE_CURRENT_LIST_DIR}/../../modules/parse_arguments/parse_arguments.cmake")

function(needs_two)
    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            FIRST
            SECOND
    )
endfunction()

needs_two(FIRST a)
