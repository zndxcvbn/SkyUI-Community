#[=======================================================================[.rst:
SWFXMLPatch
-----------

Logic to rebuild a SWF from its XML source.

Usage
^^^^^

  Add_XML_Base(
      OUTPUT_SWF <absolute/path/to/base.swf>
      XML_PATH   <relative/path/to/patch.xml>
  )

#]=======================================================================]

# ---------------------------------------------------------------------------
# Add_XML_Base
# ---------------------------------------------------------------------------
function(Add_XML_Base)
    cmake_parse_arguments(ARG "" "OUTPUT_SWF;XML_PATH" "" ${ARGN})

    if(NOT ARG_OUTPUT_SWF)
        message(FATAL_ERROR "Add_XML_Base: OUTPUT_SWF is required.")
    endif()
    if(NOT ARG_XML_PATH)
        message(FATAL_ERROR "Add_XML_Base: XML_PATH is required.")
    endif()
    if(NOT FFDEC_CLI)
        message(FATAL_ERROR "Add_XML_Base: FFDEC_CLI is not set.")
    endif()

    set(_XML_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/source/swf/${ARG_XML_PATH}")

    if(NOT EXISTS "${_XML_SOURCE}")
        message(FATAL_ERROR "Add_XML_Base: XML source not found: ${_XML_SOURCE}")
    endif()

    add_custom_command(
        OUTPUT "${ARG_OUTPUT_SWF}"
        COMMAND "${CMAKE_COMMAND}" -E echo "[Build] ffdec -xml2swf ${ARG_XML_PATH}"
        COMMAND "${FFDEC_CLI}" -xml2swf "${_XML_SOURCE}" "${ARG_OUTPUT_SWF}"
        DEPENDS "${_XML_SOURCE}"
        VERBATIM
    )
endfunction()
