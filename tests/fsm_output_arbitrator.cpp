#include "test_utils.h"

class FsmOutputArbitrator : public VerilatorTestFixture {
protected:
    void SetUp() override {
        VerilatorTestFixture::SetUp();

        for (int i = 0; i < 32; i++) {
            uut->core_select[i] = 0b00;
        }

        for (int i = 0; i < 4; i++) {
            uut->fsm_output[i] = 0x00000000;
            uut->fsm_drive[i] = 0x00000000;
        }
    }
};

TEST_F(FsmOutputArbitrator, FSMDrivingGPIOGetsSelected) {
    uut->fsm_output[0] = 0xAAAA0000;
    uut->fsm_drive[0] = 0xFFFF0000;

    uut->fsm_output[1] = 0x00005555;
    uut->fsm_drive[1] = 0x0000FFFF;

    uut->eval();

    EXPECT_EQ(uut->fsm_core_output, 0xAAAA5555);
    EXPECT_EQ(uut->fsm_core_drive, 0xFFFFFFFF);
}

TEST_F(FsmOutputArbitrator, LowestIndexedFSMGetsPriorityDuringConflict) {
    uut->fsm_output[2] = 0xDEADBEEF;
    uut->fsm_drive[2] = 0xFFFF0FF0;

    uut->fsm_output[3] = 0xBAADF00D;
    uut->fsm_drive[3] = 0xFFFFFFF0;

    uut->eval();

    EXPECT_EQ(uut->fsm_core_drive, 0xFFFFFFF0);
    EXPECT_EQ(uut->fsm_core_output, 0xDEADFEE0);
}
