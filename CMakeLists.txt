cmake_minimum_required(VERSION 3.12)

project(PIO_Chip)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

set(SIM_SRCS
    src/pio_chip.v
    src/fsm.v
    src/instruction_regfile.v
    src/program_counter.v
)

set(UNIT_TEST_SRCS
    src/test_wrapper.v
    src/pio_chip.v
    src/fsm.v
    src/instruction_regfile.v
    src/program_counter.v
)

# Main sim
add_executable(sim tb/tb_main.cpp)
target_compile_options(sim PRIVATE -std=c++23)
verilate(sim SOURCES ${SIM_SRCS} TRACE TOP_MODULE pio_chip)

# Unit tests
add_subdirectory(lib/googletest)
add_executable(unit_tests tb/tb_unit_tests.cpp)
set_target_properties(unit_tests PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
target_link_libraries(unit_tests PRIVATE gtest gtest_main)
target_compile_options(unit_tests PRIVATE -std=c++23)
verilate(unit_tests SOURCES ${UNIT_TEST_SRCS} TRACE TOP_MODULE test_wrapper)

enable_testing()
add_test(NAME PioUnitTests COMMAND ${CMAKE_BINARY_DIR}/bin/unit_tests)
