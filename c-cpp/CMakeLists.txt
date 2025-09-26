cmake_minimum_required(VERSION 3.30)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # Useful for LSPs and tools

# project(example VERSION 0.0.0) # Project metadata

set(CMAKE_CXX_COMPILER clang) # C++ compile params
set(CMAKE_CXX_STANDARD 23) # C++ params
set(CMAKE_CXX_STANDARD_REQUIRED True)

# set(CMAKE_C_COMPILER clang) # C compile params
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall") # TODO improve

# target_compile_options(TODO PRIVATE
#     $<$<CXX_COMPILER_ID:Clang>:-Wall;-Wextra;-Wpedantic>
#     $<$<CXX_COMPILER_ID:GNU>:-Wall;-Wextra;-Wpedantic> # ;-Wshadow;-Wconversion>
# )

set(MAIN main) # TODO project name by default

add_executable(${MAIN} main.cpp) # C++ files
# add_executable(${MAIN} main.c) # C files

# target_link_libraries(${EXECUTABLE_NAME} example)

# add_subdirectory(src)
