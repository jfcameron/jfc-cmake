# © Joseph Cameron - All Rights Reserved
#
# Tests for jfc_parse_arguments. Run it directly, from anywhere:
#
#     cmake -P test/parse_arguments_test.cmake
#
cmake_minimum_required(VERSION 3.21)

include("${CMAKE_CURRENT_LIST_DIR}/../modules/parse_arguments/parse_arguments.cmake")

set(_jfc_test_failures 0)
set(_jfc_test_count 0)

function(jfc_expect_equal aDescription aActual aExpected)
    math(EXPR _jfc_test_count "${_jfc_test_count}+1")
    set(_jfc_test_count "${_jfc_test_count}" PARENT_SCOPE)

    if (NOT "${aActual}" STREQUAL "${aExpected}")
        message(SEND_ERROR "  FAIL ${aDescription}\n       expected [${aExpected}]\n       actual   [${aActual}]")

        math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
        set(_jfc_test_failures "${_jfc_test_failures}" PARENT_SCOPE)
    else()
        message(STATUS "  ok   ${aDescription}")
    endif()
endfunction()

function(jfc_expect_fatal aDescription aFixture aExpectedText)
    math(EXPR _jfc_test_count "${_jfc_test_count}+1")
    set(_jfc_test_count "${_jfc_test_count}" PARENT_SCOPE)

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -Wno-deprecated -P
                "${CMAKE_CURRENT_LIST_DIR}/fixtures/${aFixture}"
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _output
        ERROR_VARIABLE _output)

    if (_result EQUAL 0)
        message(SEND_ERROR "  FAIL ${aDescription} -- it was accepted")

        math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
        set(_jfc_test_failures "${_jfc_test_failures}" PARENT_SCOPE)
    elseif (NOT "${_output}" MATCHES "${aExpectedText}")
        message(SEND_ERROR "  FAIL ${aDescription} -- error did not mention [${aExpectedText}]\n       got: ${_output}")

        math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
        set(_jfc_test_failures "${_jfc_test_failures}" PARENT_SCOPE)
    else()
        message(STATUS "  ok   ${aDescription}")
    endif()
endfunction()

function(_subject)
    jfc_parse_arguments(${ARGV}
        SINGLE_VALUES
            OPTIONAL_THING
        REQUIRED_SINGLE_VALUES
            FIRST_REQUIRED
            SECOND_REQUIRED
        REQUIRED_LISTS
            REQUIRED_LIST
    )

    set(OUT_FIRST "${FIRST_REQUIRED}" PARENT_SCOPE)
    set(OUT_SECOND "${SECOND_REQUIRED}" PARENT_SCOPE)
    set(OUT_LIST "${REQUIRED_LIST}" PARENT_SCOPE)
    set(OUT_OPTIONAL "${OPTIONAL_THING}" PARENT_SCOPE)
endfunction()

message(STATUS "jfc_parse_arguments")

_subject(FIRST_REQUIRED a SECOND_REQUIRED b REQUIRED_LIST x y OPTIONAL_THING o)
jfc_expect_equal("required arguments first: first"    "${OUT_FIRST}"    "a")
jfc_expect_equal("required arguments first: second"   "${OUT_SECOND}"   "b")
jfc_expect_equal("required arguments first: list"     "${OUT_LIST}"     "x;y")
jfc_expect_equal("required arguments first: optional" "${OUT_OPTIONAL}" "o")

_subject(OPTIONAL_THING o FIRST_REQUIRED a SECOND_REQUIRED b REQUIRED_LIST x y)
jfc_expect_equal("optional argument first: first"    "${OUT_FIRST}"    "a")
jfc_expect_equal("optional argument first: second"   "${OUT_SECOND}"   "b")
jfc_expect_equal("optional argument first: list"     "${OUT_LIST}"     "x;y")

_subject(FIRST_REQUIRED a OPTIONAL_THING o SECOND_REQUIRED b REQUIRED_LIST x y)
jfc_expect_equal("optional between two required: first"    "${OUT_FIRST}"    "a")
jfc_expect_equal("optional between two required: second"   "${OUT_SECOND}"   "b")
jfc_expect_equal("optional between two required: list"     "${OUT_LIST}"     "x;y")
jfc_expect_equal("optional between two required: optional" "${OUT_OPTIONAL}" "o")

_subject(FIRST_REQUIRED a SECOND_REQUIRED b REQUIRED_LIST only OPTIONAL_THING o)
jfc_expect_equal("single element list" "${OUT_LIST}" "only")

_subject(FIRST_REQUIRED a SECOND_REQUIRED b REQUIRED_LIST x y)
jfc_expect_equal("optional omitted: still parses"  "${OUT_FIRST}"    "a")
jfc_expect_equal("optional omitted: is empty"      "${OUT_OPTIONAL}" "")

execute_process(
    COMMAND "${CMAKE_COMMAND}" -Wno-deprecated -P
            "${CMAKE_CURRENT_LIST_DIR}/fixtures/missing_required.cmake"
    RESULT_VARIABLE _fixture_result
    OUTPUT_VARIABLE _fixture_output
    ERROR_VARIABLE _fixture_output)

if (_fixture_result EQUAL 0)
    message(SEND_ERROR "  FAIL a missing required argument was accepted")
    math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
else()
    message(STATUS "  ok   a missing required argument is fatal")
endif()

math(EXPR _jfc_test_count "${_jfc_test_count}+1")

if (NOT "${_fixture_output}" MATCHES "SECOND")
    message(SEND_ERROR "  FAIL the error did not name the missing argument\n       got: ${_fixture_output}")
    math(EXPR _jfc_test_failures "${_jfc_test_failures}+1")
else()
    message(STATUS "  ok   the error names the missing argument")
endif()

math(EXPR _jfc_test_count "${_jfc_test_count}+1")

jfc_expect_fatal("a misspelled keyword is fatal, not silently dropped"
    "unknown_keyword.cmake" "unrecognised argument")

jfc_expect_fatal("a keyword with no value after it is fatal"
    "valueless_keyword.cmake" "no value")

function(_omits_optional)
    jfc_parse_arguments(${ARGV}
        SINGLE_VALUES
            OPTIONAL_THING
        REQUIRED_SINGLE_VALUES
            FIRST_REQUIRED
    )

    set(OUT_OPTIONAL "${OPTIONAL_THING}" PARENT_SCOPE)
endfunction()

set(OPTIONAL_THING "leaked-from-caller-scope")
_omits_optional(FIRST_REQUIRED a)
jfc_expect_equal("an omitted optional does not inherit the caller's variable" "${OUT_OPTIONAL}" "")
unset(OPTIONAL_THING)

function(_all_optional)
    jfc_parse_arguments(${ARGV}
        SINGLE_VALUES
            NAME
        LISTS
            FILES
    )

    set(OUT_NAME "${NAME}" PARENT_SCOPE)
endfunction()

_all_optional()
jfc_expect_equal("an all-optional signature accepts zero arguments" "${OUT_NAME}" "")

set(_leaked)
foreach (_helper _promote_args_to_parent_scope _required_args_imp _optional_args_imp)
    if (COMMAND ${_helper})
        list(APPEND _leaked "${_helper}")
    endif()
endforeach()
jfc_expect_equal("it defines no helpers in global scope" "${_leaked}" "")

message(STATUS "")

if (_jfc_test_failures GREATER 0)
    message(FATAL_ERROR "${_jfc_test_failures} of ${_jfc_test_count} assertions failed")
endif()

message(STATUS "all ${_jfc_test_count} assertions passed")

