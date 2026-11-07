#pragma once
#include <cstddef>
#include <cstdint>
#include "recomp.h"
#include "librecomp/rsp.hpp"

// The executable owns runtime, renderer, save and Transfer Pak state. Private
// CPU code and all four maintained RSP implementations stay in one module.
struct AnnePadGameModule {
    uint32_t version;
    uint32_t size;
    const char* identity;
    gpr (*entrypoint_address)();
    void (*entrypoint)(uint8_t*, recomp_context*);
    void (*register_overlays)();
    RspUcodeFunc* audio;
    RspUcodeFunc* gb_tower;
    RspUcodeFunc* gb_tower_color;
    RspUcodeFunc* jpeg;
};
constexpr uint32_t annepad_game_module_version = 1;
using AnnePadGetModule = const AnnePadGameModule*();
extern "C" const char* annepad_load_game_module(const char* path);
extern "C" bool annepad_game_module_ready();
