#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

class InstructionRegfileTests : public ::testing::Test {
protected:
    Vtest_wrapper* uut;

    void SetUp() override {
        uut = new Vtest_wrapper;

        uut->clk = 0;
        uut->instr_in = 0b0000'0000'0000'0000;
        uut->write_addr = 0b00000;
        uut->write_en = 0;
        uut->read_addr = 0b00000;

        Reset(); // Zero the regfile
    }

    void Reset() {
        uut->rst = 1;
        uut->eval();
        uut->rst = 0;
        uut->eval();
    }

    void TearDown() override {
        delete uut;
    }
};

TEST_F(InstructionRegfileTests, TestReadWriteToRegfile) {
    uut->write_en = 1;
    uut->instr_in = 0b0101'0101'0101'0101;

    for (int i = 0b00000; i <= 0b11111; i++) {
        uut->write_addr = i;
        uut->clk = 1;
        uut->eval();

        uut->clk = 0;
        uut->eval();
    }

    uut->write_en = 0;

    for (int i = 0b00000; i <= 0b11111; i++) {
        uut->read_addr = i;
        uut->clk = 1;
        uut->eval();
        EXPECT_EQ(uut->instr_out, 0b0101'0101'0101'0101);

        uut->clk = 0;
        uut->eval();
    }
}

TEST_F(InstructionRegfileTests, TestReset) {
    uut->write_en = 1;
    uut->instr_in = 0b1111'1111'1111'1111;

    for (int i = 0b00000; i <= 0b11111; i++) {
        uut->write_addr = i;
        uut->clk = 1;
        uut->eval();

        uut->clk = 0;
        uut->eval();
    }

    uut->write_en = 0;
    uut->rst = 1;
    uut->eval();

    for (int i = 0b00000; i <= 0b11111; i++) {
        uut->read_addr = i;
        uut->clk = 1;
        uut->eval();
        EXPECT_EQ(uut->instr_out, 0b0000'0000'0000'0000);

        uut->clk = 0;
        uut->eval();
    }
}

TEST_F(InstructionRegfileTests, TestWriteEnableFalse) {
    uut->instr_in = 0b1001'1001'1001'1001;

    for (int i = 0b00000; i <= 0b11111; i++) {
        uut->write_addr = i;
        uut->clk = 1;
        uut->eval();

        uut->clk = 0;
        uut->eval();
    }

    for (int i = 0b00000; i <= 0b11111; i++) {
        uut->read_addr = i;
        uut->clk = 1;
        uut->eval();
        EXPECT_EQ(uut->instr_out, 0b0000'0000'0000'0000);

        uut->clk = 0;
        uut->eval();
    }
}