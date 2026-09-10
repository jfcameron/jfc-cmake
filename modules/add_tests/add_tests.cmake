# © Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.21)

include_guard(DIRECTORY)

set(JFC_CATCH_CONFIG_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/catchconfig.cpp)
set(JFC_CATCH_INCLUDE_DIRECTORY_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/include)

set(JFC_TEST_NAME_COUNTER 0)

if (NOT CMAKE_SCRIPT_MODE_FILE)
    enable_testing()
endif()

macro(jfc_add_tests)
    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            C++_STANDARD
        LISTS
            INCLUDE_DIRECTORIES
            LIBRARIES
            DEPENDENCIES
        SINGLE_VALUES
            C_STANDARD
        REQUIRED_LISTS
            TEST_SOURCE_FILES
    )

    set(JFC_TEST_TARGET "${PROJECT_NAME}_test_${JFC_TEST_NAME_COUNTER}")

    math(EXPR JFC_TEST_NAME_COUNTER "${JFC_TEST_NAME_COUNTER}+1")

    add_executable(${JFC_TEST_TARGET}
    	${TEST_SOURCE_FILES}
        ${JFC_CATCH_CONFIG_ABSOLUTE_PATH})

    list(LENGTH DEPENDENCIES _dependency_count)

    if (_dependency_count GREATER 0)
        add_dependencies(${JFC_TEST_TARGET} ${DEPENDENCIES})
    endif()

    target_include_directories(${JFC_TEST_TARGET} PRIVATE "${JFC_CATCH_INCLUDE_DIRECTORY_ABSOLUTE_PATH};${INCLUDE_DIRECTORIES}")

    target_link_libraries(${JFC_TEST_TARGET} PRIVATE ${LIBRARIES})

    set_property(TARGET ${JFC_TEST_TARGET} PROPERTY CXX_STANDARD ${C++_STANDARD})
    set_property(TARGET ${JFC_TEST_TARGET} PROPERTY CXX_STANDARD_REQUIRED ON)

    if (C_STANDARD)
        set_property(TARGET ${JFC_TEST_TARGET} PROPERTY C_STANDARD          ${C_STANDARD})
        set_property(TARGET ${JFC_TEST_TARGET} PROPERTY C_STANDARD_REQUIRED ON)
    endif()

    add_test(NAME ${JFC_TEST_TARGET} COMMAND ${JFC_TEST_TARGET})
endmacro()

