#These are tribits wrappers only ever called by Kokkos itself

INCLUDE(CMakeParseArguments)
INCLUDE(CTest)

MESSAGE(STATUS "The project name is: ${PROJECT_NAME}")

#Leave this here for now - but only do for tribits
#This breaks the standalone CMake
IF (KOKKOS_HAS_TRILINOS)
  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_OpenMP)
    SET(${PROJECT_NAME}_ENABLE_OpenMP OFF)
  ENDIF()

  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_HPX)
    SET(${PROJECT_NAME}_ENABLE_HPX OFF)
  ENDIF()

  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_DEBUG)
    SET(${PROJECT_NAME}_ENABLE_DEBUG OFF)
  ENDIF()

  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_CXX11)
    SET(${PROJECT_NAME}_ENABLE_CXX11 ON)
  ENDIF()

  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_TESTS)
    SET(${PROJECT_NAME}_ENABLE_TESTS OFF)
  ENDIF()

  IF(NOT DEFINED TPL_ENABLE_Pthread)
    SET(TPL_ENABLE_Pthread OFF)
  ENDIF()
ENDIF()

MACRO(KOKKOS_SUBPACKAGE NAME)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_SUBPACKAGE(${NAME})
  else()
    SET(PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    SET(PARENT_PACKAGE_NAME ${PACKAGE_NAME})
    SET(PACKAGE_NAME ${PACKAGE_NAME}${NAME})
    STRING(TOUPPER ${PACKAGE_NAME} PACKAGE_NAME_UC)
    SET(${PACKAGE_NAME}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    #ADD_INTERFACE_LIBRARY(PACKAGE_${PACKAGE_NAME})
    #GLOBAL_SET(${PACKAGE_NAME}_LIBS "")
  endif()
ENDMACRO(KOKKOS_SUBPACKAGE)

MACRO(KOKKOS_SUBPACKAGE_POSTPROCESS)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_SUBPACKAGE_POSTPROCESS()
  endif()
ENDMACRO(KOKKOS_SUBPACKAGE_POSTPROCESS)

MACRO(KOKKOS_PACKAGE_DECL)

  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_PACKAGE_DECL(Kokkos)
  else()
    SET(PACKAGE_NAME Kokkos)
    SET(${PACKAGE_NAME}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    STRING(TOUPPER ${PACKAGE_NAME} PACKAGE_NAME_UC)
  endif()

  #SET(TRIBITS_DEPS_DIR "${CMAKE_SOURCE_DIR}/cmake/deps")
  #FILE(GLOB TPLS_FILES "${TRIBITS_DEPS_DIR}/*.cmake")
  #FOREACH(TPL_FILE ${TPLS_FILES})
  #  TRIBITS_PROCESS_TPL_DEP_FILE(${TPL_FILE})
  #ENDFOREACH()

ENDMACRO()


MACRO(KOKKOS_PROCESS_SUBPACKAGES)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_PROCESS_SUBPACKAGES()
  else()
    ADD_SUBDIRECTORY(core)
    ADD_SUBDIRECTORY(containers)
    ADD_SUBDIRECTORY(algorithms)
    ADD_SUBDIRECTORY(example)
  endif()
ENDMACRO(KOKKOS_PROCESS_SUBPACKAGES)

MACRO(KOKKOS_PACKAGE_DEF)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_PACKAGE_DEF()
  else()
    #do nothing
  endif()
ENDMACRO(KOKKOS_PACKAGE_DEF)

MACRO(KOKKOS_INTERNAL_ADD_LIBRARY_INSTALL LIBRARY_NAME)
  KOKKOS_LIB_TYPE(${LIBRARY_NAME} INCTYPE)
  TARGET_INCLUDE_DIRECTORIES(${LIBRARY_NAME} ${INCTYPE} $<INSTALL_INTERFACE:include>)

  INSTALL(
    TARGETS ${LIBRARY_NAME}
    EXPORT ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    COMPONENT ${PACKAGE_NAME}
  )

  INSTALL(
    TARGETS ${LIBRARY_NAME}
    EXPORT KokkosTargets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
  )

  INSTALL(
    TARGETS ${LIBRARY_NAME}
    EXPORT KokkosDeprecatedTargets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
  )

  VERIFY_EMPTY(KOKKOS_ADD_LIBRARY ${PARSE_UNPARSED_ARGUMENTS})
ENDMACRO(KOKKOS_INTERNAL_ADD_LIBRARY_INSTALL)

FUNCTION(KOKKOS_ADD_EXECUTABLE EXE_NAME)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_ADD_EXECUTABLE(${EXE_NAME} ${ARGN})
  else()
    CMAKE_PARSE_ARGUMENTS(PARSE 
      "TESTONLY"
      ""
      "SOURCES;TESTONLYLIBS"
      ${ARGN})

    ADD_EXECUTABLE(${EXE_NAME} ${PARSE_SOURCES})
    IF (PARSE_TESTONLYLIBS)
      TARGET_LINK_LIBRARIES(${EXE_NAME} ${PARSE_TESTONLYLIBS})
    ENDIF()
    #just link to a single lib kokkos now
    TARGET_LINK_LIBRARIES(${EXE_NAME} kokkos)
    VERIFY_EMPTY(KOKKOS_ADD_EXECUTABLE ${PARSE_UNPARSED_ARGUMENTS})
  endif()
ENDFUNCTION()

IF(NOT TARGET check)
  ADD_CUSTOM_TARGET(check COMMAND ${CMAKE_CTEST_COMMAND} -VV -C ${CMAKE_CFG_INTDIR})
ENDIF()


FUNCTION(KOKKOS_ADD_EXECUTABLE_AND_TEST ROOT_NAME)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_ADD_EXECUTABLE_AND_TEST(
    ${ROOT_NAME} 
    TESTONLYLIBS kokkos_gtest 
    ${ARGN}
    NUM_MPI_PROCS 1
    COMM serial mpi
    FAIL_REGULAR_EXPRESSION "  FAILED  "
  )
ELSE()
  CMAKE_PARSE_ARGUMENTS(PARSE 
    ""
    ""
    "SOURCES;CATEGORIES"
    ${ARGN})
  VERIFY_EMPTY(KOKKOS_ADD_EXECUTABLE_AND_TEST ${PARSE_UNPARSED_ARGUMENTS})
  SET(EXE_NAME ${PACKAGE_NAME}_${ROOT_NAME})
  KOKKOS_ADD_TEST_EXECUTABLE(${EXE_NAME}
    SOURCES ${PARSE_SOURCES}
  )
  KOKKOS_ADD_TEST(NAME ${ROOT_NAME} 
    EXE ${EXE_NAME}
    FAIL_REGULAR_EXPRESSION "  FAILED  "
  )
ENDIF()
ENDFUNCTION()

MACRO(KOKKOS_SETUP_BUILD_ENVIRONMENT)
 IF (NOT KOKKOS_HAS_TRILINOS)
  #------------ COMPILER AND FEATURE CHECKS ------------------------------------
  INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_functions.cmake)

  #------------ GET OPTIONS AND KOKKOS_SETTINGS --------------------------------
  # ADD Kokkos' modules to CMake's module path.
  SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${Kokkos_SOURCE_DIR}/cmake/Modules/")

  INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_enable_options.cmake)
  INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_cxx.cmake)
  INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_tpls.cmake)
  INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_arch.cmake)
 ENDIF()
