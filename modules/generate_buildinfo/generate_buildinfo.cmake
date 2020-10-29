set(JFC_BUILDINFO_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/buildinfo.h.in)

function(jfc_generate_cmake_header) #CLEAN THIS UP
    string(RANDOM LENGTH 15 JFC_RANDOM_128BITS)
#    string(TOUPPER ${JFC_TARGET_PLATFORM} JFC_TARGET_PLATFORM)

    execute_process(COMMAND git rev-parse HEAD 
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
        OUTPUT_VARIABLE JFC_GIT_COMMIT_HASH OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND git log -1 --format=%cd --date=local HEAD 
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
        OUTPUT_VARIABLE JFC_GIT_COMMIT_DATE OUTPUT_STRIP_TRAILING_WHITESPACE)

    configure_file(${JFC_BUILDINFO_TEMPLATE_ABSOLUTE_PATH}
        ${PROJECT_BINARY_DIR}/generated_include/${PROJECT_NAME}/buildinfo.h @ONLY)
endfunction()
