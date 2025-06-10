#ifndef TEST_UTILS_H
#define TEST_UTILS_H

#include <cstdint>
#include "Vtest_wrapper.h"
#include "gtest/gtest.h"

class VerilatorTestFixture : public ::testing::Test {
protected:
    Vtest_wrapper *uut;

    void SetUp() override {
        uut = new Vtest_wrapper;
        Reset();
    }

    void TearDown() override {
        delete uut;
    }

    void Reset() {
        uut->rst = 1;
        uut->eval();
        uut->rst = 0;
        uut->eval();
    }

    void AdvanceOneCycle() {
        uut->clk = 0;
        uut->eval();
        uut->clk = 1;
        uut->eval();
    }
};

#endif // TEST_UTILS_H
