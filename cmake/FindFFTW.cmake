# FindFFTW.cmake
# Finds the FFTW3 library (double precision).
#
# This module defines the following imported target:
#   FFTW::FFTW   - The FFTW3 library
#
# and the following variables:
#   FFTW_FOUND        - True if fftw3 was found
#   FFTW_INCLUDE_DIRS - Include directories
#   FFTW_LIBRARIES    - Libraries to link against
#
# Hints: Set FFTW_ROOT or FFTW_ROOT_DIR to the install prefix of FFTW.

find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_FFTW QUIET fftw3)
endif()

find_path(FFTW_INCLUDE_DIR
    NAMES fftw3.h
    HINTS
        ${FFTW_ROOT}
        ${FFTW_ROOT_DIR}
        ${PC_FFTW_INCLUDEDIR}
        ${PC_FFTW_INCLUDE_DIRS}
    PATH_SUFFIXES include
)

find_library(FFTW_LIBRARY
    NAMES fftw3
    HINTS
        ${FFTW_ROOT}
        ${FFTW_ROOT_DIR}
        ${PC_FFTW_LIBDIR}
        ${PC_FFTW_LIBRARY_DIRS}
    PATH_SUFFIXES lib lib64
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FFTW
    REQUIRED_VARS FFTW_LIBRARY FFTW_INCLUDE_DIR
    VERSION_VAR PC_FFTW_VERSION
)

if(FFTW_FOUND)
    set(FFTW_INCLUDE_DIRS ${FFTW_INCLUDE_DIR})
    set(FFTW_LIBRARIES ${FFTW_LIBRARY})

    if(NOT TARGET FFTW::FFTW)
        add_library(FFTW::FFTW UNKNOWN IMPORTED)
        set_target_properties(FFTW::FFTW PROPERTIES
            IMPORTED_LOCATION "${FFTW_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${FFTW_INCLUDE_DIR}"
        )
    endif()
endif()

mark_as_advanced(FFTW_INCLUDE_DIR FFTW_LIBRARY)
