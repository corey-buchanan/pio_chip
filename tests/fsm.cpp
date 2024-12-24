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

        uut-> eval();
    }

    void TearDown() override {
        delete uut;
    }
};

TEST_F(FsmTests, TestJumpUnconditionalInstruction) {

}