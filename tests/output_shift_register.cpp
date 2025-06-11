#include "test_utils.h"

class OutputShiftRegisterTests : public VerilatorTestFixture {
protected:
    void SetUp() override {
        VerilatorTestFixture::SetUp();

        uut->osr_data_in = 0x00000000;
        uut->osr_load = 0;
        uut->osr_shift_en = 0;
        uut->osr_shiftdir = 0; // Left shift
        uut->osr_shift_count = 0b100000; // 32

        uut->eval();
    }
};

TEST_F(OutputShiftRegisterTests, MovOrPullFillsEmptyOsr) {
    uut->osr_data_in = 0x01234567;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000); // Don't change value if load isn't set

    uut->osr_load = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x01234567);

    uut->osr_load = 0;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x01234567); // Test persistence
}

TEST_F(OutputShiftRegisterTests, MovOrPullReplacesFullOsr) {
    uut->osr_data_in = 0xBEEEEEEF;
    uut->osr_load = 1;
    AdvanceOneCycle();

    uut->osr_data_in = 0xC4C4C4C4;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0xC4C4C4C4);
}

TEST_F(OutputShiftRegisterTests, OutShiftsBitsToDataOut) {
    // Initial value
    uut->osr_data_in = 0x87654321;
    uut->osr_load = 1;
    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x87654321);

    // Default shift 32 bits
    uut->osr_load = 0;
    uut->osr_shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_shift_out, 0x87654321);
}

TEST_F(OutputShiftRegisterTests, OutShiftsWeirdNumberOfBitsToDataOut) {
    // Set up next initial value
    uut->osr_data_in = 0xFFFFFFFF;
    uut->osr_load = 1;
    AdvanceOneCycle();

    // Shift count of 31
    uut->osr_load = 0;
    uut->osr_shift_count = 0x1F;
    uut->osr_shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x80000000);
    EXPECT_EQ(uut->osr_shift_out, 0x7FFFFFFF);

    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_shift_out, 0x40000000);
}

TEST_F(OutputShiftRegisterTests, OutShiftsBitsToDataOut1By1) {
    // Shifting by >= length of int is undefined behavior in C++, so we use long type
    uint64_t bit_stream = 0x897AF101;
    uut->osr_data_in = bit_stream;
    uut->osr_load = 1;
    AdvanceOneCycle();

    // Shift count of 1
    uut->osr_load = 0;
    uut->osr_shift_count = 0x01;
    uut->osr_shift_en = 1;
    
    for (int i = 1; i <= 32; i++) {
        short expected = bit_stream >> (32 - i) & 0b1;
        AdvanceOneCycle();
        EXPECT_EQ(uut->osr, bit_stream << i & 0xFFFFFFFF);
        EXPECT_EQ(uut->osr_shift_out, expected);
    }
}

TEST_F(OutputShiftRegisterTests, DataOutHoldsBetweenShifts) {
    // Initial value
    uut->osr_data_in = 0x87654321;
    uut->osr_load = 1;
    AdvanceOneCycle();

    // Shift count of 4
    uut->osr_load = 0;
    uut->osr_shift_count = 0x04;
    uut->osr_shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x76543210);
    EXPECT_EQ(uut->osr_shift_out, 0x00000008);

    // Shift occurs, so shift_out is replaced
    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x65432100);
    EXPECT_EQ(uut->osr_shift_out, 0x00000007);

    uut->osr_shift_en = 0;
    AdvanceOneCycle();

    // Expect shift_out to hold value if nothing is happening
    EXPECT_EQ(uut->osr_shift_out, 0x00000007);
}

TEST_F(OutputShiftRegisterTests, OutRightShift) {
    // Initial value
    uut->osr_data_in = 0x87654321;
    uut->osr_load = 1;
    AdvanceOneCycle();

    // Shift right
    uut->osr_load = 0;
    uut->osr_shift_count = 0x04;
    uut->osr_shift_en = 1;
    uut->osr_shiftdir = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x08765432);
    EXPECT_EQ(uut->osr_shift_out, 0x00000001);

    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00876543);
    EXPECT_EQ(uut->osr_shift_out, 0x00000002);

    uut->osr_shift_en = 0;
    AdvanceOneCycle();
}

TEST_F(OutputShiftRegisterTests, OutShiftDirectionChanges) {
    // Initial value
    uut->osr_data_in = 0x55555555;
    uut->osr_load = 1;
    AdvanceOneCycle();

    // Shift right
    uut->osr_load = 0;
    uut->osr_shift_count = 0x08;
    uut->osr_shift_en = 1;
    uut->osr_shiftdir = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00555555);
    EXPECT_EQ(uut->osr_shift_out, 0x00000055);

    // Shift left
    uut->osr_shiftdir = 0;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x55555500);
    EXPECT_EQ(uut->osr_shift_out, 0x00000000);

    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x55550000);
    EXPECT_EQ(uut->osr_shift_out, 0x00000055);

    uut->osr_shift_en = 0;
    AdvanceOneCycle();
}

TEST_F(OutputShiftRegisterTests, OutShiftsZerosAfterEmpty) {
    // Initial value
    uut->osr_data_in = 0xBAADD00D;
    uut->osr_load = 1;
    AdvanceOneCycle();

    // Shift count of 32
    uut->osr_load = 0;
    uut->osr_shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_shift_out, 0xBAADD00D);

    for (int i = 0; i < 10; i++) {
        AdvanceOneCycle();
        EXPECT_EQ(uut->osr, 0x00000000);
        EXPECT_EQ(uut->osr_shift_out, 0x00000000);
    }
}
