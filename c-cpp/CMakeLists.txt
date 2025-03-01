#**********************************************************************#
# Authors: Guilhem Fauré                                               #
#**********************************************************************#

cmake_minimum_required(VERSION 3.30)
# project(example VERSION 0.0.0)

set(CMAKE_C_COMPILER clang)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall") # TODO improve

set(MAIN main) # TODO project name by default

add_executable(${MAIN} main.c)

# target_link_libraries(${EXECUTABLE_NAME} example)

# add_subdirectory(src)
