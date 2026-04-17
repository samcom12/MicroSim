cmake_minimum_required(VERSION 3.20)
project(MicroSim_KKS_OpenCL LANGUAGES C)

# ---------------------------------------------------------------------------
# KKS OpenCL solver
#
# Dependencies: MPI, GSL, OpenCL
# Targets: microsim_kks_opencl, reconstruct
# ---------------------------------------------------------------------------

if(NOT TARGET MPI::MPI_C)
    find_package(MPI REQUIRED COMPONENTS C)
endif()

if(NOT TARGET GSL::gsl)
    find_package(GSL REQUIRED)
endif()

if(NOT TARGET OpenCL::OpenCL)
    find_package(OpenCL REQUIRED)
endif()

# ---------------------------------------------------------------------------
# microsim_kks_opencl
# ---------------------------------------------------------------------------
add_executable(microsim_kks_opencl microsim_kks_opencl.c)

target_include_directories(microsim_kks_opencl PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop
    ${CMAKE_CURRENT_SOURCE_DIR}/tdbs
)

target_link_libraries(microsim_kks_opencl PRIVATE
    MPI::MPI_C
    GSL::gsl
    GSL::gslcblas
    OpenCL::OpenCL
    m
)

# ---------------------------------------------------------------------------
# reconstruct utility
# ---------------------------------------------------------------------------
add_executable(reconstruct reconstruct.c)

target_include_directories(reconstruct PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
)

target_link_libraries(reconstruct PRIVATE
    MPI::MPI_C
    GSL::gsl
    GSL::gslcblas
    m
)

install(TARGETS microsim_kks_opencl reconstruct RUNTIME DESTINATION bin)
