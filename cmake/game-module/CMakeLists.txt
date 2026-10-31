cmake_minimum_required(VERSION 3.28)
project(AnnePadGameModule LANGUAGES C CXX)
if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS" OR NOT CMAKE_OSX_ARCHITECTURES STREQUAL "arm64")
    message(FATAL_ERROR "Use an arm64 iOS module toolchain")
endif()
get_filename_component(ANNEPAD_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(ANNEPAD_GENERATED "" CACHE PATH "Verified private generated CPU source")
set(ANNEPAD_GAME_SOURCE "" CACHE PATH "Verified maintained PokemonStadiumRecomp source")
set(ANNEPAD_RUNTIME_SOURCE "" CACHE PATH "Verified maintained N64ModernRuntime source")
foreach(required
        "${ANNEPAD_GENERATED}/funcs.h" "${ANNEPAD_GENERATED}/lookup.cpp" "${ANNEPAD_GENERATED}/recomp_overlays.inl"
        "${ANNEPAD_GAME_SOURCE}/rsp/aspMain.cpp" "${ANNEPAD_GAME_SOURCE}/rsp/gbTowerMain.cpp"
        "${ANNEPAD_GAME_SOURCE}/rsp/gbTowerColorMain.cpp" "${ANNEPAD_GAME_SOURCE}/rsp/njpgdspMain.cpp"
        "${ANNEPAD_RUNTIME_SOURCE}/N64Recomp/include/recomp.h")
    if(NOT EXISTS "${required}")
        message(FATAL_ERROR "Missing verified module input: ${required}")
    endif()
endforeach()
include("${ANNEPAD_ROOT}/cmake/ModuleIdentity.cmake")
annepad_module_identity("${ANNEPAD_ROOT}" identity)
file(GLOB generated CONFIGURE_DEPENDS "${ANNEPAD_GENERATED}/*.c")
add_library(AnnePadGame SHARED ${generated} "${ANNEPAD_GENERATED}/lookup.cpp"
    "${ANNEPAD_GAME_SOURCE}/rsp/aspMain.cpp" "${ANNEPAD_GAME_SOURCE}/rsp/gbTowerMain.cpp"
    "${ANNEPAD_GAME_SOURCE}/rsp/gbTowerColorMain.cpp" "${ANNEPAD_GAME_SOURCE}/rsp/njpgdspMain.cpp"
    "${ANNEPAD_ROOT}/apple/module/game_module_entry.cpp")
set_target_properties(AnnePadGame PROPERTIES C_STANDARD 17 CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON
    CXX_SCAN_FOR_MODULES OFF C_VISIBILITY_PRESET hidden CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON PREFIX "" OUTPUT_NAME "AnnePadGame")
target_include_directories(AnnePadGame PRIVATE "${ANNEPAD_ROOT}/apple/module" "${ANNEPAD_GENERATED}"
    "${ANNEPAD_GAME_SOURCE}/include" "${ANNEPAD_RUNTIME_SOURCE}/N64Recomp/include"
    "${ANNEPAD_RUNTIME_SOURCE}/librecomp/include" "${ANNEPAD_RUNTIME_SOURCE}/ultramodern/include"
    "${ANNEPAD_RUNTIME_SOURCE}/thirdparty" "${ANNEPAD_RUNTIME_SOURCE}/thirdparty/sse2neon"
    "${ANNEPAD_RUNTIME_SOURCE}/thirdparty/concurrentqueue")
target_compile_definitions(AnnePadGame PRIVATE ANNEPAD_RELEASE_BUILD=1 N64MODERN_NO_DYNAMIC_CODE=1)
set_source_files_properties("${ANNEPAD_ROOT}/apple/module/game_module_entry.cpp" PROPERTIES
    COMPILE_DEFINITIONS "ANNEPAD_MODULE_ID=\"${identity}\"")
# Match the existing shipping CPU core. Do not import tuning flags from other games.
target_compile_options(AnnePadGame PRIVATE "$<$<COMPILE_LANGUAGE:C>:-O2>" "$<$<COMPILE_LANGUAGE:CXX>:-fms-extensions>" -fno-strict-aliasing -Wno-unused-variable
    -Wno-implicit-function-declaration "-ffile-prefix-map=${ANNEPAD_ROOT}=.")
target_link_options(AnnePadGame PRIVATE "LINKER:-undefined,dynamic_lookup")
