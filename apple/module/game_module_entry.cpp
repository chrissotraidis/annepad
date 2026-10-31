#include "game_module.h"
#include "librecomp/overlays.hpp"
#include "recomp_overlays.inl"

extern "C" void recomp_entrypoint(uint8_t*, recomp_context*);
gpr get_entrypoint_address();
extern RspUcodeFunc aspMain;
extern RspUcodeFunc gbTowerMain;
extern RspUcodeFunc gbTowerColorMain;
extern RspUcodeFunc njpgdspMain;

// Preserve the maintained register_overlays.cpp contract. The table and every
// function it points to live in this module; the runtime registry lives in the app.
static void register_module_overlays() {
    recomp::overlays::overlay_section_table_data_t sections {
        .code_sections = section_table,
        .num_code_sections = sizeof(section_table) / sizeof(section_table[0]),
        .total_num_sections = num_sections,
    };
    recomp::overlays::overlays_by_index_t overlays {
        .table = overlay_sections_by_index,
        .len = sizeof(overlay_sections_by_index) / sizeof(overlay_sections_by_index[0]),
    };
    recomp::overlays::register_overlays(sections, overlays);
}

extern "C" __attribute__((visibility("default")))
const AnnePadGameModule* annepad_get_game_module() {
    static const AnnePadGameModule module {
        annepad_game_module_version, sizeof(AnnePadGameModule), ANNEPAD_MODULE_ID,
        get_entrypoint_address, recomp_entrypoint, register_module_overlays,
        aspMain, gbTowerMain, gbTowerColorMain, njpgdspMain
    };
    return &module;
}
