# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

set(JFC_CATCH_CONFIG_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/catchconfig.cpp)
set(JFC_CATCH_INCLUDE_DIRECTORY_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR})

# @TEST_SOURCE_FILES list of cpp files containing tests
# @C++_STANDARD required iso langauge standard for C++ 
# @C_STANDARD required iso language standard for C
macro(jfc_add_tests)
    set(TAG "TEST")
    
    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            C++_STANDARD
            C_STANDARD
        REQUIRED_LISTS
            TEST_SOURCE_FILES
    )

    enable_testing()

    project("tests")

    add_executable(${PROJECT_NAME}
    	${TEST_SOURCE_FILES}
        ${JFC_CATCH_CONFIG_ABSOLUTE_PATH}
    )

    target_include_directories(${PROJECT_NAME} PRIVATE "${JFC_CATCH_INCLUDE_DIRECTORY_ABSOLUTE_PATH}")
    set_property(TARGET ${PROJECT_NAME} PROPERTY C_STANDARD ${C_STANDARD})
    set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD ${C++_STANDARD})

    add_test(${PROJECT_NAME} ${PROJECT_NAME})

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/
        COMMAND ${CMAKE_CTEST_COMMAND} --verbose)
endmacro()