ENDMACRO(KOKKOS_SETUP_BUILD_ENVIRONMENT)

MACRO(KOKKOS_ADD_TEST_EXECUTABLE EXE_NAME)
  CMAKE_PARSE_ARGUMENTS(PARSE 
    ""
    ""
    "SOURCES"
    ${ARGN})
  KOKKOS_ADD_EXECUTABLE(${EXE_NAME}
    SOURCES ${PARSE_SOURCES}
    ${PARSE_UNPARSED_ARGUMENTS}
    TESTONLYLIBS kokkos_gtest
  )
  IF (NOT KOKKOS_HAS_TRILINOS)
    TARGET_LINK_LIBRARIES(${EXE_NAME} kokkos_gtest)
    ADD_DEPENDENCIES(check ${EXE_NAME})
  ENDIF()
ENDMACRO(KOKKOS_ADD_TEST_EXECUTABLE)

MACRO(KOKKOS_PACKAGE_POSTPROCESS)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_PACKAGE_POSTPROCESS()
  endif()
ENDMACRO(KOKKOS_PACKAGE_POSTPROCESS)

MACRO(KOKKOS_MAKE_LIBKOKKOS)
  ADD_LIBRARY(kokkos ${KOKKOS_SOURCE_DIR}/core/src/dummy.cpp)
  TARGET_LINK_LIBRARIES(kokkos PUBLIC kokkoscore kokkoscontainers)
  TARGET_LINK_LIBRARIES(kokkos PUBLIC kokkosalgorithms)
  KOKKOS_INTERNAL_ADD_LIBRARY_INSTALL(kokkos)
ENDMACRO()

