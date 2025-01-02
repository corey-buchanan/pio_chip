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

    // Don't change value if mov_en isn't set
    EXPECT_EQ(uut->osr, 0x00000000);

    uut->mov_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x01234567);
}

TEST_F(OutputShiftRegisterTests, MovReplacesFullOsr) {
    uut->osr = 0xBEEEEEEF;
    uut->eval();
    
    // Ensure we can preload the OSR
    // Not part of the chip, just a function of the simulation
    EXPECT_EQ(uut->osr, 0xBEEEEEEF);

    uut->mov_in = 0xC4C4C4C4;
    uut->mov_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0xC4C4C4C4);
}

TEST_F(OutputShiftRegisterTests, OutShiftsBitsToDataOut) {
    uut->osr = 0x87654321;
    uut->eval();
    AdvanceOneCycle();
    EXPECT_EQ(uut->osr, 0x87654321);

    // Shift count of 32
    uut->shift_en = 1;
    AdvanceOneCycle();

    EXPECT_EQ(uut->osr, 0x00000000);
    EXPECT_EQ(uut->osr_data_out, 0x87654321);
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