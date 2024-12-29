#include "gtest/gtest.h"
#include "Vtest_wrapper.h"

class OutputArbitrator : public ::testing::Test {
protected:
    Vtest_wrapper *uut;

    void SetUp() override {
        uut = new Vtest_wrapper;

        for (int i = 0; i < 32; i++) {
            uut->core_select[i] = 0b00;
        }

        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                uut->fsm_output[i][j] = 0x00000000;
                uut->fsm_drive[i][j] = 0x00000000;
            }
        }
    }

    void TearDown() override {
        delete uut;
    }
};

TEST_F(OutputArbitrator, FSMDrivingGPIOGetsSelected) {
    uut->fsm_output[0][0] = 0xAAAA0000;
    uut->fsm_drive[0][0] = 0xFFFF0000;

    uut->fsm_output[0][1] = 0x00005555;
    uut->fsm_drive[0][1] = 0x0000FFFF;

    uut->eval();

    EXPECT_EQ(uut->gpio_output, 0xAAAA5555);
    EXPECT_EQ(uut->gpio_drive, 0xFFFFFFFF);
}

TEST_F(OutputArbitrator, LowestIndexedFSMGetsPriorityDuringConflict) {
    uut->fsm_output[0][2] = 0xDEADBEEF;
    uut->fsm_drive[0][2] = 0xFFFF0FF0;

    uut->fsm_output[0][3] = 0xBAADF00D;
    uut->fsm_drive[0][3] = 0xFFFFFFF0;

    // Core isn't selected, so shouldn't impact output
    uut->fsm_output[1][0] = 0xAAAAAAAA;
    uut->fsm_drive[1][0] = 0xFFFFFFFF;

    uut->eval();

    EXPECT_EQ(uut->gpio_drive, 0xFFFFFFF0);
    EXPECT_EQ(uut->gpio_output, 0xDEADFEE0);
}

TEST_F(OutputArbitrator, CoreSelectMuxWorksProperly) {
    uut->fsm_output[0][0] = 0x00000000;
    uut->fsm_output[0][0] = 0xFFFFFFFF;

    uut->fsm_output[1][2] = 0xAAAAAAAA;
    uut->fsm_drive[1][2] = 0x99999999;

    for (int i = 0; i < 32; i++) {
        uut->core_select[i] = 1;
    }

    uut->eval();

    EXPECT_EQ(uut->gpio_output, 0x88888888);
    EXPECT_EQ(uut->gpio_drive, 0x99999999);
}

TEST_F(OutputArbitrator, CoreSelectMuxMultipleSources) {
    uut->fsm_output[0][0] = 0x00000000;
    uut->fsm_drive[0][0] = 0xFFFFFFFF;

    uut->fsm_output[1][2] = 0xD15EA5E0;
    uut->fsm_drive[1][2] = 0x11111111;

    uut->fsm_output[2][3] = 0xC001D00D;
    uut->fsm_drive[2][3] = 0xFFFFFFFF;

    uut->fsm_output[3][2] = 0x0D15EA5E;
    uut->fsm_drive[3][2] = 0x88888888;

    for (int i = 31; i >= 0; i--) {
        uut->core_select[i] = i % 4;
    }

    uut->eval();

    EXPECT_EQ(uut->gpio_output, 0x4800C80C);
    EXPECT_EQ(uut->gpio_drive, 0xDDDDDDDD);
}
