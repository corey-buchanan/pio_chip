#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

class UnitTests : public ::testing::Test {
protected:
    Vtest_wrapper* top;

    // Initialize your module
    void SetUp() override {
        top = new Vtest_wrapper;
    }

    // Clean up after each test
    void TearDown() override {
        delete top;
    }
};

TEST_F(UnitTests, TestCounterCountsAndWraps) {
    for (int i = 0; i < 10; i++) {
        top->clk = 0;
        top->eval();
        EXPECT_EQ(top->counter, i % 4);

        top->clk = 1;
        top->eval();
        EXPECT_EQ(top->counter, (i+1) % 4);
    }
}
