cmake_minimum_required(VERSION 3.20)

project(AnnePadAppleCore LANGUAGES C CXX)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    message(FATAL_ERROR "AnnePadAppleCore must be cross-compiled with CMAKE_SYSTEM_NAME=iOS")
endif()

set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(ANNEPAD_SHIPPING_CORE "Optimize the generated AOT core for release packaging" OFF)

get_filename_component(ANNEPAD_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(ANNEPAD_GAME_ROOT "${ANNEPAD_ROOT}/external/sources/PokemonStadiumRecomp")
set(ANNEPAD_RUNTIME_ROOT "${ANNEPAD_ROOT}/external/sources/N64ModernRuntime")

if(NOT EXISTS "${ANNEPAD_GAME_ROOT}/generated/lookup.cpp")
    message(FATAL_ERROR "Generated game sources are missing; run scripts/generate-game.sh first")
endif()

# Apple mobile targets are static-only. Runtime recompilers, executable-memory
# backends, and plug-in loading are compile-time exclusions rather than runtime
# switches.
set(N64MODERN_NO_DYNAMIC_CODE ON CACHE BOOL "" FORCE)
set(WITH_ARES_BRIDGE OFF CACHE BOOL "" FORCE)
set(WITH_DEV_DIVERGENCE OFF CACHE BOOL "" FORCE)
set(PSR_TCC_DEV_TOOLS OFF CACHE BOOL "" FORCE)

add_subdirectory("${ANNEPAD_RUNTIME_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/runtime")

if(TARGET fmt)
    target_compile_definitions(fmt PUBLIC FMT_USE_CONSTEVAL=0)
endif()

file(GLOB ANNEPAD_RECOMPILED_SOURCES CONFIGURE_DEPENDS
    "${ANNEPAD_GAME_ROOT}/generated/*.c")

add_library(AnnePadRecompiledCore STATIC ${ANNEPAD_RECOMPILED_SOURCES})
if(ANNEPAD_SHIPPING_CORE)
    set(ANNEPAD_AOT_OPTIMIZATION -O2)
else()
    set(ANNEPAD_AOT_OPTIMIZATION -O0)
endif()
target_compile_options(AnnePadRecompiledCore PRIVATE
    ${ANNEPAD_AOT_OPTIMIZATION}
    -fno-strict-aliasing
    -Wno-unused-variable
    -Wno-implicit-function-declaration
)
target_include_directories(AnnePadRecompiledCore PRIVATE
    "${ANNEPAD_GAME_ROOT}/include"
    "${ANNEPAD_RUNTIME_ROOT}/ultramodern/include"
    "${ANNEPAD_RUNTIME_ROOT}/librecomp/include"
    "${ANNEPAD_RUNTIME_ROOT}/N64Recomp/include"
)

add_library(AnnePadCore STATIC src/core_profile.cpp)
target_include_directories(AnnePadCore PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_compile_definitions(AnnePadCore PUBLIC N64MODERN_NO_DYNAMIC_CODE=1)
target_link_libraries(AnnePadCore PUBLIC
    AnnePadRecompiledCore
    librecomp
    ultramodern
)

set_target_properties(AnnePadCore AnnePadRecompiledCore PROPERTIES
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
)
