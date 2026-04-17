cmake_minimum_required(VERSION 3.20)
project(MicroSim_CH_FFT LANGUAGES C)

# ---------------------------------------------------------------------------
# Cahn-Hilliard FFT 2D solver
#
# Dependency: FFTW3 (double precision)
# Target: microsim_ch_fft
#
# When built as part of the top-level project FFTW is already discovered;
# when built standalone we find it here via the bundled FindFFTW module.
# ---------------------------------------------------------------------------

if(NOT TARGET FFTW::FFTW)
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")
    find_package(FFTW REQUIRED)
endif()

add_executable(microsim_ch_fft microsim_ch_fft.c)

target_include_directories(microsim_ch_fft PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop
)

target_link_libraries(microsim_ch_fft PRIVATE
    FFTW::FFTW
    m
)

install(TARGETS microsim_ch_fft RUNTIME DESTINATION bin)
