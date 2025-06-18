#include "test_utils.h"

class FsmTests : public VerilatorTestFixture {
protected:
    void SetUp() override {
        VerilatorTestFixture::SetUp();

        uut->instruction = pio_encode_nop();
        uut->out_shiftdir = 1; // Right shift
        uut->autopull = 0;
        uut->pull_thresh = 0; // Encoding for 32 bits
        uut->eval();
    }
};

TEST_F(FsmTests, TestJumpUnconditionalInstruction) {
    uut->instruction = pio_encode_jmp(0b10101);
    AdvanceOneCycle();

    // Note - here and all jump tests: pc updates on the next clock cycle
    AdvanceOneCycle();

    EXPECT_EQ(uut->fsm_pc, 0b10101);
}

TEST_F(FsmTests, TestJumpXZero) {
    // JMP 001 : Jump to 0b01010 if X is zero
    uut->instruction = pio_encode_jmp_not_x(0b01010);
    AdvanceOneCycle();

    // Set X = 0b10101
    uut->instruction = pio_encode_set(pio_x, 0b10101);
    AdvanceOneCycle();

    // Expect the first jump to be taken, as X was zero on issue
    EXPECT_EQ(uut->fsm_pc, 0b01010);

    // JMP 001 : Jump to 0b11110 if X is zero
    uut->instruction = pio_encode_jmp_not_x(0b11110);
    AdvanceOneCycle();

    // Expect the second jump to not be taken (PC advances 2), as X was non-zero on issue
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01100);
}

TEST_F(FsmTests, TestJumpYZero) {
    // JMP 011 : Jump to 0b01010 if Y is zero
    uut->instruction = pio_encode_jmp_not_y(0b01010);
    AdvanceOneCycle();

    // Set Y = 0b10101
    uut->instruction = pio_encode_set(pio_y, 0b10101);
    AdvanceOneCycle();

    // Expect the first jump to be taken, as Y was zero on issue
    EXPECT_EQ(uut->fsm_pc, 0b01010);

    // JMP 001 : Jump to 0b11110 if Y is zero
    uut->instruction = pio_encode_jmp_not_y(0b11110);
    AdvanceOneCycle();

    // Expect the second jump to not be taken (PC advances 2), as Y was non-zero on issue
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01100);
}

TEST_F(FsmTests, TestJumpXNonZeroDecrement) {
    // Set X = 1
    uut->instruction = pio_encode_set(pio_x, 1);
    AdvanceOneCycle();

    // JMP X-- : Jump to 0b01010 if X was non-zero before decrementing.
    uut->instruction = pio_encode_jmp_x_dec(0b01010);
    AdvanceOneCycle();
    EXPECT_EQ(uut->x, 0); // X should decrement to 0

    // Issue another JMP X-- to 0b11111 when X is already zero.
    uut->instruction = pio_encode_jmp_x_dec(0b11111);
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01010); // Verify that the first jump was taken
    // Verify that X wraps around after decrementing from 0.
    EXPECT_EQ(uut->x, 0xFFFFFFFF);

    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01011); // Verify that second jump was not taken (PC increments)
}

TEST_F(FsmTests, TestJumpYNonZeroDecrement) {
    // Set Y = 1
    uut->instruction = pio_encode_set(pio_y, 1);
    AdvanceOneCycle();

    // JMP Y-- : Jump to 0b01010 if Y was non-zero before decrementing.
    uut->instruction = pio_encode_jmp_y_dec(0b01010);
    AdvanceOneCycle();
    EXPECT_EQ(uut->y, 0); // Y should decrement to 0

    // Issue another JMP Y-- to 0b11111 when Y is already zero.
    uut->instruction = pio_encode_jmp_y_dec(0b11111);
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01010); // Verify that the first jump was taken
    // Verify that Y wraps around after decrementing from 0.
    EXPECT_EQ(uut->y, 0xFFFFFFFF);

    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b01011); // Verify that second jump was not taken (PC increments)
}

TEST_F(FsmTests, TestJumpXNotEqualY) {
    // Set X = 0b01110
    uut->instruction = pio_encode_set(pio_x, 0b01110);
    AdvanceOneCycle();
    // Set Y = 0b01110 (equal to x)
    uut->instruction = pio_encode_set(pio_y, 0b01110);
    AdvanceOneCycle();

    // JMP X!=Y to 0b00000
    uut->instruction = pio_encode_jmp_x_ne_y(0b00000);
    AdvanceOneCycle();

    // Set Y = 0b00100 (not equal to x)
    // uut->instruction = 0b1110'0000'0100'0100;
    uut->instruction = pio_encode_set(pio_y, 0b00100);
    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b00011); // Verify jump was not taken

    // Re-issue jmp instruction
    uut->instruction = pio_encode_jmp_x_ne_y(0b00000);
    AdvanceOneCycle();

    AdvanceOneCycle();
    EXPECT_EQ(uut->fsm_pc, 0b00000); // Verify jump was taken
}

