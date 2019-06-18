# © 2018 Joseph Cameron - All Rights Reserved

cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include_guard(DIRECTORY)

set(JFC_CATCH_CONFIG_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR}/catchconfig.cpp)
set(JFC_CATCH_INCLUDE_DIRECTORY_ABSOLUTE_PATH ${CMAKE_CURRENT_LIST_DIR})

set(JFC_TEST_NAME_COUNTER 0)

enable_testing()

# \brief adds a list of unit tests to the current project
#
# \detailed uses catch2 cpp unit testing system.
#
# TODO: Consider merging this with jfc_project.. although this can be used with vanilla cmake projects.
#
# @TEST_SOURCE_FILES list of cpp files containing tests
# @C++_STANDARD required iso langauge standard for C++ 
# @C_STANDARD required iso language standard for C
macro(jfc_add_tests)
    set(TAG "TEST")
    
    jfc_parse_arguments(${ARGV}
        REQUIRED_SINGLE_VALUES
            C++_STANDARD
            C_STANDARD
        LISTS
            INCLUDE_DIRECTORIES
            LIBRARIES
            DEPENDENCIES
        REQUIRED_LISTS
            TEST_SOURCE_FILES
    )

    project("${PROJECT_NAME}_test_${JFC_TEST_NAME_COUNTER}")

    math(EXPR JFC_TEST_NAME_COUNTER "${JFC_TEST_NAME_COUNTER}+1")

    add_executable(${PROJECT_NAME}
    	${TEST_SOURCE_FILES}
        ${JFC_CATCH_CONFIG_ABSOLUTE_PATH})

    list(LENGTH DEPENDENCIES _dependency_count)

    if (_dependency_count GREATER 0)
        add_dependencies(${PROJECT_NAME} "${DEPENDENCIES}")
    endif()

    list(APPEND INCLUDE_DIRECTORIES "${${PROJECT_NAME}_INCLUDE_DIRECTORIES}") #automatically include public header paths from jfc_projects

    target_include_directories(${PROJECT_NAME} PRIVATE "${JFC_CATCH_INCLUDE_DIRECTORY_ABSOLUTE_PATH};${INCLUDE_DIRECTORIES}")

    target_link_libraries(${PROJECT_NAME} ${LIBRARIES})

    set_property(TARGET ${PROJECT_NAME} PROPERTY C_STANDARD   ${C_STANDARD})
    set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD ${C++_STANDARD})

    add_test(${PROJECT_NAME} ${PROJECT_NAME})

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/
        COMMAND ${CMAKE_CTEST_COMMAND} --verbose)
    
    # PRINTING COVERAGE -- WARNING HARD CODED FOR XCODE STUFF
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-instr-generate -fcoverage-mapping") #switch to set property call
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-instr-generate -fcoverage-mapping")
    
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/
        COMMAND xcrun llvm-profdata merge -sparse default.profraw -o default.profdata) #hmmm
    
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/
        COMMAND xcrun llvm-cov show "./${PROJECT_NAME}" -instr-profile=default.profdata -show-line-counts-or-regions -output-dir=llvm-cov -format="html") #hmmm 
    # # # # # # # # # # # # # # # # # # # # # # #  
endmacro()

