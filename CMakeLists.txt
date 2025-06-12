cmake_minimum_required(VERSION 3.12)

project(PIO_Chip)

set(PICO_SDK_PATH ${CMAKE_CURRENT_SOURCE_DIR}/external/pico-sdk)

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
target_compile_options(sim PRIVATE -std=c++23 -include cassert)
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
add_compile_options(-include cassert)
target_compile_options(unit_tests PRIVATE -std=c++23 -include cassert)
target_include_directories(unit_tests PRIVATE
    ${PICO_SDK_PATH}/src/common/pico_base_headers/include
    ${PICO_SDK_PATH}/src/rp2_common/hardware_pio/include
    ${PICO_SDK_PATH}/src/host/pico_platform/include
    ${CMAKE_SOURCE_DIR}/pico_dummy_files
)

verilate(unit_tests
    SOURCES ${UNIT_TEST_SRCS}
    INCLUDE_DIRS include
    TRACE
    TOP_MODULE test_wrapper
)

enable_testing()
add_test(NAME PioUnitTests COMMAND ${CMAKE_BINARY_DIR}/bin/unit_tests)
