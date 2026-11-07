#include "game_module.h"
#include <cstdio>
#include <cstring>
#include <dlfcn.h>

namespace {
const AnnePadGameModule* module = nullptr;
void* library = nullptr;
}

extern "C" const char* annepad_load_game_module(const char* path) {
    if (module) return nullptr;
    if (!path || !*path) return "This copy needs its game module. Build it with PadMint using your supported ROM.";
    void* candidate = dlopen(path, RTLD_NOW | RTLD_LOCAL);
    if (!candidate) {
        std::fprintf(stderr, "[game module] %s\n", dlerror());
        return "The game module could not load. Build this copy with PadMint and install it again.";
    }
    auto getter = reinterpret_cast<AnnePadGetModule*>(dlsym(candidate, "annepad_get_game_module"));
    const auto* value = getter ? getter() : nullptr;
    if (!value || value->version != annepad_game_module_version || value->size != sizeof(AnnePadGameModule) ||
        !value->identity || std::strcmp(value->identity, ANNEPAD_MODULE_ID) != 0 ||
        !value->entrypoint_address || !value->entrypoint || !value->register_overlays ||
        !value->audio || !value->gb_tower || !value->gb_tower_color || !value->jpeg) {
        dlclose(candidate);
        return "The game module belongs to a different app build. Build this copy with PadMint again.";
    }
    library = candidate; // Keep every private function and overlay pointer alive.
    module = value;
    return nullptr;
}

extern "C" bool annepad_game_module_ready() { return module != nullptr; }
gpr get_entrypoint_address() { return module ? module->entrypoint_address() : 0; }
extern "C" void recomp_entrypoint(uint8_t* rdram, recomp_context* ctx) { module->entrypoint(rdram, ctx); }
namespace pokestadium { void register_overlays() { module->register_overlays(); } }
RspExitReason aspMain(uint8_t* rdram, uint32_t address) { return module->audio(rdram, address); }
RspExitReason gbTowerMain(uint8_t* rdram, uint32_t address) { return module->gb_tower(rdram, address); }
RspExitReason gbTowerColorMain(uint8_t* rdram, uint32_t address) { return module->gb_tower_color(rdram, address); }
RspExitReason njpgdspMain(uint8_t* rdram, uint32_t address) { return module->jpeg(rdram, address); }
