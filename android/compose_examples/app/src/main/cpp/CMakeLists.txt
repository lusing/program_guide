cmake_minimum_required(VERSION 3.22.1)
project(guide_native)

add_library(
    guide_native
    SHARED
    native-lib.cpp
)

find_library(log-lib log)
target_link_libraries(guide_native ${log-lib})

