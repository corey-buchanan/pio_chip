cmake_minimum_required(VERSION 3.12)

project(PIO_Chip)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

set(SIM_SRCS
    src/pio_chip.v
    src/fsm.v
    src/instruction_regfile.v
    src/program_counter.v
    src/pio_core.v
    src/gpio.v
    src/control_regfile.v
    src/fsm_output_arbitrator.v
    src/core_output_arbitrator.v
    src/output_shift_register.v
)

set(UNIT_TEST_SRCS
    src/test_wrapper.v
    src/pio_chip.v
    src/fsm.v
    src/instruction_regfile.v
    src/program_counter.v
    src/pio_core.v
    src/gpio.v
    src/control_regfile.v
    src/fsm_output_arbitrator.v
    src/core_output_arbitrator.v
    src/output_shift_register.v
)

set(UNIT_TEST_C_SRCS
    tests/program_counter.cpp
    tests/instruction_regfile.cpp
    tests/fsm.cpp
    tests/gpio.cpp
    tests/fsm_output_arbitrator.cpp
    tests/core_output_arbitrator.cpp
    tests/output_shift_register.cpp
)

# Main sim
add_executable(sim tb/tb_main.cpp)
target_compile_options(sim PRIVATE -std=c++23)
verilate(sim SOURCES ${SIM_SRCS} TRACE TOP_MODULE pio_chip)

# Unit tests
add_subdirectory(lib/googletest)
add_executable(unit_tests ${UNIT_TEST_C_SRCS})
set_target_properties(unit_tests PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
target_link_libraries(unit_tests PRIVATE gtest gtest_main)
target_compile_options(unit_tests PRIVATE -std=c++23)
verilate(unit_tests SOURCES ${UNIT_TEST_SRCS} TRACE TOP_MODULE test_wrapper)

enable_testing()
add_test(NAME PioUnitTests COMMAND ${CMAKE_BINARY_DIR}/bin/unit_tests)
