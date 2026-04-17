cmake_minimum_required(VERSION 3.20)
project(MicroSim_KKS_CuFFT LANGUAGES C CXX CUDA)

# ---------------------------------------------------------------------------
# KKS CuFFT solver  (single-GPU CUDA)
#
# Dependency: CUDA toolkit (cufft, cuda_driver, cudart)
# Target: microsim_kks_cufft
# ---------------------------------------------------------------------------

if(NOT CUDAToolkit_FOUND)
    find_package(CUDAToolkit REQUIRED)
endif()

# Default GPU architecture
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES 70 CACHE STRING
        "CUDA GPU architectures to compile for (e.g. 70;80;90)")
endif()

add_executable(microsim_kks_cufft KKS_cuFFT.cu)

set_target_properties(microsim_kks_cufft PROPERTIES
    CUDA_SEPARABLE_COMPILATION OFF
)

target_include_directories(microsim_kks_cufft PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop
)

target_link_libraries(microsim_kks_cufft PRIVATE
    CUDA::cufft
    CUDA::cuda_driver
    CUDA::cudart
    m
)

# Create the DATA output directory at build time (matches original Makefile behaviour)
add_custom_command(TARGET microsim_kks_cufft POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
            "${CMAKE_CURRENT_BINARY_DIR}/DATA"
    COMMENT "Creating DATA output directory"
)

install(TARGETS microsim_kks_cufft RUNTIME DESTINATION bin)
