#[=======================================================================[.rst:
Deploy
------

Build-time helper to deploy built files to the game directory or MO2 folder.
Invoked via cmake -P.

Variables expected:
  OUTPUT_DIR             - destination root (MOD_DEBUG_PATH)
  DEPLOY_LISTS_DIR       - directory containing the list files below
  SWF_COMPILED_BASE      - base dir for relative path calculation (build tree)
  SWF_PASSTHROUGH_BASE   - base dir for relative path calculation (source tree)

List files (in DEPLOY_LISTS_DIR):
  pex_files.txt          - absolute paths to .pex files
  swf_compiled.txt       - absolute paths to built .swf files
  swf_passthrough.txt    - absolute paths to original .swf files
  esp_file.txt           - absolute path to the .esp

#]=======================================================================]

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

foreach(REQUIRED_VAR OUTPUT_DIR DEPLOY_LISTS_DIR SWF_COMPILED_BASE SWF_PASSTHROUGH_BASE)
    if(NOT DEFINED ${REQUIRED_VAR} OR "${${REQUIRED_VAR}}" STREQUAL "")
        message(FATAL_ERROR "Deploy.cmake: ${REQUIRED_VAR} is not set.")
    endif()
endforeach()

# ---------------------------------------------------------------------------
# Deployment Logic
# ---------------------------------------------------------------------------

# 1. PEX Scripts
set(_PEX_LIST_FILE "${DEPLOY_LISTS_DIR}/pex_files.txt")
if(EXISTS "${_PEX_LIST_FILE}")
    file(STRINGS "${_PEX_LIST_FILE}" _PEX_FILES)
    foreach(_PEX ${_PEX_FILES})
        if(EXISTS "${_PEX}")
            file(COPY_FILE "${_PEX}" "${OUTPUT_DIR}/scripts/${_PEX_NAME}" ONLY_IF_DIFFERENT)
        else()
            message(WARNING "Deploy.cmake: .pex not found: ${_PEX}")
        endif()
    endforeach()
    message(STATUS "  Deployed scripts")
endif()

# 2. Compiled SWFs
set(_SWF_C_LIST_FILE "${DEPLOY_LISTS_DIR}/swf_compiled.txt")
if(EXISTS "${_SWF_C_LIST_FILE}")
    file(STRINGS "${_SWF_C_LIST_FILE}" _SWF_FILES)
    foreach(_SWF ${_SWF_FILES})
        if(EXISTS "${_SWF}")
            file(RELATIVE_PATH _REL "${SWF_COMPILED_BASE}" "${_SWF}")
            file(COPY_FILE "${_SWF}" "${OUTPUT_DIR}/interface/${_REL}" ONLY_IF_DIFFERENT)
        endif()
    endforeach()
    message(STATUS "  Deployed compiled SWFs")
endif()

# 3. Passthrough SWFs
set(_SWF_P_LIST_FILE "${DEPLOY_LISTS_DIR}/swf_passthrough.txt")
if(EXISTS "${_SWF_P_LIST_FILE}")
    file(STRINGS "${_SWF_P_LIST_FILE}" _SWF_FILES)
    foreach(_SWF ${_SWF_FILES})
        if(EXISTS "${_SWF}")
            file(RELATIVE_PATH _REL "${SWF_PASSTHROUGH_BASE}" "${_SWF}")
            file(COPY_FILE "${_SWF}" "${OUTPUT_DIR}/interface/${_REL}" ONLY_IF_DIFFERENT)
        endif()
    endforeach()
endif()

# 4. ESP File
set(_ESP_LIST_FILE "${DEPLOY_LISTS_DIR}/esp_file.txt")
if(EXISTS "${_ESP_LIST_FILE}")
    file(STRINGS "${_ESP_LIST_FILE}" _ESP_FILES)
    foreach(_ESP ${_ESP_FILES})
        get_filename_component(_ESP_NAME "${_ESP}" NAME)
        file(COPY_FILE "${_ESP}" "${OUTPUT_DIR}/${_ESP_NAME}" ONLY_IF_DIFFERENT)
    endforeach()
    message(STATUS "  Deployed ${_ESP_NAME}")
endif()

message(STATUS "Deploy complete -> ${OUTPUT_DIR}")
