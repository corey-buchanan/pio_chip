#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

#define DEBUG_PRINT 0

class OutputShiftRegisterTests : public ::testing::Test {
protected:
    Vtest_wrapper* uut;

    void SetUp() override {
        uut = new Vtest_wrapper;

        uut->clk = 0;
        uut->rst = 0;
        uut->mov_in = 0x00000000;
        uut->mov_en = 0;
        uut->fifo_in = 0x00000000;
        uut->fifo_pull = 0;
        uut->shift_en = 0;
        uut->pull_thresh = 0b00000; // Encoding for 32
        uut->shiftdir = 0;
        uut->autopull = 0;
        uut->shift_count = 0b00000;
        uut->osr = 0x00000000;

        uut->eval();
    }

    void TearDown() override {
        delete uut;
    }

    // Generates a rising edge
    void AdvanceOneCycle() {
        uut->clk = 0;
        uut->eval();
        uut->clk = 1;
        uut->eval();

        #if DEBUG_PRINT
        // TODO: Add a helpful print statement
        #endif
    }
};

// TODO: Implement tests

TEST_F(OutputShiftRegisterTests, MovFillsEmptyOsr) {
    uut->mov_in = 0x01234567;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000); // Don't change value if mov_en isn't set

    uut->mov_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x01234567);

    uut->mov_en = 0;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x01234567); // Test persistence
}

TEST_F(OutputShiftRegisterTests, MovReplacesFullOsr) {
    uut->mov_in = 0xBEEEEEEF;
    uut->mov_en = 1;
    AdvanceOneCycle();

    uut->mov_in = 0xC4C4C4C4;
    uut->mov_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0xC4C4C4C4);
}

TEST_F(OutputShiftRegisterTests, OutShiftsBitsToDataOut) {
    // Initial value
    uut->mov_in = 0x87654321;
    uut->mov_en = 1;
    uut->eval();
    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x87654321);

    // Shift count of 32
    uut->shift_en = 1;
    uut->mov_en = 0;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_data_out, 0x87654321);

    // Set up next initial value
    uut->mov_in = 0x87654321;
    uut->mov_en = 1;
    uut->shift_en = 0;
    AdvanceOneCycle();

    // TODO: Figure out if osr should hold output values between shifts
    // EXPECT_EQ(uut->osr_data_out, 0x87654321);
    EXPECT_EQ(uut->osr_data_out, 0x00000000);

    // Shift count of 4
    uut->mov_en = 0;
    uut->shift_count = 0x04;
    uut->shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x76543210);
    EXPECT_EQ(uut->osr_data_out, 0x00000008);

    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x65432100);
    EXPECT_EQ(uut->osr_data_out, 0x00000007);
}

TEST_F(OutputShiftRegisterTests, OutShiftsWeirdNumberOfBitsToDataOut) {
    // Set up next initial value
    uut->mov_in = 0xFFFFFFFF;
    uut->mov_en = 1;
    uut->shift_en = 0;
    AdvanceOneCycle();

    // Shift count of 31
    uut->mov_en = 0;
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
    uut->mov_en = 1;
    uut->shift_en = 0;
    AdvanceOneCycle();

    // Shift count of 1
    uut->mov_en = 0;
    uut->shift_count = 0x01;
    uut->shift_en = 1;
    
    for (int i = 1; i <= 32; i++) {
        bool expected = bit_stream >> (32 - i) & 0b1;
        AdvanceOneCycle();
        EXPECT_EQ(uut->osr, bit_stream << i & 0xFFFFFFFF);
        EXPECT_EQ(uut->osr_data_out, expected);
    }
}

TEST_F(OutputShiftRegisterTests, DataOutClearedBetweenShifts) {

}

TEST_F(OutputShiftRegisterTests, OutShiftDirectionChanges) {

}

TEST_F(OutputShiftRegisterTests, OutShiftsZerosAfterEmpty) {

}

TEST_F(OutputShiftRegisterTests, FifoPullRefillsFromEmpty) {

}

TEST_F(OutputShiftRegisterTests, FifoPullRefillsFromPartiallyEmpty) {

}

TEST_F(OutputShiftRegisterTests, FifoPullWhenAlreadyFull) {

}

TEST_F(OutputShiftRegisterTests, AutopullRefillsWhenThresholdMet) {

}

TEST_F(OutputShiftRegisterTests, AutopullRefillsDirectionChanged) {

}

TEST_F(OutputShiftRegisterTests, AutopullOnEmpty) {

}

TEST_F(OutputShiftRegisterTests, AutopullOnSingleBitMoved) {

}