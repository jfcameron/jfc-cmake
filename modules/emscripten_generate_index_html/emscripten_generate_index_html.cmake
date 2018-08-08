# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

set(JFC_EMSCRIPTEN_INDEX_HTML_TEMPLATE_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/emscripten_index_template.html.in)

function(jfc_emscripten_generate_index_html_for_current_project)
    set(TAG "html")

    configure_file(${JFC_EMSCRIPTEN_INDEX_HTML_TEMPLATE_ABSOLUTE_PATH} "${PROJECT_BINARY_DIR}/index.html" @ONLY)
endfunction()