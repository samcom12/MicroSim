cmake_minimum_required(VERSION 3.20)

# ---------------------------------------------------------------------------
# Project declaration
# Languages are enabled selectively per-solver via sub-directory options.
# CUDA and CXX are listed here so CMake sets them up at the top level if any
# CUDA-capable solver is enabled; solvers that do not need them are unaffected.
# ---------------------------------------------------------------------------
project(MicroSim
    VERSION 1.0
    LANGUAGES C CXX
)

# ---------------------------------------------------------------------------
# Module path for custom Find<Package> modules
# ---------------------------------------------------------------------------
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# ---------------------------------------------------------------------------
# Solver selection options
# ---------------------------------------------------------------------------
option(BUILD_GP_SERIAL    "Build Grand-Potential Serial solver"          ON)
option(BUILD_GP_MPI       "Build Grand-Potential MPI solver"             ON)
option(BUILD_CH_FFT       "Build Cahn-Hilliard FFT 2D solver"            ON)
option(BUILD_KKS_CUFFT    "Build KKS CuFFT (single-GPU CUDA) solver"     ON)
option(BUILD_KKS_CUDA_MPI "Build KKS FD CUDA MPI solver"                 ON)
option(BUILD_KKS_OPENCL   "Build KKS OpenCL solver"                      ON)

# ---------------------------------------------------------------------------
# Shared dependency discovery
# Each sub-directory will use these already-found targets / variables.
# We discover only what is needed by at least one enabled solver.
# ---------------------------------------------------------------------------

# Math library (always needed)
find_library(M_LIBRARY m)

# MPI
if(BUILD_GP_MPI OR BUILD_KKS_CUDA_MPI OR BUILD_KKS_OPENCL)
    find_package(MPI REQUIRED COMPONENTS C)
endif()

# HDF5
if(BUILD_GP_MPI OR BUILD_KKS_CUDA_MPI)
    find_package(HDF5 REQUIRED COMPONENTS C)
endif()

# GSL
if(BUILD_GP_MPI OR BUILD_KKS_CUDA_MPI OR BUILD_KKS_OPENCL)
    find_package(GSL REQUIRED)
endif()

# FFTW3
if(BUILD_CH_FFT)
    find_package(FFTW REQUIRED)
endif()

# OpenCL
if(BUILD_KKS_OPENCL)
    find_package(OpenCL REQUIRED)
endif()

# CUDA / CUDAToolkit
if(BUILD_KKS_CUFFT OR BUILD_KKS_CUDA_MPI)
    enable_language(CUDA)
    find_package(CUDAToolkit REQUIRED)

    # Default GPU architecture if not specified by the user
    if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
        set(CMAKE_CUDA_ARCHITECTURES 70 CACHE STRING
            "CUDA GPU architectures to compile for (e.g. 70;80;90)")
    endif()
endif()

# ---------------------------------------------------------------------------
# Sub-directories
# ---------------------------------------------------------------------------
if(BUILD_GP_SERIAL)
    add_subdirectory(Grand_Potential_Serial)
endif()

if(BUILD_GP_MPI)
    add_subdirectory(Grand_Potential_MPI)
endif()

if(BUILD_CH_FFT)
    add_subdirectory(Cahn_Hilliard_FFT_2D)
endif()

if(BUILD_KKS_CUFFT)
    add_subdirectory(KKS_CuFFT)
endif()

if(BUILD_KKS_CUDA_MPI)
    add_subdirectory(KKS_FD_CUDA_MPI)
endif()

if(BUILD_KKS_OPENCL)
    add_subdirectory(KKS_OpenCl)
endif()
