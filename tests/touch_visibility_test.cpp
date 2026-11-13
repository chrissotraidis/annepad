#include "touch_visibility.h"

#include <cassert>

namespace {

AnnePadTouchVisibility firstLaunch(bool controllerReady) {
    AnnePadTouchVisibility visibility;
    visibility.autoHide = AnnePadSavedAutoHide(false, false);
    visibility.controllerReady = controllerReady;
    return visibility;
}

void controller_present_before_launch_hides_by_default() {
    assert(!firstLaunch(true).gameplayVisible());
    assert(firstLaunch(false).gameplayVisible());
}

void saved_opt_out_survives_relaunch() {
    AnnePadTouchVisibility visibility;
    visibility.autoHide = AnnePadSavedAutoHide(true, false);
    visibility.controllerReady = true;
    assert(visibility.gameplayVisible());
    assert(AnnePadSavedAutoHide(true, true));
}

void connect_and_disconnect_follow_player_one() {
    AnnePadTouchVisibility visibility = firstLaunch(false);
    visibility.controllerReady = true;
    assert(!visibility.gameplayVisible());
    // The runtime reports Player 1 ownership, so removing a second controller
    // keeps this true and removing Player 1's controller makes it false.
    visibility.controllerReady = false;
    assert(visibility.gameplayVisible());
}

void preference_change_applies_while_connected() {
    AnnePadTouchVisibility visibility = firstLaunch(true);
    visibility.autoHide = false;
    assert(visibility.gameplayVisible());
    visibility.autoHide = true;
    assert(!visibility.gameplayVisible());
}

void show_restores_controls_with_controller_connected() {
    AnnePadTouchVisibility visibility = firstLaunch(true);
    visibility.enabled = false;
    visibility.show();
    assert(visibility.gameplayVisible());
    assert(visibility.enabled && !visibility.autoHide);
}

void manual_hide_holds_without_controller() {
    AnnePadTouchVisibility visibility = firstLaunch(false);
    visibility.enabled = false;
    assert(!visibility.gameplayVisible());
    visibility.show();
    assert(visibility.gameplayVisible());
}

} // namespace

int main() {
    controller_present_before_launch_hides_by_default();
    saved_opt_out_survives_relaunch();
    connect_and_disconnect_follow_player_one();
    preference_change_applies_while_connected();
    show_restores_controls_with_controller_connected();
    manual_hide_holds_without_controller();
    return 0;
}
