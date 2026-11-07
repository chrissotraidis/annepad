function(annepad_module_identity root output)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    file(GLOB_RECURSE contract_sources CONFIGURE_DEPENDS
        "${root}/apple/*.h" "${root}/apple/*.hpp" "${root}/apple/*.cpp" "${root}/apple/*.mm" "${root}/apple/*.txt"
        "${root}/patches/*.patch" "${root}/cmake/*.cmake" "${root}/cmake/*.txt" "${root}/cmake/*.manifest"
        "${root}/scripts/*.py" "${root}/scripts/*.sh")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${contract_sources}
        "${root}/dependencies.lock.json" "${root}/version.json")
    execute_process(COMMAND "${Python3_EXECUTABLE}" -X utf8 -B "${root}/scripts/module-identity.py"
        OUTPUT_VARIABLE identity OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL ANY)
    set(${output} "${identity}" PARENT_SCOPE)
endfunction()
