cmake_minimum_required(VERSION 3.30)
project(
  project
  VERSION 0.1.0
  LANGUAGES C CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

find_package(PkgConfig REQUIRED)
find_package(Threads REQUIRED)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug)
endif()

add_compile_options(-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Werror)

option(COVERAGE "Coverage measurement" ON)
if(COVERAGE)
  add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
  add_link_options(-fprofile-instr-generate)
endif()
set(PROFRAW_MAIN "main.profraw")
set(PROFRAW_TESTS "tests-%m.profraw")
set(PROFDATA_FILE "coverage.profdata")

add_executable(${PROJECT_NAME}main main.cpp)
target_include_directories(
  ${PROJECT_NAME}main PUBLIC ${CMAKE_SOURCE_DIR}/include ${RTMIDI_INCLUDE_DIRS}
                             ${ALSA_INCLUDE_DIRS})

find_package(doctest REQUIRED)
include(CTest)

add_executable(${PROJECT_NAME}test test.cpp)
target_include_directories(${PROJECT_NAME}test
                           PRIVATE ${CMAKE_SOURCE_DIR}/include)
target_link_libraries(${PROJECT_NAME}test PRIVATE ${PROJECT_NAME}
                                                  doctest::doctest)
add_test(NAME ${PROJECT_NAME}test COMMAND ${PROJECT_NAME}test)

add_custom_target(
  run
  COMMAND LLVM_PROFILE_FILE=${CMAKE_BINARY_DIR}/${PROFRAW_MAIN}
          ./${PROJECT_NAME}main --timeout 1000 # If daemon
  COMMENT "Run main to generate ${PROFRAW_MAIN}")
add_custom_target(
  tests
  COMMAND rm -f ${CMAKE_BINARY_DIR}/tests-*.profraw
  COMMAND LLVM_PROFILE_FILE=${CMAKE_BINARY_DIR}/${PROFRAW_TESTS} ctest
  COMMENT "Run tests to generate ${PROFRAW_TESTS}")
add_custom_target(
  merge_coverage_data
  COMMAND
    bash -c
    "llvm-profdata merge -sparse -output=${CMAKE_BINARY_DIR}/${PROFDATA_FILE} ${CMAKE_BINARY_DIR}/${PROFRAW_MAIN} ${CMAKE_BINARY_DIR}/tests-*.profraw"
  DEPENDS tests run
  COMMENT "Merge coverage data ${PROFDATA_FILE}")
add_custom_target(
  coverage
  COMMAND
    llvm-cov show ./${PROJECT_NAME}main
    -instr-profile=${CMAKE_BINARY_DIR}/${PROFDATA_FILE} -format=html
    -output-dir=${CMAKE_BINARY_DIR}/coverage
  DEPENDS merge_coverage_data
  COMMENT "Coverage report as HTML ${CMAKE_BINARY_DIR}/coverage")
add_dependencies(run ${PROJECT_NAME}main)
add_dependencies(tests ${PROJECT_NAME}test)
add_dependencies(coverage merge_coverage_data)

include(GNUInstallDirs)
install(TARGETS ${name} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