FUNCTION(KOKKOS_INTERNAL_ADD_LIBRARY LIBRARY_NAME)
  CMAKE_PARSE_ARGUMENTS(PARSE 
    "STATIC;SHARED"
    ""
    "HEADERS;SOURCES"
    ${ARGN})

  IF(PARSE_HEADERS)
    LIST(REMOVE_DUPLICATES PARSE_HEADERS)
  ENDIF()
  IF(PARSE_SOURCES)
    LIST(REMOVE_DUPLICATES PARSE_SOURCES)
  ENDIF()

  IF (KOKKOS_SEPARATE_LIBS)
    ADD_LIBRARY(
      ${LIBRARY_NAME}
      ${PARSE_HEADERS}
      ${PARSE_SOURCES}
    )
  ELSE()
    ADD_LIBRARY(
      ${LIBRARY_NAME}
      OBJECT
      ${PARSE_HEADERS}
      ${PARSE_SOURCES}
    )
  ENDIF()

  TARGET_COMPILE_OPTIONS(
    ${LIBRARY_NAME}
    PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${KOKKOS_COMPILE_OPTIONS}>
  )

  IF(${CMAKE_VERSION} VERSION_GREATER "3.13" OR ${CMAKE_VERSION} VERSION_EQUAL "3.13")
    TARGET_LINK_OPTIONS(
      ${LIBRARY_NAME}
      PUBLIC ${KOKKOS_LD_FLAGS}
    )
  ELSE()
    #Well, this is annoying - I am going to need to hack this for Visual Studio
    TARGET_LINK_LIBRARIES(
      ${LIBRARY_NAME} PUBLIC ${KOKKOS_LINK_OPTIONS}
    )
  ENDIF()

  IF (KOKKOS_ENABLE_CUDA)
    TARGET_COMPILE_OPTIONS(
      ${LIBRARY_NAME}
      PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${KOKKOS_CUDA_OPTIONS}>
    )
    SET(NODEDUP_CUDAFE_OPTIONS)
    FOREACH(OPT ${NODEDEUP_CUDAFE_OPTIONS})
      LIST(APPEND NODEDUP_CUDAFE_OPTIONS "-Xcudafe ${OPT}") 
    ENDFOREACH()
    TARGET_COMPILE_OPTIONS(
      ${LIBRARY_NAME} 
      PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${NODEDUP_CUDAFE_OPTIONS}>
    )
  ENDIF()

  IF(KOKKOS_XCOMPILER_OPTIONS)
    SET(NODEDUP_XCOMPILER_OPTIONS)
    FOREACH(OPT ${KOKKOS_XCOMPILER_OPTIONS})
      LIST(APPEND NODEDUP_XCOMPILER_OPTIONS "-Xcompiler ${OPT}") 
    ENDFOREACH()
    TARGET_COMPILE_OPTIONS(
      ${LIBRARY_NAME} 
      PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${NODEDUP_XCOMPILER_OPTIONS}>
    )
  ENDIF()



  TARGET_INCLUDE_DIRECTORIES(
    ${LIBRARY_NAME}
    PUBLIC ${KOKKOS_TPL_INCLUDE_DIRS}
  )

  IF (KOKKOS_ENABLE_CUDA)
    SET(LIB_cuda "-lcuda")
    TARGET_LINK_LIBRARIES(${LIBRARY_NAME} PUBLIC cuda)
  ENDIF()

  IF (KOKKOS_ENABLE_HPX)
    TARGET_LINK_LIBRARIES(${LIBRARY_NAME} PUBLIC ${HPX_LIBRARIES})
    TARGET_INCLUDE_DIRECTORIES(${LIBRARY_NAME} PUBLIC ${HPX_INCLUDE_DIRS})
  ENDIF()

  IF (KOKKOS_ENABLE_HWLOC)
    TARGET_LINK_LIBRARIES(${LIBRARY_NAME} PRIVATE hwloc)
  ENDIF()

  IF (KOKKOS_ENABLE_MEMKIND)
    TARGET_LINK_LIBRARIES(${LIBRARY_NAME} PRIVATE memkind)
  ENDIF()

  IF (KOKKOS_CXX_STANDARD_FEATURE)
    #GREAT! I can't do this the right way
    TARGET_COMPILE_FEATURES(${LIBRARY_NAME} PUBLIC ${KOKKOS_CXX_STANDARD_FEATURE})
  ELSE()
    #OH, Well, no choice but the wrong way
    TARGET_COMPILE_OPTIONS(${LIBRARY_NAME} PUBLIC ${KOKKOS_CXX_STANDARD_FLAG})
  ENDIF()

  #Even if separate libs and these are object libraries
  #We still need to install them for transitive flags and deps
  KOKKOS_INTERNAL_ADD_LIBRARY_INSTALL(${LIBRARY_NAME})

  INSTALL(
    FILES  ${PARSE_HEADERS}
    DESTINATION include
    COMPONENT ${PACKAGE_NAME}
  )

