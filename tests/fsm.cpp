#include "test_utils.h"

class FsmTests : public VerilatorTestFixture {
protected:
    void SetUp() override {
        VerilatorTestFixture::SetUp();

        uut->instruction = 0b0000'0000'0000'0000;
        uut->out_shiftdir = 1; // Right shift
        uut->autopull = 0;
        uut->pull_thresh = 0; // Encoding for 32 bits
        uut->eval();
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
    // JMP 001 : Jump to 0b01010 if X is zero
    uut->instruction = 0b0000'0000'0010'1010;
    AdvanceOneCycle();

    // Set X = 0b10101
    uut->instruction = 0b1110'0000'0011'0101;
    AdvanceOneCycle();

    // Expect the first jump to be taken, as X was zero on issue
    EXPECT_EQ(uut->fsm_pc, 0b01010);

    // JMP 001 : Jump to 0b11110 if X is zero
    uut->instruction = 0b0000'0000'0011'1110;
    AdvanceOneCycle();

    // Expect the second jump to not be taken (PC advances 2), as X was non-zero on issue
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01100);
}

TEST_F(FsmTests, TestJumpYZero) {
    // JMP 011 : Jump to 0b01010 if Y is zero
    uut->instruction = 0b0000'0000'0110'1010;
    AdvanceOneCycle();

    // Set Y = 0b10101
    uut->instruction = 0b1110'0000'0101'0101;
    AdvanceOneCycle();

    // Expect the first jump to be taken, as Y was zero on issue
    EXPECT_EQ(uut->fsm_pc, 0b01010);

    // JMP 001 : Jump to 0b11110 if Y is zero
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

    // JMP X-- : Jump to 0b01010 if X was non-zero before decrementing.
    uut->instruction = 0b0000'0000'0100'1010;
    AdvanceOneCycle();
    EXPECT_EQ(uut->x, 0); // X should decrement to 0

    // Issue another JMP X-- to 0b11111 when X is already zero.
    uut->instruction = 0b0000'0000'0101'1111;
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01010); // Verify that the first jump was taken
    // Verify that X wraps around after decrementing from 0.
    EXPECT_EQ(uut->x, 0xFFFFFFFF);

    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01011); // Verify that second jump was not taken (PC increments)
}

TEST_F(FsmTests, TestJumpYNonZeroDecrement) {
    // Set Y = 1
    uut->instruction = 0b1110'0000'0100'0001;
    AdvanceOneCycle();

    // JMP Y-- : Jump to 0b01010 if Y was non-zero before decrementing.
    uut->instruction = 0b0000'0000'1000'1010;
    AdvanceOneCycle();
    EXPECT_EQ(uut->y, 0); // Y should decrement to 0

    // Issue another JMP Y-- to 0b11111 when Y is already zero.
    uut->instruction = 0b0000'0000'1001'1111;
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01010); // Verify that the first jump was taken
    // Verify that Y wraps around after decrementing from 0.
    EXPECT_EQ(uut->y, 0xFFFFFFFF);

    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01011); // Verify that second jump was not taken (PC increments)
}

TEST_F(FsmTests, TestJumpXNotEqualY) {
    // Set X = 0b01110
    uut->instruction = 0b1110'0000'0010'1110;
    AdvanceOneCycle();
    // Set Y = 0b01110 (equal to x)
    uut->instruction = 0b1110'0000'0100'1110;
    AdvanceOneCycle();

    // JMP X!=Y to 0b00000
    uut->instruction = 0b0000'0000'1010'0000;
    AdvanceOneCycle();

    // Set Y = 0b00100 (not equal to x)
    uut->instruction = 0b1110'0000'0100'0100;
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b00011); // Verify jump was not taken

    // Re-issue jmp instruction
    uut->instruction = 0b0000'0000'1010'0000;
    AdvanceOneCycle();

    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b00000); // Verify jump was taken
}

// TODO - Implement this test
TEST_F(FsmTests, TestJumpOSRNotEmpty) {

}

TEST_F(FsmTests, TestOut32Bits) {

}

TEST_F(FsmTests, TestOut8Bits) {

}

TEST_F(FsmTests, TestOutAutopullOneCycle) {

}

TEST_F(FsmTests, TestOutAutopullMultiCycle) {
    // Autopull should pull on the same cycle as the out instruction
    // but only if the fifo is not empty.
    // We are testing autpull where the fifo is empty on the first cycle,
    // but filled on a later cycle.
}

TEST_F(FsmTests, TestOutAutopullStallOnEmpty) {

}

TEST_F(FsmTests, TestPullNormal) {

}

TEST_F(FsmTests, TestPullBlockStall) {

}

TEST_F(FsmTests, TestPullBlockXToOSR) {

}

TEST_F(FsmTests, TestPullUnderThresholdDoNothing) {

}

TEST_F(FsmTests, TestMovXY) {
    
}

TEST_F(FsmTests, TestMovXNull) {
    
}

TEST_F(FsmTests, TestMovXOSR) {

}

TEST_F(FsmTests, TestMovYX) {

}

TEST_F(FsmTests, TestMovYNull) {
    // Preload y with an immediate value
    // Issue SET Y 31
    uut->instruction = pio_encode_set(pio_y, 31);
    AdvanceOneCycle();

    // Expect Y to be 31
    EXPECT_EQ(uut->y, 31);

    // Issue MOV Y, NULL
    uut->instruction = pio_encode_mov(pio_y, pio_null);
    AdvanceOneCycle();

    // Expect Y to be 0
    EXPECT_EQ(uut->y, 0);
}

TEST_F(FsmTests, TestMovYOSR) {

}

TEST_F(FsmTests, TestMovOSRX) {

}

TEST_F(FsmTests, TestMovOSRY) {

}

TEST_F(FsmTests, TestMovOSRNull) {

}

TEST_F(FsmTests, TestSetImmediateXY) {
    uut->instruction = 0b1110'0000'0011'0101;
    AdvanceOneCycle();

    EXPECT_EQ(uut->x, 0b10101);

    uut->instruction = 0b1110'0000'0100'1110;
    AdvanceOneCycle();
    
    EXPECT_EQ(uut->y, 0b01110);

    // Test persistence
    uut->instruction = 0x0000;
    AdvanceOneCycle();
    EXPECT_EQ(uut->x, 0b10101);
    EXPECT_EQ(uut->y, 0b01110);
}
