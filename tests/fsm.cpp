#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

#define DEBUG_PRINT 0

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

    // Generates a rising edge
    void AdvanceOneCycle() {
        uut->clk = 0;
        uut->eval();
        uut->clk = 1;
        uut->eval();

        #if DEBUG_PRINT
        // TODO: Add binary representation of instruction
        printf("PC: %d, X: %d, Y: %d\n", uut->fsm_pc, uut->x, uut->y);
        #endif
    }
};

TEST_F(FsmTests, TestJumpUnconditionalInstruction) {
    uut->instruction = 0b0000'0000'0001'0101;
    AdvanceOneCycle();

    // Note - here and all jump tests: pc updates on the next clock cycle
    AdvanceOneCycle();

    EXPECT_EQ(uut->fsm_pc, 0b10101);
}

TEST_F(FsmTests, TestJumpXZero) {
    // JMP 001 : Jump if X is zero
    uut->instruction = 0b0000'0000'0010'1010;
    AdvanceOneCycle();

    // Set X = 0b10101
    uut->instruction = 0b1110'0000'0011'0101;
    AdvanceOneCycle();

    // Expect the first jump to be taken, as X was zero on issue
    EXPECT_EQ(uut->fsm_pc, 0b01010);

    // JMP 001 : Jump if X is zero
    uut->instruction = 0b0000'0000'0011'1110;
    AdvanceOneCycle();

    // Expect the second jump to not be taken (PC advances 2), as X was non-zero on issue
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01100);
}

TEST_F(FsmTests, TestJumpYZero) {
    // JMP 011 : Jump if Y is zero
    uut->instruction = 0b0000'0000'0110'1010;
    AdvanceOneCycle();

    // Set Y = 0b10101
    uut->instruction = 0b1110'0000'0101'0101;
    AdvanceOneCycle();

    // Expect the first jump to be taken, as Y was zero on issue
    EXPECT_EQ(uut->fsm_pc, 0b01010);

    // JMP 001 : Jump if Y is zero
    uut->instruction = 0b0000'0000'0111'1110;
    AdvanceOneCycle();

    // Expect the second jump to not be taken (PC advances 2), as Y was non-zero on issue
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01100);
}

TEST_F(FsmTests, TestJumpXNonZeroDecrement) {
    // Set X = 1
    uut->instruction = 0b1110'0000'0010'0001;
    AdvanceOneCycle();

    // JMP X-- : Jump if X was non-zero before decrementing.
    uut->instruction = 0b0000'0000'0100'1010;
    AdvanceOneCycle();
    EXPECT_EQ(uut->x, 0); // X should decrement to 0

    // Issue another JMP X-- when X is already zero.
    uut->instruction = 0b0000'0000'0101'1111;
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01010); // Verify that the first jump was taken
    // Verify that X wraps around after decrementing from 0.
    EXPECT_EQ(uut->x, 0b1111'1111'1111'1111'1111'1111'1111'1111);

    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01011); // Verify that second jump was not taken (PC increments)
}

TEST_F(FsmTests, TestJumpYNonZeroDecrement) {
    // Set Y = 1
    uut->instruction = 0b1110'0000'0100'0001;
    AdvanceOneCycle();

    // JMP Y-- : Jump if Y was non-zero before decrementing.
    uut->instruction = 0b0000'0000'1000'1010;
    AdvanceOneCycle();
    EXPECT_EQ(uut->y, 0); // Y should decrement to 0

    // Issue another JMP Y-- when Y is already zero.
    uut->instruction = 0b0000'0000'1001'1111;
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01010); // Verify that the first jump was taken
    // Verify that Y wraps around after decrementing from 0.
    EXPECT_EQ(uut->y, 0b1111'1111'1111'1111'1111'1111'1111'1111);

    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01011); // Verify that second jump was not taken (PC increments)
}

// 011 - !Y - Scratch Y zero
// uut->instruction = 0b0000'0000'0110'1010;

// 100 - Y-- - Scratch Y non-zero before decrement
// uut->instruction = 0b0000'0000'1000'1010;

TEST_F(FsmTests, TestSetImmediateXY) {
    uut->instruction = 0b1110'0000'0011'0101;
    AdvanceOneCycle();

    EXPECT_EQ(uut->x, 0b10101);

    uut->instruction = 0b1110'0000'0100'1110;
    AdvanceOneCycle();
    
    EXPECT_EQ(uut->y, 0b01110);

    // Test persistence
    uut->instruction = 0b0000'0000'0000'0000;
    AdvanceOneCycle();
    EXPECT_EQ(uut->x, 0b10101);
    EXPECT_EQ(uut->y, 0b01110);
}
