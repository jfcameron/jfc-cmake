# © Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

option(JFC_BUILD_FUZZERS "Build coverage guided fuzz harnesses. Needs clang." OFF)

if (JFC_BUILD_FUZZERS)
    set(JFC_FUZZER_FLAGS -fsanitize=fuzzer,address,undefined -fno-omit-frame-pointer -g)

    add_compile_options(-fsanitize=fuzzer-no-link,address,undefined -fno-omit-frame-pointer -g)
    add_link_options(-fsanitize=address,undefined)

    message(STATUS "jfc: fuzzers on, with address and undefined behaviour sanitizers")
endif()

macro(jfc_add_fuzz_tests)
    if (JFC_BUILD_FUZZERS)
        if (NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            message(FATAL_ERROR
                "jfc_add_fuzz_tests: JFC_BUILD_FUZZERS needs clang: libFuzzer ships with it as -fsanitize=fuzzer and gcc has no equivalent. Configure this build directory with clang, or drive the same harnesses with AFL++, which takes the same entry point.")
        endif()

        jfc_parse_arguments(${ARGV}
            REQUIRED_SINGLE_VALUES
                C++_STANDARD
            LISTS
                INCLUDE_DIRECTORIES
                LIBRARIES
                DEPENDENCIES
                CORPUS_DIRECTORIES
            SINGLE_VALUES
                C_STANDARD
            REQUIRED_LISTS
                FUZZ_SOURCE_FILES
        )

        set(JFC_FUZZ_TARGETS)

        foreach(_jfc_fuzz_source ${FUZZ_SOURCE_FILES})
            get_filename_component(_jfc_fuzz_name "${_jfc_fuzz_source}" NAME_WE)

            set(_jfc_fuzz_target "${PROJECT_NAME}_fuzz_${_jfc_fuzz_name}")

            add_executable(${_jfc_fuzz_target} "${_jfc_fuzz_source}")

            list(APPEND JFC_FUZZ_TARGETS "${_jfc_fuzz_target}")

            list(LENGTH DEPENDENCIES _jfc_fuzz_dependency_count)

            if (_jfc_fuzz_dependency_count GREATER 0)
                add_dependencies(${_jfc_fuzz_target} ${DEPENDENCIES})
            endif()

            target_include_directories(${_jfc_fuzz_target} PRIVATE ${INCLUDE_DIRECTORIES})

            target_link_libraries(${_jfc_fuzz_target} PRIVATE ${LIBRARIES})

            target_compile_options(${_jfc_fuzz_target} PRIVATE ${JFC_FUZZER_FLAGS})
            target_link_options(${_jfc_fuzz_target} PRIVATE ${JFC_FUZZER_FLAGS})

            set_property(TARGET ${_jfc_fuzz_target} PROPERTY CXX_STANDARD ${C++_STANDARD})
            set_property(TARGET ${_jfc_fuzz_target} PROPERTY CXX_STANDARD_REQUIRED ON)

            if (C_STANDARD)
                set_property(TARGET ${_jfc_fuzz_target} PROPERTY C_STANDARD          ${C_STANDARD})
                set_property(TARGET ${_jfc_fuzz_target} PROPERTY C_STANDARD_REQUIRED ON)
            endif()

            if (CORPUS_DIRECTORIES)
                add_test(NAME ${_jfc_fuzz_target}
                    COMMAND ${_jfc_fuzz_target} -runs=0 ${CORPUS_DIRECTORIES})
            else()
                add_test(NAME ${_jfc_fuzz_target} COMMAND ${_jfc_fuzz_target} -runs=0)
            endif()
        endforeach()
    endif()
endmacro()

