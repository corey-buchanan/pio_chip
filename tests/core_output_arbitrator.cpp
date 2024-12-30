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
            uut->core_output[i] = 0x00000000;
            uut->core_drive[i] = 0x00000000;
        }
    }

    void TearDown() override {
        delete uut;
    }
};

TEST_F(OutputArbitrator, CoreSelectMuxWorksProperly) {
    uut->core_output[0] = 0x00000000;
    uut->core_drive[0] = 0xFFFFFFFF;

    uut->core_output[1] = 0xAAAAAAAA;
    uut->core_drive[1] = 0x99999999;

    for (int i = 0; i < 32; i++) {
        uut->core_select[i] = 1;
    }

    uut->eval();

    EXPECT_EQ(uut->gpio_output, 0xAAAAAAAA);
    EXPECT_EQ(uut->gpio_drive, 0x99999999);
}

TEST_F(OutputArbitrator, CoreSelectMuxMultipleSources) {
    uut->core_output[0] = 0x00000000;
    uut->core_drive[0] = 0xFFFFFFFF;

    uut->core_output[1] = 0xD15EA5E0;
    uut->core_drive[1] = 0x11111111;

    uut->core_output[2] = 0xC001D00D;
    uut->core_drive[2] = 0xFFFFFFFF;

    uut->core_output[3] = 0x0D15EA5E;
    uut->core_drive[3] = 0x88888888;

    for (int i = 31; i >= 0; i--) {
        // Switch core select every 4 bits
        int select = (i / 4) % 4;
        uut->core_select[i] = select;
    }

    uut->eval();

    EXPECT_EQ(uut->gpio_output, 0x0050E0E0);
    EXPECT_EQ(uut->gpio_drive, 0x8F1F8F1F);
}
