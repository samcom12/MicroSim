cmake_minimum_required(VERSION 3.20)
project(MicroSim_GP_MPI LANGUAGES C)

# ---------------------------------------------------------------------------
# Grand-Potential MPI solver
#
# Dependencies: MPI, HDF5 (C, parallel), GSL
# Targets: microsim_gp, write_xdmf, reconstruct
#
# When built as part of the top-level project these packages are already
# discovered; when built standalone we find them here.
# ---------------------------------------------------------------------------

if(NOT TARGET MPI::MPI_C)
    find_package(MPI REQUIRED COMPONENTS C)
endif()

if(NOT HDF5_FOUND)
    find_package(HDF5 REQUIRED COMPONENTS C)
endif()

if(NOT TARGET GSL::gsl)
    find_package(GSL REQUIRED)
endif()

# ---------------------------------------------------------------------------
# microsim_gp
# ---------------------------------------------------------------------------
add_executable(microsim_gp microsim_gp.c)

target_include_directories(microsim_gp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop
    ${CMAKE_CURRENT_SOURCE_DIR}/tdbs
    ${HDF5_INCLUDE_DIRS}
)

target_link_libraries(microsim_gp PRIVATE
    MPI::MPI_C
    ${HDF5_C_LIBRARIES}
    GSL::gsl
    GSL::gslcblas
    m
)

# ---------------------------------------------------------------------------
# write_xdmf  (converts HDF5 output files to XDMF/XML for ParaView)
# ---------------------------------------------------------------------------
add_executable(write_xdmf write_xdmf.c)

target_include_directories(write_xdmf PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${HDF5_INCLUDE_DIRS}
)

target_link_libraries(write_xdmf PRIVATE
    MPI::MPI_C
    ${HDF5_C_LIBRARIES}
    GSL::gsl
    GSL::gslcblas
    m
)

# ---------------------------------------------------------------------------
# reconstruct  (consolidates per-processor VTK files)
# ---------------------------------------------------------------------------
add_executable(reconstruct reconstruct.c)

target_include_directories(reconstruct PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${HDF5_INCLUDE_DIRS}
)

target_link_libraries(reconstruct PRIVATE
    MPI::MPI_C
    ${HDF5_C_LIBRARIES}
    GSL::gsl
    GSL::gslcblas
    m
)

install(TARGETS microsim_gp write_xdmf reconstruct RUNTIME DESTINATION bin)
