#include "test_utils.h"

class GpioTests : public VerilatorTestFixture {
protected:
    void SetUp() override {
        VerilatorTestFixture::SetUp();

        uut->out_data = 0x00000000;
        uut->sync_bypass = 0x00000000;
        uut->dir = 0x00000000;
    }
};

// There is some difficulty in testing this fully, as
// verilator can't simulate high impedence ('bz) signals
// I will implement some separate test bench tests.

TEST_F(GpioTests, NoInputReadWhenDirIsOne) {
    uut->gpio = 0xAAAAAAAA;
    uut->dir = 0xFFFFFFFF;
    uut->clk = 1;
    uut->eval();

    EXPECT_EQ(uut->in_data, 0x00000000);
}

TEST_F(GpioTests, OutputDrivenWhenDirIsOne) {
    uut->out_data = 0x55555555;
    uut->dir = 0xFFFFFFFF;
    uut->eval();

    EXPECT_EQ(uut->gpio, 0x55555555);
}

TEST_F(GpioTests, PullupResistorHandling) {
    uut->pue = 0xFFFFFFFF;
    uut->eval();

    EXPECT_EQ(uut->gpio, 0xFFFFFFFF);
}

TEST_F(GpioTests, PullDownResistorHandling) {
    uut->pde = 0xFFFFFFFF;
    uut->eval();

    // Really not that meaningful with verilator - bz also shows as zeroes
    EXPECT_EQ(uut->gpio, 0x00000000);
}

TEST_F(GpioTests, TestPinsSetToDifferentDirections) {
    uut->out_data = 0xFFFFFFFF;
    uut->dir = 0xCCCCCCCC; // Acts as kindof a mask on the output data
    uut->eval();

    EXPECT_EQ(uut->gpio, 0xCCCCCCCC);

    uut->out_data = 0x33333333;         // 0011 repeating
    uut->dir = 0x11111111;              // 0001 repeating
    uut->pue = 0x44444444;              // 0100 repeating
    uut->eval();

    EXPECT_EQ(uut->gpio, 0x55555555);   // 0101 repeating
}