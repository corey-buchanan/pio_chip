#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

class Fifo : public ::testing::Test {
protected:
    Vtest_wrapper *uut;

    void SetUp() override {
        uut = new Vtest_wrapper;
    }

    void TearDown() override {
        delete uut;
    }
};

// TODO - Implement the following tests
// - Insert into an empty FIFO
// - Insert into a non-empty FIFO
// - Insert into a full FIFO
// - Pull from an empty FIFO
// - Pull from a non-empty FIFO
// - Pull from a full FIFO
// - Insert and pull from a FIFO at the same time
// - Multiple inserts and pulls
// - Wrapping around the FIFO
