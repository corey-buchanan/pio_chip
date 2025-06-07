#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

class Fifo : public ::testing::Test {
protected:
    Vtest_wrapper *uut;

    void SetUp() override {
        uut = new Vtest_wrapper;
        
        uut->fifo_in = 0x00000000;
        uut->push_en = 0;
        uut->pop_en = 0;

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

TEST_F(Fifo, FifoDoesntFillWhenPushIsDisabled) {
    // Check initial status
    EXPECT_EQ(uut->empty, 1);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 0);

    uut->fifo_in = 0x12345678;
    for (int i = 0; i < 32; i++) {
        AdvanceOneCycle();
    }

    // Check status
    EXPECT_EQ(uut->empty, 1);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 0);

    // Check state
    for (int i = 0; i < 4; i++) {
        EXPECT_EQ(uut->fifo_memory[i], 0x00000000);
    }
    EXPECT_EQ(uut->fifo_head, 0);
    EXPECT_EQ(uut->fifo_tail, 0);
}

TEST_F(Fifo, InsertIntoEmptyFifo) {
    // Check initial status
    EXPECT_EQ(uut->empty, 1);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 0);

    // Insert value
    uut->push_en = 1;
    uut->fifo_in = 0x12345678;
    AdvanceOneCycle();

    // Check state
    EXPECT_EQ(uut->fifo_memory[0], 0x12345678);
    EXPECT_EQ(uut->fifo_head, 1);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 1);
}

TEST_F(Fifo, InsertMultipleIntoFifo) {
    // Insert multiple values
    uut->push_en = 1;
    uut->fifo_in = 0x9999AAAA;
    AdvanceOneCycle();
    uut->fifo_in = 0x5555FFFF;
    AdvanceOneCycle();
    uut->fifo_in = 0x83A2A3B5;
    AdvanceOneCycle();

    // Check state
    EXPECT_EQ(uut->fifo_memory[0], 0x9999AAAA);
    EXPECT_EQ(uut->fifo_memory[1], 0x5555FFFF);
    EXPECT_EQ(uut->fifo_memory[2], 0x83A2A3B5);
    EXPECT_EQ(uut->fifo_head, 3);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 3);

    // Insert one last value
    AdvanceOneCycle();

    // Check state
    EXPECT_EQ(uut->fifo_memory[3], 0x83A2A3B5);
    EXPECT_EQ(uut->fifo_head, 0);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 1);
    EXPECT_EQ(uut->fifo_count, 4);
}

TEST_F(Fifo, InsertIntoFullFifo) {
    // Fill the FIFO
    uut->push_en = 1;
    uut->fifo_in = 0xFFFFFFFF;
    for (int i = 0; i < 4; i++) {
        AdvanceOneCycle();
    }

    // Check State
    for (int i = 0; i < 4; i++) {
        EXPECT_EQ(uut->fifo_memory[i], 0xFFFFFFFF);
    }
    EXPECT_EQ(uut->fifo_head, 0);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 1);
    EXPECT_EQ(uut->fifo_count, 4);

    // Check to see that push is ignored
    uut->fifo_in = 0x11111111;
    AdvanceOneCycle();
    for (int i = 0; i < 4; i++) {
        EXPECT_EQ(uut->fifo_memory[i], 0xFFFFFFFF);
    }
    EXPECT_EQ(uut->fifo_head, 0);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 1);
    EXPECT_EQ(uut->fifo_count, 4);
}
    
TEST_F(Fifo, FifoDoesntReadWhenPopIsDisabled) {
    // Fill the FIFO
    uut->push_en = 1;
    uut->fifo_in = 0x88888888;
    for (int i = 0; i < 4; i++) {
        AdvanceOneCycle();
    }

    // Check State
    for (int i = 0; i < 4; i++) {
        EXPECT_EQ(uut->fifo_memory[i], 0x88888888);
    }
    EXPECT_EQ(uut->fifo_head, 0);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 1);
    EXPECT_EQ(uut->fifo_count, 4);

    uut->push_en = 0;

    // Check to see that data is not read out
    for (int i = 0; i < 4; i++) {
        AdvanceOneCycle();
        EXPECT_EQ(uut->fifo_out, 0x00000000);
    }

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 1);
    EXPECT_EQ(uut->fifo_count, 4);
}

TEST_F(Fifo, PopOneValueFromFifo) {
    // Load one value into the FIFO
    uut->push_en = 1;
    uut->fifo_in = 0xACDCACDC;
    AdvanceOneCycle();
    uut->push_en = 0;

    // Check state
    EXPECT_EQ(uut->fifo_memory[0], 0xACDCACDC);
    EXPECT_EQ(uut->fifo_head, 1);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 1);

    // Pull one value out
    uut->pop_en = 1;
    AdvanceOneCycle();
    EXPECT_EQ(uut->fifo_out, 0xACDCACDC);

    // Check state
    EXPECT_EQ(uut->fifo_memory[0], 0xACDCACDC);
    EXPECT_EQ(uut->fifo_head, 1);
    EXPECT_EQ(uut->fifo_tail, 1);

    // Check status
    EXPECT_EQ(uut->empty, 1);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 0);
}

