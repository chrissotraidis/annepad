#include "controller_slots.h"

#include <array>
#include <cassert>
#include <cstdint>
#include <vector>

namespace {

using pkmnstadium::controller::Eligibility;
using pkmnstadium::controller::Instances;
using pkmnstadium::controller::kNoController;
using pkmnstadium::controller::reconcile_slots;

struct InputSample {
    uint16_t buttons = 0;
    int16_t stick_x = 0;
    int16_t stick_y = 0;
    int16_t left_trigger = 0;
    int16_t right_trigger = 0;
};

struct FakeBackend {
    Instances slots{kNoController, kNoController, kNoController, kNoController};
    Eligibility eligible{true, true, true, true};
    std::vector<int> attached;
    std::array<InputSample, 4> input{};
    const char* last_reason = nullptr;

    void reconcile(const char* reason) {
        last_reason = reason;
        const auto plan = reconcile_slots(slots, eligible, attached.data(), attached.size());
        for (std::size_t slot = 0; slot < slots.size(); ++slot) {
            if (plan.released[slot]) input[slot] = {};
        }
        slots = plan.instances;
    }

    InputSample read(std::size_t slot) const {
        for (int instance : attached) {
            if (slots[slot] == instance) return input[slot];
        }
        return {};
    }
};

void missed_removal_releases_held_input() {
    FakeBackend backend;
    backend.slots[0] = 10;
    backend.attached = {};
    backend.input[0] = {0x8000, 21000, -18000, 32767, 16000};

    backend.reconcile("active-check");

    assert(backend.slots[0] == kNoController);
    const InputSample neutral = backend.read(0);
    assert(neutral.buttons == 0);
    assert(neutral.stick_x == 0 && neutral.stick_y == 0);
    assert(neutral.left_trigger == 0 && neutral.right_trigger == 0);
}

void returning_and_additional_controllers_use_free_slots() {
    FakeBackend backend;
    backend.attached = {11};
    backend.reconcile("device-added");
    assert(backend.slots[0] == 11);

    backend.attached = {11, 22};
    backend.reconcile("device-added");
    assert(backend.slots[0] == 11);
    assert(backend.slots[1] == 22);
}

void changing_one_controller_preserves_the_other() {
    FakeBackend backend;
    backend.slots = {11, 22, kNoController, kNoController};
    backend.attached = {11, 33};

    backend.reconcile("device-removed");

    assert(backend.slots[0] == 11);
    assert(backend.slots[1] == 33);
}

void foreground_reconciliation_preserves_valid_ownership() {
    FakeBackend backend;
    backend.slots = {11, 22, kNoController, kNoController};
    backend.attached = {22, 11};

    backend.reconcile("foreground");

    assert(backend.last_reason != nullptr);
    assert(backend.slots[0] == 11);
    assert(backend.slots[1] == 22);
}

void ineligible_slots_do_not_steal_configured_ownership() {
    FakeBackend backend;
    backend.eligible = {false, true, true, false};
    backend.attached = {41, 42};

    backend.reconcile("launcher-config");

    assert(backend.slots[0] == kNoController);
    assert(backend.slots[1] == 41);
    assert(backend.slots[2] == 42);
    assert(backend.slots[3] == kNoController);
}

} // namespace

int main() {
    missed_removal_releases_held_input();
    returning_and_additional_controllers_use_free_slots();
    changing_one_controller_preserves_the_other();
    foreground_reconciliation_preserves_valid_ownership();
    ineligible_slots_do_not_steal_configured_ownership();
    return 0;
}
