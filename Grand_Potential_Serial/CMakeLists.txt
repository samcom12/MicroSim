cmake_minimum_required(VERSION 3.20)
project(MicroSim_GP_Serial LANGUAGES C)

# ---------------------------------------------------------------------------
# Grand-Potential Serial solver
#
# Single translation-unit build: all logic lives in header files that are
# #included by microsim_gp.c.  The headers under functions/ and solverloop/
# are added as include directories so the compiler can locate them.
# ---------------------------------------------------------------------------

add_executable(microsim_gp microsim_gp.c)

target_include_directories(microsim_gp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/functions
    ${CMAKE_CURRENT_SOURCE_DIR}/solverloop
)

# Only dependency is the math library
target_link_libraries(microsim_gp PRIVATE m)

install(TARGETS microsim_gp RUNTIME DESTINATION bin)
