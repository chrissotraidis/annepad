#include "touch_tap_latch.h"

#include <cstdio>
#include <cstdlib>

namespace {

void expect(uint16_t actual, uint16_t expected, const char* label) {
    if (actual == expected) return;
    std::fprintf(stderr, "%s: expected 0x%04X, found 0x%04X\n",
                 label, expected, actual);
    std::exit(EXIT_FAILURE);
}

} // namespace

int main() {
    constexpr uint16_t A = 0x8000;
    constexpr uint16_t Z = 0x2000;
    constexpr uint16_t R = 0x0010;

    AnnePadTouchTapLatch taps;
    taps.extend(A, 6);
    for (int poll = 0; poll < 6; ++poll) {
        expect(taps.consume(), A, "quick tap duration");
    }
    expect(taps.consume(), 0, "quick tap expiry");

    taps.extend(A, 6);
    for (int poll = 0; poll < 5; ++poll) expect(taps.consume(), A, "A lead-in");
    taps.extend(R, 45);
    expect(taps.consume(), static_cast<uint16_t>(A | R), "overlap boundary");
    expect(taps.consume(), R, "independent shoulder duration");
    for (int poll = 0; poll < 43; ++poll) expect(taps.consume(), R, "R grace");
    expect(taps.consume(), 0, "overlap expiry");

    taps.extend(Z, 6);
    expect(taps.consume(), Z, "Z tap");
    taps.clear(Z);
    expect(taps.consume(), 0, "Z unlatch cancellation");

    taps.extend(static_cast<uint16_t>(A | R | Z), 6);
    taps.clearAll();
    expect(taps.consume(), 0, "lifecycle cancellation");

    std::puts("Touch tap latch tests passed.");
    return EXIT_SUCCESS;
}
