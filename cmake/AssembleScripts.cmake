# AssembleScripts.cmake - Build-time helper to assemble AS sources for FFDEC
#
# Called at build time via cmake -P with these variables:
#   STAGING_DIR         - Output directory for assembled __Packages tree
#   SOURCES_FILE        - Path to a file listing absolute source paths (one per line)
#   FRAME_SOURCES_FILE  - (optional) Path to a file listing frame script paths (one per line)
#   AS_SOURCE_DIR       - Root of source/actionscript (to compute relative paths)
#
# Source layout:        <AS_SOURCE_DIR>/<Module>/<classpath>.as
# Output layout:        <STAGING_DIR>/__Packages/<classpath>.as
# Frame script layout:  <STAGING_DIR>/<filename>.as  (staged at root for DoInitAction)

file(REMOVE_RECURSE "${STAGING_DIR}")
file(MAKE_DIRECTORY "${STAGING_DIR}/__Packages")

file(STRINGS "${SOURCES_FILE}" SOURCES)

foreach(SRC ${SOURCES})
	# Get path relative to AS_SOURCE_DIR: <Module>/<classpath>.as
	file(RELATIVE_PATH REL "${AS_SOURCE_DIR}" "${SRC}")

	# Strip the first component (module name) to get classpath
	string(FIND "${REL}" "/" SLASH_POS)
	if(SLASH_POS EQUAL -1)
		message(WARNING "Unexpected source path (no module dir): ${SRC}")
		continue()
	endif()
	math(EXPR AFTER "${SLASH_POS} + 1")
	string(SUBSTRING "${REL}" ${AFTER} -1 CLASSPATH)

	set(DST "${STAGING_DIR}/__Packages/${CLASSPATH}")
	if(EXISTS "${SRC}")
		get_filename_component(DST_DIR "${DST}" DIRECTORY)
		file(MAKE_DIRECTORY "${DST_DIR}")
		file(COPY_FILE "${SRC}" "${DST}")

		# Patch version numbers in SkyUISplash.as to match the project version
		get_filename_component(DST_NAME "${DST}" NAME)
		if(DST_NAME STREQUAL "SkyUISplash.as"
				AND DEFINED PROJECT_VERSION_MAJOR
				AND DEFINED PROJECT_VERSION_MINOR)
			file(READ "${DST}" _SPLASH_CONTENT)
			string(REGEX REPLACE
				"(SKYUI_VERSION_MAJOR[ \t]*=[ \t]*)[0-9]+"
				"\\1${PROJECT_VERSION_MAJOR}"
				_SPLASH_CONTENT "${_SPLASH_CONTENT}")
			string(REGEX REPLACE
				"(SKYUI_VERSION_MINOR[ \t]*=[ \t]*)[0-9]+"
				"\\1${PROJECT_VERSION_MINOR}"
				_SPLASH_CONTENT "${_SPLASH_CONTENT}")
			file(WRITE "${DST}" "${_SPLASH_CONTENT}")
		endif()
	else()
		message(WARNING "Source not found: ${SRC}")
	endif()
endforeach()

# Stage frame scripts at root of STAGING_DIR (for DoInitAction / Object.registerClass)
if(DEFINED FRAME_SOURCES_FILE AND NOT FRAME_SOURCES_FILE STREQUAL "")
	if(EXISTS "${FRAME_SOURCES_FILE}")
		file(STRINGS "${FRAME_SOURCES_FILE}" FRAME_SOURCES)
		foreach(SRC ${FRAME_SOURCES})
			if(EXISTS "${SRC}")
				get_filename_component(FNAME "${SRC}" NAME)
				file(COPY_FILE "${SRC}" "${STAGING_DIR}/${FNAME}")
			else()
				message(WARNING "Frame source not found: ${SRC}")
			endif()
		endforeach()
	endif()
endif()
