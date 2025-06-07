cmake_minimum_required(VERSION 3.12)

project(PIO_Chip)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

set(SIM_SRCS
    src/pio_chip.sv
    src/fsm.sv
    src/instruction_regfile.sv
    src/program_counter.sv
    src/pio_core.sv
    src/gpio.sv
    src/control_regfile.sv
    src/fsm_output_arbitrator.sv
    src/core_output_arbitrator.sv
    src/output_shift_register.sv
    src/fifo.sv
)

set(UNIT_TEST_SRCS
    src/test_wrapper.sv
    src/pio_chip.sv
    src/fsm.sv
    src/instruction_regfile.sv
    src/program_counter.sv
    src/pio_core.sv
    src/gpio.sv
    src/control_regfile.sv
    src/fsm_output_arbitrator.sv
    src/core_output_arbitrator.sv
    src/output_shift_register.sv
    src/fifo.sv
)

set(UNIT_TEST_C_SRCS
    tests/program_counter.cpp
    tests/instruction_regfile.cpp
    tests/fsm.cpp
    tests/gpio.cpp
    tests/fsm_output_arbitrator.cpp
    tests/core_output_arbitrator.cpp
    tests/output_shift_register.cpp
    tests/fifo.cpp
)

# Main sim
add_executable(sim tb/tb_main.cpp)
target_compile_options(sim PRIVATE -std=c++23)
verilate(sim
    SOURCES ${SIM_SRCS}
    INCLUDE_DIRS include
    TRACE
    TOP_MODULE pio_chip
)

# Unit tests
add_subdirectory(lib/googletest)
add_executable(unit_tests ${UNIT_TEST_C_SRCS})
set_target_properties(unit_tests PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
target_link_libraries(unit_tests PRIVATE gtest gtest_main)
target_compile_options(unit_tests PRIVATE -std=c++23)
verilate(unit_tests
    SOURCES ${UNIT_TEST_SRCS}
    INCLUDE_DIRS include
    TRACE
    TOP_MODULE test_wrapper
)

enable_testing()
add_test(NAME PioUnitTests COMMAND ${CMAKE_BINARY_DIR}/bin/unit_tests)
