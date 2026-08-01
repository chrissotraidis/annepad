#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AnnePadCoreProfile {
    int static_recompilation;
    int runtime_generated_code;
    int dynamic_plugins;
} AnnePadCoreProfile;

AnnePadCoreProfile annepad_core_profile(void);

#ifdef __cplusplus
}
#endif
