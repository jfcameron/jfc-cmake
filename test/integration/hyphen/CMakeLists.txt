# © Joseph Cameron - All Rights Reserved

project(jfc-hyphen-probe)

jfc_generate_build_info(INCLUDE_PATH jfc/hyphen-probe)

set(_h "${PROJECT_BINARY_DIR}/generated_include/jfc/hyphen-probe/build_info.h")

if (EXISTS "${_h}")
    file(READ "${_h}" _t)
else()
    set(_t "")
endif()

string(REGEX MATCHALL "\n(#ifndef|#define|namespace) [A-Za-z0-9_:-]*" _ids "${_t}")

set(_bad 0)
foreach(_id ${_ids})
    if (_id MATCHES "-")
        set(_bad 1)
    endif()
endforeach()

if (NOT _t MATCHES "JFC_HYPHEN_PROBE_BUILD_INFO_H")
    set(_bad 1)
endif()

if (EXISTS "${_h}" AND NOT _bad)
    set(JFC_HYPHEN_PROBE_OK TRUE PARENT_SCOPE)
else()
    set(JFC_HYPHEN_PROBE_OK FALSE PARENT_SCOPE)
endif()
