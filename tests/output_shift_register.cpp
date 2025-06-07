#include "test_utils.h"

class OutputShiftRegisterTests : public VerilatorTestFixture {
protected:
    void SetUp() override {
        VerilatorTestFixture::SetUp();

        uut->mov_in = 0x00000000;
        uut->mov = 0b00;
        uut->fifo_in = 0x00000000;
        uut->fifo_pull = 0;
        uut->shift_en = 0;
        uut->pull_thresh = 0b00000; // Encoding for 32
        uut->shiftdir = 0;
        uut->autopull = 0;
        uut->shift_count = 0b00000; // Encoding for 32
        uut->osr = 0x00000000;

        uut->eval();
    }
};

// TODO: Implement rest of tests

TEST_F(OutputShiftRegisterTests, MovFillsEmptyOsr) {
    uut->mov_in = 0x01234567;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000); // Don't change value if mov isn't set

    uut->mov = 0b01;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x01234567);

    uut->mov = 0b00;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x01234567); // Test persistence
}

TEST_F(OutputShiftRegisterTests, MovReplacesFullOsr) {
    uut->mov_in = 0xBEEEEEEF;
    uut->mov = 0b01;
    AdvanceOneCycle();

    uut->mov_in = 0xC4C4C4C4;
    uut->mov = 0b01;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0xC4C4C4C4);
}

TEST_F(OutputShiftRegisterTests, OutShiftsBitsToDataOut) {
    // Initial value
    uut->mov_in = 0x87654321;
    uut->mov = 0b01;
    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x87654321);

    // Shift count of 32
    uut->shift_en = 1;
    uut->mov = 0b00;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_data_out, 0x87654321);
}

TEST_F(OutputShiftRegisterTests, OutShiftsWeirdNumberOfBitsToDataOut) {
    // Set up next initial value
    uut->mov_in = 0xFFFFFFFF;
    uut->mov = 0b01;
    uut->shift_en = 0;
    AdvanceOneCycle();

    // Shift count of 31
    uut->mov = 0b00;
    uut->shift_count = 0x1F;
    uut->shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x80000000);
    EXPECT_EQ(uut->osr_data_out, 0x7FFFFFFF);

    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_data_out, 0x40000000);
}

TEST_F(OutputShiftRegisterTests, OutShiftsBitsToDataOut1By1) {
    // Shifting by >= length of int is undefined behavior in C++, so we use long type
    unsigned long bit_stream = 0x897AF101;
    uut->mov_in = bit_stream;
    uut->mov = 0b01;
    uut->shift_en = 0;
    AdvanceOneCycle();

    // Shift count of 1
    uut->mov = 0b00;
    uut->shift_count = 0x01;
    uut->shift_en = 1;
    
    for (int i = 1; i <= 32; i++) {
        short expected = bit_stream >> (32 - i) & 0b1;
        AdvanceOneCycle();
        EXPECT_EQ(uut->osr, bit_stream << i & 0xFFFFFFFF);
        EXPECT_EQ(uut->osr_data_out, expected);
    }
}

TEST_F(OutputShiftRegisterTests, DataOutHoldsBetweenShifts) {
    // Initial value
    uut->mov_in = 0x87654321;
    uut->mov = 0b01;
    AdvanceOneCycle();

    // Shift count of 4
    uut->mov = 0b00;
    uut->shift_count = 0x04;
    uut->shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x76543210);
    EXPECT_EQ(uut->osr_data_out, 0x00000008);

    // Shift occurs, so data_out is replaced
    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x65432100);
    EXPECT_EQ(uut->osr_data_out, 0x00000007);

    uut->shift_en = 0;
    AdvanceOneCycle();

    // Expect data_out to hold value if nothing is happening
    EXPECT_EQ(uut->osr_data_out, 0x00000007);
}

