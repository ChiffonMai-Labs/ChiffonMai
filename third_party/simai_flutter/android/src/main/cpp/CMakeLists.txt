cmake_minimum_required(VERSION 3.22.1)
project(simai_video_export LANGUAGES CXX)

add_library(simai_video_export SHARED native_buffer.cpp)
find_library(log-lib log)
target_link_libraries(simai_video_export ${log-lib})
