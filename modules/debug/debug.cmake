# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

# print a message with colorized text of form: [TAGNAME] MESSAGEBODY
#    @param aLogLevel: standard cmake log levels e.g: STATUS, FATAL_ERROR
#    @param aTag: Hint about where in the project the log is coming from
#    @param aMessage: content of message 
function(jfc_log aLogLevel aTag aMessage)
    if (NOT WIN32)
        string(ASCII 27 JFC_ESC) # "\"

        set(JFC_STYLE_NONE  "${JFC_ESC}[m")
        set(JFC_STYLE_TAG   "${JFC_ESC}[38;5;3m")
        set(JFC_STYLE_ERROR "${JFC_ESC}[31m")
        set(JFC_STYLE_WARN  "${JFC_ESC}[35m")
    endif()
    
    set(message_buffer "${JFC_STYLE_TAG}[${aTag}]${JFC_STYLE_NONE} ")
    
    if ("${aLogLevel}" STREQUAL "FATAL_ERROR" OR "${aLogLevel}" STREQUAL "SEND_ERROR")
        string(CONCAT message_buffer "${message_buffer}" "${JFC_STYLE_ERROR}error:${JFC_STYLE_NONE} ")
    elseif ("${aLogLevel}" STREQUAL "WARNING" OR "${aLogLevel}" STREQUAL "AUTHOR_WARNING" OR "${aLogLevel}" STREQUAL "DEPRECATION")
        string(CONCAT message_buffer "${message_buffer}" "${JFC_STYLE_WARN}warn:${JFC_STYLE_NONE} ")
    endif()

    string(CONCAT message_buffer "${message_buffer}" "${aMessage}")

    message("${aLogLevel}" "${message_buffer}")
endfunction()

# log all variables visible in the current scope
# useful for identifying and state related bugs
function(jfc_print_all_variables)
    get_cmake_property(cmakevars VARIABLES)
    
    list(SORT cmakevars)
    set(output "")
    
    foreach (cmakevar ${cmakevars})
        string(CONCAT output "${output}" "${cmakevar}=${${cmakevar}}\n")
    endforeach()

    jfc_log(STATUS "Dump" "Called from ${CMAKE_CURRENT_LIST_FILE}...\n${output}")
    jfc_log(STATUS "Dump" "end.")
endfunction()
