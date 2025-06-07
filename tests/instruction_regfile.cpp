#include "test_utils.h"

class InstructionRegfileTests : public VerilatorTestFixture {
protected:
    void SetUp() override {
        VerilatorTestFixture::SetUp();

        uut->instr_in = 0b0000'0000'0000'0000;
        uut->write_addr = 0b00000;
        uut->write_en = 0;
        uut->read_addr = 0b00000;
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