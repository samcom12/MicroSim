cmake_minimum_required(VERSION 3.20)
project(MicroSim_KKS_FD_CUDA_MPI LANGUAGES C CXX CUDA)

# ---------------------------------------------------------------------------
# KKS Finite-Difference CUDA MPI solver
#
# Dependencies: MPI, HDF5 (C, parallel), GSL, CUDA toolkit
# Optional: cuFFTMp (ENABLE_CUFFTMP), HDF5 output (ENABLE_HDF5)
#
# Targets: microsim_kks_fd_cuda_mpi, write_xdmf, reconstruct
# ---------------------------------------------------------------------------

option(ENABLE_HDF5   "Enable HDF5 output in KKS_FD_CUDA_MPI"   ON)
option(ENABLE_CUFFTMP "Enable cuFFTMp in KKS_FD_CUDA_MPI"      ON)

# --- Find dependencies when built standalone ---
if(NOT TARGET MPI::MPI_C)
    find_package(MPI REQUIRED COMPONENTS C CXX)
endif()

if(ENABLE_HDF5 AND NOT HDF5_FOUND)
    find_package(HDF5 REQUIRED COMPONENTS C)
endif()

if(NOT TARGET GSL::gsl)
    find_package(GSL REQUIRED)
endif()

if(NOT CUDAToolkit_FOUND)
    find_package(CUDAToolkit REQUIRED)
endif()

# Default GPU architecture
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES 70 CACHE STRING
        "CUDA GPU architectures to compile for (e.g. 70;80;90)")
endif()

# ---------------------------------------------------------------------------
# Optional cuFFTMp paths (user-supplied via cache variables)
# ---------------------------------------------------------------------------
set(NVHPC_ROOT "/opt/nvidia" CACHE PATH "NVIDIA HPC SDK root")
# Override HPCSDK_VERSION to match your installed HPC SDK (e.g. 23.7, 24.1).
set(HPCSDK_VERSION "23.3" CACHE STRING "HPC SDK version (override to match your installation)")
set(NVHPC_HOME "${NVHPC_ROOT}/hpc_sdk/Linux_x86_64/${HPCSDK_VERSION}")

if(ENABLE_CUFFTMP)
    set(CUFFT_INC  "${NVHPC_HOME}/math_libs/include/cufftmp" CACHE PATH "cuFFTMp include directory")
    set(CUFFT_LIB  "${NVHPC_HOME}/math_libs/lib64"           CACHE PATH "cuFFTMp library directory")
endif()

# ---------------------------------------------------------------------------
# Helper: common include directories shared by all targets
# ---------------------------------------------------------------------------
set(_KKS_CUDA_MPI_INCLUDES
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop
    ${CMAKE_CURRENT_SOURCE_DIR}/tdbs
)
if(ENABLE_HDF5)
    list(APPEND _KKS_CUDA_MPI_INCLUDES ${HDF5_INCLUDE_DIRS})
endif()
if(ENABLE_CUFFTMP)
    list(APPEND _KKS_CUDA_MPI_INCLUDES ${CUFFT_INC})
endif()

# ---------------------------------------------------------------------------
# Collect source files
# ---------------------------------------------------------------------------

# Host (C / C++) sources
set(HOST_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/microsim_kks_fd_cuda_mpi.c
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/fileWriter.c
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/utilityFunctions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/initialize_variables.c
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/filling.c
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/reading_input_parameters.c
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/fill_domain.c
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/read_boundary_conditions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/calc_bn.c
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/error_checks.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/box_iterator.cpp
)

# Device (CUDA) sources
set(DEVICE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/tdbs/Thermo.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/functionF.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/functionH.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/functionTau.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/functionW_02.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/anisotropy_01.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/functionA_01.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/functionA_02.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/functions/matrix.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/utilityKernels.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/boundary.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/calcPhaseComp.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/smooth.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/computeDrivingForce.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/computeElastic.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/updateComposition.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop/updatePhi.cu
)

# ---------------------------------------------------------------------------
# Main solver target
# ---------------------------------------------------------------------------
add_executable(microsim_kks_fd_cuda_mpi
    ${HOST_SOURCES}
    ${DEVICE_SOURCES}
)

# Separable compilation is required for device-side linking across TUs
set_target_properties(microsim_kks_fd_cuda_mpi PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    # Allow C++17 features used in computeElastic.cu
    CUDA_STANDARD 17
    CUDA_STANDARD_REQUIRED ON
)

target_include_directories(microsim_kks_fd_cuda_mpi PRIVATE
    ${_KKS_CUDA_MPI_INCLUDES}
)

target_compile_definitions(microsim_kks_fd_cuda_mpi PRIVATE
    ENABLE_HDF5=$<BOOL:${ENABLE_HDF5}>
    ENABLE_CUFFTMP=$<BOOL:${ENABLE_CUFFTMP}>
)

target_compile_options(microsim_kks_fd_cuda_mpi PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:
        -Xcompiler -march=native
        --diag_suppress=declared_but_not_referenced
        --diag_suppress=set_but_not_used
    >
)

# Link libraries
set(_KKS_CUDA_MPI_LIBS
    MPI::MPI_C
    GSL::gsl
    GSL::gslcblas
    CUDA::cudart
    m
)

if(ENABLE_HDF5)
    list(APPEND _KKS_CUDA_MPI_LIBS ${HDF5_C_LIBRARIES})
endif()

if(ENABLE_CUFFTMP)
    # Use an imported target for cuFFTMp so CMake can track the dependency
    # correctly.  Users can override CUFFT_LIB via the cache variable.
    add_library(cuFFTMp SHARED IMPORTED)
    set_target_properties(cuFFTMp PROPERTIES
        IMPORTED_LOCATION "${CUFFT_LIB}/libcufftMp.so"
        INTERFACE_INCLUDE_DIRECTORIES "${CUFFT_INC}"
    )
    list(APPEND _KKS_CUDA_MPI_LIBS cuFFTMp)
else()
    list(APPEND _KKS_CUDA_MPI_LIBS CUDA::cufft)
endif()

target_link_libraries(microsim_kks_fd_cuda_mpi PRIVATE ${_KKS_CUDA_MPI_LIBS})

# ---------------------------------------------------------------------------
# write_xdmf utility
# ---------------------------------------------------------------------------
add_executable(write_xdmf_kks write_xdmf.c)
set_target_properties(write_xdmf_kks PROPERTIES OUTPUT_NAME write_xdmf)

target_include_directories(write_xdmf_kks PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop
    ${HDF5_INCLUDE_DIRS}
)

target_compile_definitions(write_xdmf_kks PRIVATE THERMO=0)

target_link_libraries(write_xdmf_kks PRIVATE
    MPI::MPI_C
    ${HDF5_C_LIBRARIES}
    CUDA::cudart
    m
)

# ---------------------------------------------------------------------------
# reconstruct utility
# ---------------------------------------------------------------------------
add_executable(reconstruct_kks reconstruct.c)
set_target_properties(reconstruct_kks PROPERTIES OUTPUT_NAME reconstruct)

target_include_directories(reconstruct_kks PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop
    ${HDF5_INCLUDE_DIRS}
)

target_compile_definitions(reconstruct_kks PRIVATE THERMO=0)

target_link_libraries(reconstruct_kks PRIVATE
    MPI::MPI_C
    ${HDF5_C_LIBRARIES}
    CUDA::cudart
    m
)

install(TARGETS microsim_kks_fd_cuda_mpi write_xdmf_kks reconstruct_kks
    RUNTIME DESTINATION bin)