TEST_F(OutputShiftRegisterTests, OutRightShift) {
    // Initial value
    uut->mov_in = 0x87654321;
    uut->mov = 0b01;
    AdvanceOneCycle();

    // Shift right
    uut->mov = 0b00;
    uut->shift_count = 0x04;
    uut->shift_en = 1;
    uut->shiftdir = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x08765432);
    EXPECT_EQ(uut->osr_data_out, 0x00000008);

    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00876543);
    EXPECT_EQ(uut->osr_data_out, 0x00000004);

    uut->shift_en = 0;
    AdvanceOneCycle();
}

TEST_F(OutputShiftRegisterTests, OutShiftDirectionChanges) {
    // Initial value
    uut->mov_in = 0x55555555;
    uut->mov = 0b01;
    AdvanceOneCycle();

    // Shift right
    uut->mov = 0b00;
    uut->shift_count = 0x08;
    uut->shift_en = 1;
    uut->shiftdir = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00555555);
    EXPECT_EQ(uut->osr_data_out, 0x000000AA);

    // Shift left
    uut->shiftdir = 0;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x55555500);
    EXPECT_EQ(uut->osr_data_out, 0x00000000);

    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x55550000);
    EXPECT_EQ(uut->osr_data_out, 0x00000055);

    uut->shift_en = 0;
    AdvanceOneCycle();
}

TEST_F(OutputShiftRegisterTests, OutShiftsZerosAfterEmpty) {
    // Initial value
    uut->mov_in = 0xBAADD00D;
    uut->mov = 0b01;
    AdvanceOneCycle();

    // Shift count of 32
    uut->shift_en = 1;
    uut->mov = 0b00;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_data_out, 0xBAADD00D);

    for (int i = 0; i < 10; i++) {
        AdvanceOneCycle();
        EXPECT_EQ(uut->osr, 0x00000000);
        EXPECT_EQ(uut->osr_data_out, 0x00000000);
    }
}

TEST_F(OutputShiftRegisterTests, FifoPullRefillsFromEmpty) {
    uut->shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_data_out, 0x00000000);
    EXPECT_EQ(uut->output_shift_counter, 32);

    uut->shift_en = 0;
    uut->fifo_in = 0xACDCACDC;
    uut->fifo_pull = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x3B353B35);
    EXPECT_EQ(uut->fifo_pulled, 1);
    EXPECT_EQ(uut->output_shift_counter, 0);

    uut->fifo_pull = 0;
    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x3B353B35);
    EXPECT_EQ(uut->fifo_pulled, 0);
}

TEST_F(OutputShiftRegisterTests, FifoPullRefillsFromPartiallyEmpty) {
    // Initial value
    uut->mov_in = 0x1BADCD00;
    uut->mov = 0b01;
    AdvanceOneCycle();

    // Shift by 16
    uut->mov = 0b00;
    uut->shift_count = 0x10;
    uut->shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0xCD000000);
    EXPECT_EQ(uut->osr_data_out, 0x00001BAD);
    EXPECT_EQ(uut->output_shift_counter, 16);

    uut->shift_en = 0;
    uut->fifo_in = 0xACDCACDC;
    uut->fifo_pull = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0xCD003B35);
    EXPECT_EQ(uut->fifo_pulled, 1);
    EXPECT_EQ(uut->output_shift_counter, 0);
}

TEST_F(OutputShiftRegisterTests, FifoPullWhenAlreadyFull) {
    uut->mov_in = 0x33333333;
    uut->mov = 0b01;
    AdvanceOneCycle();

    EXPECT_EQ(uut->output_shift_counter, 0);

}

TEST_F(OutputShiftRegisterTests, AutopullRefillsWhenThresholdMet) {

}

TEST_F(OutputShiftRegisterTests, AutopullRefillsDirectionChanged) {

}

TEST_F(OutputShiftRegisterTests, AutopullOnEmpty) {

}

TEST_F(OutputShiftRegisterTests, AutopullOnSingleBitMoved) {

}