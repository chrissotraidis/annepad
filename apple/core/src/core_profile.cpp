#include "annepad/core_profile.h"

#if !defined(N64MODERN_NO_DYNAMIC_CODE)
#error "The Apple mobile core must compile with N64MODERN_NO_DYNAMIC_CODE"
#endif

AnnePadCoreProfile annepad_core_profile(void) {
    return AnnePadCoreProfile{
        .static_recompilation = 1,
        .runtime_generated_code = 0,
        .dynamic_plugins = 0,
    };
}
