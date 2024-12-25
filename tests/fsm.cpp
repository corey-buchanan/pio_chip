#include "gtest/gtest.h"
#include "Vtest_wrapper.h"
#include "verilated_vcd_c.h"

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

    void AdvanceOneCycle() {
        uut->clk = 0;
        uut->eval();
        uut->clk = 1;
        uut->eval();
    }
};

TEST_F(FsmTests, TestJumpUnconditionalInstruction) {
    uut->instruction = 0b0000'0000'0001'0101;
    uut->clk = 1;
    uut->eval();

    AdvanceOneCycle();

    EXPECT_EQ(uut->fsm_pc, 0b10101);
}

TEST_F(FsmTests, TestJumpScratchXZero) {
    // JMP 001 - !X - Scratch X zero
    uut->instruction = 0b0000'0000'0010'1010;
    uut->clk = 1;
    uut->eval();

    AdvanceOneCycle();

    // Expect the branch to be taken, as there is nothing in the X register
    EXPECT_EQ(uut->fsm_pc, 0b01010);

    // Store something other than zero in X
    uut->instruction = 0b1110'0000'0011'0101;
    uut->clk = 1;
    uut->eval();

    // JMP 001 - !X - Scratch X zero
    uut->instruction = 0b0000'0000'0011'1110;
    AdvanceOneCycle();

    // Expect the branch to not be taken, as there is stuff in X
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01011);
}

// 010 - X-- - Scratch X non-zero before decrement
// uut->instruction = 0b0000'0000'0100'1010;

// 011 - !Y - Scratch Y zero
// uut->instruction = 0b0000'0000'0110'1010;

// 100 - Y-- - Scratch Y non-zero before decrement
// uut->instruction = 0b0000'0000'1000'1010;

TEST_F(FsmTests, TestSetImmediateXY) {
    uut->instruction = 0b1110'0000'0011'0101;
    uut->clk = 1;
    uut->eval();

    EXPECT_EQ(uut->x, 0b10101);
    uut->clk = 0;
    uut->eval();

    uut->instruction = 0b1110'0000'0100'1110;
    uut->clk = 1;
    uut->eval();
    
    EXPECT_EQ(uut->y, 0b01110);

    // Test persistence
    uut->instruction = 0b0000'0000'0000'0000;
    AdvanceOneCycle();
    EXPECT_EQ(uut->x, 0b10101);
    EXPECT_EQ(uut->y, 0b01110);
}