ENDFUNCTION(KOKKOS_INTERNAL_ADD_LIBRARY LIBRARY_NAME)

FUNCTION(KOKKOS_ADD_LIBRARY LIBRARY_NAME)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_ADD_LIBRARY(${LIBRARY_NAME} ${ARGN})
  else()
    KOKKOS_INTERNAL_ADD_LIBRARY(
      ${LIBRARY_NAME} ${ARGN})
  endif()
ENDFUNCTION()

FUNCTION(KOKKOS_ADD_INTERFACE_LIBRARY NAME)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_ADD_LIBRARY(${NAME} ${ARGN})
ELSE()
  CMAKE_PARSE_ARGUMENTS(PARSE
    ""
    ""
    "HEADERS;SOURCES"
    ${ARGN}
  )

  ADD_LIBRARY(${NAME} INTERFACE)
  KOKKOS_INTERNAL_ADD_LIBRARY_INSTALL(${NAME})

  INSTALL(
    FILES  ${PARSE_HEADERS}
    DESTINATION include
  )

  INSTALL(
    FILES  ${PARSE_HEADERS}
    DESTINATION include
    COMPONENT ${PACKAGE_NAME}
  )
ENDIF()
ENDFUNCTION(KOKKOS_ADD_INTERFACE_LIBRARY)

FUNCTION(KOKKOS_LIB_COMPILE_DEFINITIONS)
  IF(KOKKOS_HAS_TRILINOS)
    #don't trust tribits to do this correctly
    KOKKOS_TARGET_COMPILE_DEFINITIONS(${TARGET} ${ARGN})
  ELSE(TARGET ${TARGET})
    KOKKOS_LIB_TYPE(${TARGET} INCTYPE)
    KOKKOS_TARGET_COMPILE_DEFINITIONS(${${PROJECT_NAME}_LIBRARY_NAME_PREFIX}${TARGET} ${INCTYPE} ${ARGN})
  ENDIF()
ENDFUNCTION(KOKKOS_LIB_COMPILE_DEFINITIONS)

FUNCTION(KOKKOS_LIB_INCLUDE_DIRECTORIES TARGET)
  IF(KOKKOS_HAS_TRILINOS)
    #ignore the target, tribits doesn't do anything directly with targets
    TRIBITS_INCLUDE_DIRECTORIES(${ARGN})
  ELSE() #append to a list for later
    KOKKOS_LIB_TYPE(${TARGET} INCTYPE) 
    FOREACH(DIR ${ARGN})
      TARGET_INCLUDE_DIRECTORIES(${TARGET} ${INCTYPE} $<BUILD_INTERFACE:${DIR}>)
    ENDFOREACH()
  ENDIF()
ENDFUNCTION(KOKKOS_LIB_INCLUDE_DIRECTORIES)

FUNCTION(KOKKOS_LIB_COMPILE_OPTIONS TARGET)
  IF(KOKKOS_HAS_TRILINOS)
    #don't trust tribits to do this correctly
    KOKKOS_TARGET_COMPILE_OPTIONS(${TARGET} ${ARGN})
  ELSE()
    KOKKOS_LIB_TYPE(${TARGET} INCTYPE)
    KOKKOS_TARGET_COMPILE_OPTIONS(${${PROJECT_NAME}_LIBRARY_NAME_PREFIX}${TARGET} ${INCTYPE} ${ARGN})
  ENDIF()
ENDFUNCTION(KOKKOS_LIB_COMPILE_OPTIONS)

MACRO(KOKKOS_ADD_TEST_DIRECTORIES)
  IF (KOKKOS_HAS_TRILINOS)
    TRIBITS_ADD_TEST_DIRECTORIES(${ARGN})
  ELSE()
    IF(KOKKOS_ENABLE_TESTS)
      FOREACH(TEST_DIR ${ARGN})
        ADD_SUBDIRECTORY(${TEST_DIR})
      ENDFOREACH()
    ENDIF()
  ENDIF()
ENDMACRO()

MACRO(KOKKOS_ADD_EXAMPLE_DIRECTORIES)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_ADD_EXAMPLE_DIRECTORIES(${ARGN})
  else()
    IF(KOKKOS_ENABLE_EXAMPLES)
      FOREACH(EXAMPLE_DIR ${ARGN})
        ADD_SUBDIRECTORY(${EXAMPLE_DIR})
      ENDFOREACH()
    ENDIF()
  endif()
ENDMACRO()
