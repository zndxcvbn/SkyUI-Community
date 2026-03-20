#[=======================================================================[.rst:
Package
-------

Build-time helper to package the build artefacts into a distribution ZIP.
Invoked via cmake -P.

Variables expected:
  STAGING_DIR   - directory to stage files into before zipping
  BSA_FILE      - absolute path to the built .bsa
  ESP_FILE      - absolute path to the .esp
  ZIP_OUTPUT    - absolute path to the final .zip

#]=======================================================================]

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

foreach(REQUIRED_VAR STAGING_DIR BSA_FILE ESP_FILE ZIP_OUTPUT)
    if(NOT DEFINED ${REQUIRED_VAR} OR "${${REQUIRED_VAR}}" STREQUAL "")
        message(FATAL_ERROR "Package.cmake: ${REQUIRED_VAR} is not set.")
    endif()
endforeach()

# ---------------------------------------------------------------------------
# Packaging Logic
# ---------------------------------------------------------------------------

message(STATUS "Packaging -> ${ZIP_OUTPUT}")

# 1. Create staging and output directories
file(MAKE_DIRECTORY "${STAGING_DIR}")

get_filename_component(_ZIP_DIR "${ZIP_OUTPUT}" DIRECTORY)
if(NOT EXISTS "${_ZIP_DIR}")
    file(MAKE_DIRECTORY "${_ZIP_DIR}")
endif()

# 2. Copy files into staging
get_filename_component(_BSA_NAME "${BSA_FILE}" NAME)
get_filename_component(_ESP_NAME "${ESP_FILE}" NAME)

if(EXISTS "${BSA_FILE}")
    file(COPY_FILE "${BSA_FILE}" "${STAGING_DIR}/${_BSA_NAME}" ONLY_IF_DIFFERENT)
    message(STATUS "  Staged: ${_BSA_NAME}")
else()
    message(FATAL_ERROR "Package.cmake: BSA file not found: ${BSA_FILE}")
endif()

if(EXISTS "${ESP_FILE}")
    file(COPY_FILE "${ESP_FILE}" "${STAGING_DIR}/${_ESP_NAME}" ONLY_IF_DIFFERENT)
    message(STATUS "  Staged: ${_ESP_NAME}")
else()
    message(FATAL_ERROR "Package.cmake: ESP file not found: ${ESP_FILE}")
endif()

# 3. Create ZIP archive
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar cf "${ZIP_OUTPUT}" --format=zip
        "${_BSA_NAME}"
        "${_ESP_NAME}"
    WORKING_DIRECTORY "${STAGING_DIR}"
)

message(STATUS "  Created: ${ZIP_OUTPUT}")
