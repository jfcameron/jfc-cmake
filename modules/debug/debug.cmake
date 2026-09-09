# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

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
