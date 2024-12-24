#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

class ProgramCounterTests : public ::testing::Test {
protected:
    Vtest_wrapper* uut;

    void SetUp() override {
        uut = new Vtest_wrapper;

        uut->clk = 0;
        uut->rst = 0;
        uut->wrap_top = 0b00000;
        uut->wrap_bottom = 0b11111;
        uut->jump = 0;
        uut->pc_en = 0;

        uut->eval();
    }

    void TearDown() override {
        delete uut;
    }
};

TEST_F(ProgramCounterTests, ProgramCounterOnlyIncrementsWithPCEnable) {
    // Enable off
    for (int i = 0b00000; i <= 0b11111; i++) {
        uut->clk = 1;
        uut->eval();
        EXPECT_EQ(uut->pc, 0b00000);

        uut->clk = 0;
        uut->eval();
    }

    // Enable on
    uut->pc_en = 1;
    for (int i = 0b00000; i <= 0b11111; i++) {
        EXPECT_EQ(uut->pc, i);
        
        uut->clk = 1;
        uut->eval();

        uut->clk = 0;
        uut->eval();
    }
}

TEST_F(ProgramCounterTests, ProgramCounterWraps) {
    uut->pc_en = 1;
    uut->wrap_top = 0b00010;
    uut->wrap_bottom = 0b00111;
    uut->pc = 0b00110;

    uut->clk = 1;
    uut->eval();
    EXPECT_EQ(uut->pc, 0b00111);

    uut->clk = 0;
    uut->eval();
    uut->clk = 1;
    uut->eval();
    EXPECT_EQ(uut->pc, 0b00010);

    // Testing the odd scenario where wrap_top > wrap_bottom - we still want the jump to occur
    uut->wrap_top = 0b01000;
    uut->wrap_bottom = 0b00010;
    uut->clk = 0;
    uut->eval();

    uut->clk = 1;
    uut->eval();
    EXPECT_EQ(uut->pc, 0b01000);
}

TEST_F(ProgramCounterTests, ProgramCounterWrapsToZero) {
    uut->pc_en = 1;
    // A plausible scenario in which we'd get modulo wrap-around is when wrap_top > wrap_bottom
    uut->wrap_top = 0b01100;
    uut->wrap_bottom = 0b01011;
    uut->pc = 0b11111;

    uut->clk = 1;
    uut->eval();
    EXPECT_EQ(uut->pc, 0b00000);
}

TEST_F(ProgramCounterTests, ResetSendsProgramCounterToWrapTop) {
    uut->pc_en = 1;

    // Send in reverse ordering so it doesn't get mistaken for normal pc flow
    for (int i = 0b11111; i >= 0b00000; i--) {
        uut->wrap_top = i;
        uut->rst = 1;
        uut->clk = 1; // Ensure reset is taking precedence over clock

        uut->eval();
        EXPECT_EQ(uut->pc, i);

        uut->rst = 0;
        uut->clk = 0;
        uut->eval();
    }
}

TEST_F(ProgramCounterTests, JumpEnableSendsProgramCounterToJumpAddr) {
    uut->pc_en = 1;
    uut->jump_en = 1;

    // Send in reverse ordering so it doesn't get mistaken for normal pc flow
    for (int i = 0b11111; i >= 0b00000; i--) {
        uut->jump = i;
        uut->clk = 1;

        uut->eval();
        EXPECT_EQ(uut->pc, i);

        uut->clk = 0;
        uut->eval();
    }
}