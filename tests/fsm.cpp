#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

class FsmTests : public ::testing::Test {
protected:
    Vtest_wrapper* uut;

    void SetUp() override {
        uut = new Vtest_wrapper;
        uut->clk = 0;
        uut->rst = 0;
        uut->instruction = 0b0000'0000'0000'0000;
        uut->eval();

        // Reset the program counter and scratch registers
        uut->rst = 1;
        uut->eval();
        uut->rst = 0;
        uut->eval();
    }

    void TearDown() override {
        delete uut;
    }
};

TEST_F(FsmTests, TestJumpUnconditionalInstruction) {
    uut->instruction = 0b0000'0000'0001'0101;
    uut->clk = 1;
    uut->eval();

    // Advance to next instruction
    uut->clk = 0;
    uut->eval();
    uut->clk = 1;
    uut->eval();

    EXPECT_EQ(uut->fsm_pc, 0b10101);
}
