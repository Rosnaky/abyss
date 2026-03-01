cmake_minimum_required(VERSION 3.18)
project(blackhole-sim LANGUAGES C CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

find_package(OpenGL REQUIRED)
find_package(glfw3 3.3 REQUIRED)

add_library(glad STATIC
    glad/src/glad.c
)

target_include_directories(glad PUBLIC glad/include)

set(SOURCES
    src/main.cpp
    src/cuda_interop.cu
)

add_executable(${PROJECT_NAME} ${SOURCES})

target_link_libraries(${PROJECT_NAME} PRIVATE
    OpenGL::GL
    glfw
    glad
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/inc
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    CUDA_ARCHITECTURES "75;86"
)

