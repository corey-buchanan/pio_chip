#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

class OutputShiftRegisterTests : public ::testing::Test {
protected:
    Vtest_wrapper* uut;

    void SetUp() override {
        uut = new Vtest_wrapper;

        uut->clk = 0;
        uut->rst = 0;

        // TODO: Implement initial values

        uut->eval();
    }

    void TearDown() override {
        delete uut;
    }
};

// TODO: Implement tests

TEST_F(OutputShiftRegisterTests, MovFillsEmptyOsr) {

}

TEST_F(OutputShiftRegisterTests, MovReplacesFullOsr) {

}

TEST_F(OutputShiftRegisterTests, OutShiftsBitsToDataOut) {

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