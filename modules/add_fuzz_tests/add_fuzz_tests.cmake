# © Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

macro(jfc_add_fuzz_tests)
    if (JFC_BUILD_FUZZERS)
        if (NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            message(FATAL_ERROR
                "JFC_BUILD_FUZZERS needs clang: libFuzzer ships with it as -fsanitize=fuzzer and "
                "gcc has no equivalent. Configure this build directory with clang, or drive the "
                "same harnesses with AFL++, which takes the same entry point.")
        endif()

        set(TAG "FUZZ")

        jfc_parse_arguments(${ARGV}
            REQUIRED_SINGLE_VALUES
                C++_STANDARD
                C_STANDARD
            LISTS
                INCLUDE_DIRECTORIES
                LIBRARIES
                DEPENDENCIES
                CORPUS_DIRECTORIES
            REQUIRED_LISTS
                FUZZ_SOURCE_FILES
        )

        set(_jfc_fuzz_owner "${PROJECT_NAME}")

        set(_jfc_fuzz_includes "${${PROJECT_NAME}_INCLUDE_DIRECTORIES}")

        foreach(_jfc_fuzz_source ${FUZZ_SOURCE_FILES})
            get_filename_component(_jfc_fuzz_name "${_jfc_fuzz_source}" NAME_WE)

            project("${_jfc_fuzz_owner}_fuzz_${_jfc_fuzz_name}")

            add_executable(${PROJECT_NAME} "${_jfc_fuzz_source}")

            list(LENGTH DEPENDENCIES _jfc_fuzz_dependency_count)

            if (_jfc_fuzz_dependency_count GREATER 0)
                add_dependencies(${PROJECT_NAME} ${DEPENDENCIES})
            endif()

            target_include_directories(${PROJECT_NAME} PRIVATE
                "${_jfc_fuzz_includes};${INCLUDE_DIRECTORIES}")

            target_link_libraries(${PROJECT_NAME} ${LIBRARIES})

            target_compile_options(${PROJECT_NAME} PRIVATE ${JFC_FUZZER_FLAGS})
            target_link_options(${PROJECT_NAME} PRIVATE ${JFC_FUZZER_FLAGS})

            set_property(TARGET ${PROJECT_NAME} PROPERTY C_STANDARD   ${C_STANDARD})
            set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD ${C++_STANDARD})

            if (CORPUS_DIRECTORIES)
                add_test(NAME ${PROJECT_NAME}
                    COMMAND ${PROJECT_NAME} -runs=0 ${CORPUS_DIRECTORIES})
            else()
                add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME} -runs=0)
            endif()
        endforeach()

        project("${_jfc_fuzz_owner}")
    endif()
endmacro()