TEST_F(Fifo, PopFromEmptyFifoRetainsPreviousData) {
    // Load one value into the FIFO
    uut->push_en = 1;
    uut->fifo_in = 0x12345678;
    AdvanceOneCycle();
    uut->push_en = 0;

    // Check state
    EXPECT_EQ(uut->fifo_memory[0], 0x12345678);
    EXPECT_EQ(uut->fifo_head, 1);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->fifo_count, 1);

    // Pull one value out
    uut->pop_en = 1;
    AdvanceOneCycle();
    EXPECT_EQ(uut->fifo_out, 0x12345678);

    // Check state
    EXPECT_EQ(uut->fifo_memory[0], 0x12345678);
    EXPECT_EQ(uut->fifo_head, 1);
    EXPECT_EQ(uut->fifo_tail, 1);

    // Check that FIFO is empty again
    EXPECT_EQ(uut->empty, 1);
    EXPECT_EQ(uut->fifo_count, 0);

    // Check to see that data is not read out and tail is not changed
    uut->pop_en = 1;
    for (int i = 0; i < 32; i++) {
        AdvanceOneCycle();
        EXPECT_EQ(uut->fifo_out, 0x12345678);

        // Check tail
        EXPECT_EQ(uut->fifo_tail, 1);
    }

    // Check state
    EXPECT_EQ(uut->fifo_memory[0], 0x12345678);
    EXPECT_EQ(uut->fifo_memory[1], 0x00000000);
    EXPECT_EQ(uut->fifo_memory[2], 0x00000000);
    EXPECT_EQ(uut->fifo_memory[3], 0x00000000);
    EXPECT_EQ(uut->fifo_head, 1);
    EXPECT_EQ(uut->fifo_tail, 1);

    // Check status
    EXPECT_EQ(uut->empty, 1);
    EXPECT_EQ(uut->fifo_count, 0);
}

TEST_F(Fifo, PopFromFullFifo) {
    // Fill the FIFO
    uut->push_en = 1;
    for (int i = 0; i < 4; i++) {
        uut->fifo_in = 0xDEADBEE0 + i;
        AdvanceOneCycle();
        EXPECT_EQ(uut->fifo_count, i + 1);
        EXPECT_EQ(uut->fifo_head, (i + 1) % 4);
    }

    uut->push_en = 0;

    // Check state
    for (int i = 0; i < 4; i++) {
        EXPECT_EQ(uut->fifo_memory[i], 0xDEADBEE0 + i);
    }

    EXPECT_EQ(uut->fifo_head, 0);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 1);
    EXPECT_EQ(uut->fifo_count, 4);

    // Pop values out
    uut->pop_en = 1;
    for (int i = 0; i < 4; i++) {
        AdvanceOneCycle();
        EXPECT_EQ(uut->fifo_out, 0xDEADBEE0 + i);
        EXPECT_EQ(uut->fifo_count, 4 - i - 1);
        EXPECT_EQ(uut->fifo_tail, (i + 1) % 4);
        EXPECT_EQ(uut->fifo_head, 0);
    }

    // Check state
    for (int i = 0; i < 4; i++) {
        // We aren't overriding anything yet, simply advancing pointers
        EXPECT_EQ(uut->fifo_memory[i], 0xDEADBEE0 + i);  
    }

    // Check status
    EXPECT_EQ(uut->empty, 1);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 0);
}

TEST_F(Fifo, PushAndPopAtSameTime) {
    // Insert one value into the FIFO
    uut->push_en = 1;
    uut->pop_en = 1;
    uut->fifo_in = 0x00000001;
    AdvanceOneCycle();
    
    // Check that value is inserted, not popped out yet
    EXPECT_EQ(uut->fifo_head, 1);
    EXPECT_EQ(uut->fifo_tail, 0);

    // Check status
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 1);

    EXPECT_EQ(uut->fifo_out, 0x00000000);

    // Load a new value
    uut->fifo_in = 0x00000002;
    AdvanceOneCycle();
    
    // Previous value should be popped
    EXPECT_EQ(uut->fifo_head, 2);
    EXPECT_EQ(uut->fifo_tail, 1);

    EXPECT_EQ(uut->fifo_out, 0x00000001);
    EXPECT_EQ(uut->fifo_count, 1);

    for (int i = 2; i < 32; i++) {
        uut->fifo_in = i + 1;
        AdvanceOneCycle();
        EXPECT_EQ(uut->fifo_out, i);
        EXPECT_EQ(uut->fifo_count, 1);
        EXPECT_EQ(uut->fifo_head, (i + 1) % 4);
        EXPECT_EQ(uut->fifo_tail, i % 4);
    }
}

TEST_F(Fifo, PopKeepsFifoFromBeingFull) {
    // Pre-fill the FIFO
    uut->push_en = 1;
    for (int i = 0; i < 3; i++) {
        uut->fifo_in = i + 1;
        AdvanceOneCycle();
    }

    uut->pop_en = 1;

    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 3);

    // Insert one more value with pop enabled
    uut->fifo_in = 4;
    AdvanceOneCycle();

    EXPECT_EQ(uut->fifo_out, 1);
    EXPECT_EQ(uut->empty, 0);
    EXPECT_EQ(uut->full, 0);
    EXPECT_EQ(uut->fifo_count, 3);
}