TEST_F(FsmTests, TestJumpOSRNotEmpty) {
    // Expect OSR to not be empty
    EXPECT_EQ(uut->osr_empty, 0);

    // Issue jump on OSR not empty
    uut->instruction = pio_encode_jmp_not_osre(0b10000);
    AdvanceOneCycle();

    // Empty the OSR
    uut->instruction = pio_encode_out(pio_null, 32);
    AdvanceOneCycle();

    // Expect OSR to be empty now
    EXPECT_EQ(uut->osr_empty, 1);

    // Expect first jump to be taken, as OSR was not empty on issue
    EXPECT_EQ(uut->fsm_pc, 0b10000);

    // Issue another jump on OSR not empty
    uut->instruction = pio_encode_jmp_not_osre(0b00000);
    AdvanceOneCycle();

    // Advance one more cycle to allow jump operation
    AdvanceOneCycle();

    // Expect second jump to not be taken (PC advances 2)
    EXPECT_EQ(uut->fsm_pc, 0b10010);
}

// TODO - Implement the rest of the tests

TEST_F(FsmTests, TestOut32Bits) {

}

TEST_F(FsmTests, TestOut8Bits) {

}

TEST_F(FsmTests, TestOutLeftShift) {

}

TEST_F(FsmTests, TestOutX) {
    // Load the OSR with an immediate value from Y
    uut->instruction = pio_encode_set(pio_y, 16);
    AdvanceOneCycle();
    uut->instruction = pio_encode_mov(pio_osr, pio_y);
    AdvanceOneCycle();

    // Output OSR to X
    uut->instruction = pio_encode_out(pio_x, 32);
    AdvanceOneCycle();

    // Advance one more cycle to allow the out operation to complete
    // uut->instruction = pio_encode_nop();
    AdvanceOneCycle();

    // Expect X to be 16
    EXPECT_EQ(uut->x, 16);

    // Check that OSR is empty after the out operation
    EXPECT_EQ(uut->osr_empty, 1);

    // Check that the out shift counter is 32
    EXPECT_EQ(uut->out_shift_counter, 32);

    // Check that the OSR data is 0 after the out operation
    EXPECT_EQ(uut->osr_data, 0);
}

TEST_F(FsmTests, TestOutY) {

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
    // Preload OSR with an immediate value from Y
    uut->instruction = pio_encode_set(pio_y, 27);
    AdvanceOneCycle();
    uut->instruction = pio_encode_mov(pio_osr, pio_y);
    AdvanceOneCycle();

    // Set X to a different value
    uut->instruction = pio_encode_set(pio_x, 15);
    AdvanceOneCycle();

    // Move OSR to X
    uut->instruction = pio_encode_mov(pio_x, pio_osr);
    AdvanceOneCycle();

    // Expect X to be 27
    EXPECT_EQ(uut->x, 27);
}

TEST_F(FsmTests, TestMovYX) {
    // Preload x with an immediate value
    // Issue SET X 14
    uut->instruction = pio_encode_set(pio_x, 14);
    AdvanceOneCycle();

    // Expect X to be 14
    EXPECT_EQ(uut->x, 14);

    // Preload y with an immediate value
    // Issue SET Y 12
    uut->instruction = pio_encode_set(pio_y, 12);
    AdvanceOneCycle();

    // Expect Y to be 12
    EXPECT_EQ(uut->y, 12);

    // Issue MOV Y, X
    uut->instruction = pio_encode_mov(pio_y, pio_x);
    AdvanceOneCycle();

    // Expect Y to be 14 (the value of X)
    EXPECT_EQ(uut->y, 14);
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
    // Preload OSR with an immediate value from X
    uut->instruction = pio_encode_set(pio_x, 18);
    AdvanceOneCycle();
    uut->instruction = pio_encode_mov(pio_osr, pio_x);
    AdvanceOneCycle();

    // Set Y to a different value
    uut->instruction = pio_encode_set(pio_y, 3);
    AdvanceOneCycle();

    // Move OSR to Y
    uut->instruction = pio_encode_mov(pio_y, pio_osr);
    AdvanceOneCycle();

    // Expect Y to be 18
    EXPECT_EQ(uut->y, 18);
}

TEST_F(FsmTests, TestMovOSRX) {
    // Preload x with an immediate value
    // Issue SET X 5
    uut->instruction = pio_encode_set(pio_x, 5);
    AdvanceOneCycle();

    // Expect X to be 5
    EXPECT_EQ(uut->x, 5);

    // Issue MOV OSR, X
    uut->instruction = pio_encode_mov(pio_osr, pio_x);
    AdvanceOneCycle();

    // Allow one cycle for the OSR to be updated
    uut->instruction = pio_encode_nop();
    AdvanceOneCycle();

    // Expect OSR to be 5
    EXPECT_EQ(uut->osr_data, 5);
}

TEST_F(FsmTests, TestMovOSRY) {
    // Preload y with an immediate value
    // Issue SET Y 10
    uut->instruction = pio_encode_set(pio_y, 10);
    AdvanceOneCycle();

    // Expect Y to be 10
    EXPECT_EQ(uut->y, 10);

    // Issue MOV OSR, Y
    uut->instruction = pio_encode_mov(pio_osr, pio_y);
    AdvanceOneCycle();

    // Allow one cycle for the OSR to be updated
    uut->instruction = pio_encode_nop();
    AdvanceOneCycle();

    // Expect OSR to be 10
    EXPECT_EQ(uut->osr_data, 10);
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
