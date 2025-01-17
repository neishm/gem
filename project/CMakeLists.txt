cmake_minimum_required(VERSION 2.8.12)

project(GEM NONE)

cmake_policy(SET CMP0066 NEW)
cmake_policy(SET CMP0056 NEW)

# set the compiler suite by uncommenting one of the following 3 lines:
set(COMPILER gnu CACHE STRING compiler)
#set(COMPILER intel CACHE STRING compiler)
#set(COMPILER pgi CACHE STRING compiler)
message(STATUS "Compiler suite to be used is: ${COMPILER}")

# CMAKE_BUILD_TYPE can be one of Debug, Release, RelWithDebInfo, MinSizeRel
if (NOT CMAKE_BUILD_TYPE)
  message(STATUS "CMAKE_BUILD_TYPE can be one of Debug, Release, RelWithDebInfo, MinSizeRel")
  message(STATUS "No build type selected, default to RelWithDebInfo")
  set(CMAKE_BUILD_TYPE "RelWithDebInfo")
endif()

message(STATUS "Configuring for ${CMAKE_BUILD_TYPE} build type")

# Include a file that contains settings for a particular architecture and
# compiler, using the default value of the compiler defined above or the
# argument given to cmake command.
set(ARCH "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")

message(STATUS "include ${ARCH}-${COMPILER}.cmake")
include("${ARCH}-${COMPILER}.cmake")

# TODO: This isn't used presently.  Check to see if we need it
# set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMakeModules)

option(EXTRA_CHECKS "Compile with extra checks to detect things such as overunned bounds and stack trashing" OFF)

# To build without OpenMP, you have to add -DWITH_OPENMP=0 to the cmake command line
option(WITH_OPENMP "Build with OpenMP support" ON)
if (WITH_OPENMP)
   find_package(OpenMP)
   if (NOT OPENMP_FOUND)
      message(FATAL_ERROR "OpenMP was requested, but was not found!")
   endif()
   if(OpenMP_C_FLAGS)
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
   endif()
   if(OpenMP_Fortran_FLAGS)
      set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_Fortran_FLAGS}")
   else()
      # If we can't find Fortran flags, fallback on C flags
      message(WARNING "OpenMP couldn't find Fortran OpenMP Flags.  Falling back on C Flags.")
      set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_C_FLAGS}")
   endif()
else()
   message(STATUS "Building WITHOUT OpenMP")
endif()

message(STATUS "CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
message(STATUS "CMAKE_Fortran_FLAGS=${CMAKE_Fortran_FLAGS}")
if (${CMAKE_BUILD_TYPE} MATCHES Debug )
  message(STATUS "CMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}")
  message(STATUS "CMAKE_Fortran_FLAGS_DEBUG=${CMAKE_Fortran_FLAGS_DEBUG}")
endif()

option(WITH_OPENACC "Build with OpenACC support" OFF)
if (WITH_OPENACC)
   find_package(OpenACC)
   if (OPENACC_NOTFOUND)
      message(FATAL_ERROR "OpenACC was requested, but was not found!")
   endif()
   if(OpenACC_C_FLAGS)
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenACC_C_FLAGS} ${OpenACC_extra_FLAGS}")
   endif()
   if(OpenACC_Fortran_FLAGS)
      set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenACC_Fortran_FLAGS}")
   elseif(OpenACC_C_FLAGS)
      # Fallback on C flags and hope it also works for Fortran
      set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenACC_C_FLAGS} ${OpenACC_extra_FLAGS}")
   endif()
else()
   message(STATUS "Building WITHOUT OpenACC")
endif()

# get name and version of operating system
execute_process(COMMAND sh "-c" "${CMAKE_CURRENT_SOURCE_DIR}/os.sh" OUTPUT_VARIABLE OS)
message(STATUS "Operating system is: ${OS}")

# get name and version of compiler
execute_process(COMMAND sh "-c" "${CMAKE_CURRENT_SOURCE_DIR}/compiler.sh ${COMPILER}" OUTPUT_VARIABLE COMP_VERSION)
message(STATUS "Compiler version is: ${COMPILER} ${COMP_VERSION}")

# Enable distclean target
include("distclean.cmake")

set(CMAKE_Fortran_SOURCE_FILE_EXTENSIONS f;f90;F90 CACHE STRING "Fortran extension files")

# This was changed so that there cannot be an upstream call
#set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/modules CACHE STRING "Where Fortran modules go")

get_filename_component(ROOT ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY CACHE)
message(STATUS "ROOT=${ROOT}")
#message(STATUS "Sources directory is: ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "Build directory is: ${CMAKE_CURRENT_BINARY_DIR}")

file(READ "${ROOT}/VERSION" GEM_VERSION)
string(REGEX REPLACE "\n$" "" GEM_VERSION "${GEM_VERSION}")
message(STATUS "GEM_VERSION=${GEM_VERSION}")
# Include an architecture dependent file that contains include files for a
# particular architecture and compiler, using the default value of the
# compiler defined above or the argument given to cmake command.
message(STATUS "arch-dependent include directory: ${ROOT}/src/archdep/include/${ARCH}-${COMPILER}")

include_directories(
   ${ROOT}/src/archdep/include/${ARCH}-${COMPILER}
   ${ROOT}/src/rpn-si/mpi-extras
   ${ROOT}/src/rpn-si/rpncomm
   ${ROOT}/src/rpn-si/rmn/PUBLIC_INCLUDES
   ${ROOT}/src/rpn-si/RPN/compiler_includes
)

# Instead of adding -I. to the FLAGS, we can let cmake add the current folder automatically
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# To see the make commands
#set(CMAKE_VERBOSE_MAKEFILE ON)

add_subdirectory(${ROOT}/src src)

# TODO: Move this to cmake_shared
function(dir_writable DIR_PATH REQUIRED)
    # Check that the path given in DIR_PATH is writable.  If DIR_PATH does not
    # exist, it checks if it can be created.
    # The result is returned in the DIR_WRITABLE variable in the calling scope
    # If REQUIRED is specified, dir_writable will throw a FATAL_ERROR

    execute_process(COMMAND test -e ${DIR_PATH} RESULT_VARIABLE INSTALL_PREFIX_NOT_EXISTS)
    if (INSTALL_PREFIX_NOT_EXISTS)
        execute_process(COMMAND dirname ${DIR_PATH} OUTPUT_VARIABLE TEST_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)
    else()
        set(TEST_DIR ${DIR_PATH})
    endif()

    execute_process(COMMAND test -w ${TEST_DIR} RESULT_VARIABLE DIR_NOT_WRITABLE)
    if (REQUIRED AND DIR_NOT_WRITABLE EQUAL 1)
        message(FATAL_ERROR "${DIR_PATH} is not writable!")
    endif()
    set(DIR_WRITABLE PARENT_SCOPE NOT DIR_NOT_WRITABLE)
endfunction()
# END TODO: Move this to cmake_shared

# get name and version of operating system
execute_process(COMMAND sh "-c" "${CMAKE_CURRENT_SOURCE_DIR}/os.sh" OUTPUT_VARIABLE OS)
message(STATUS "Operating system is: ${OS}")

# get name and version of compiler
if(DEFINED ENV{COMPILER_version})
   set(COMPILER_version $ENV{COMPILER_version})
else()
  execute_process(COMMAND sh "-c" "${CMAKE_CURRENT_SOURCE_DIR}/compiler.sh ${COMPILER}" OUTPUT_VARIABLE COMPILER_version)
endif()

set(WORK_PREFIX ${ROOT} CACHE FILEPATH "Execution environment directory")
dir_writable(${WORK_PREFIX} TRUE)
if(DEFINED ENV{GEM_WORK})
   set(WORK_DIR ${WORK_PREFIX}/$ENV{GEM_WORK})
else()
  set(WORK_DIR ${WORK_PREFIX}/work-${OS}-${COMPILER}-${COMPILER_version})
endif()
message(STATUS "Working directory is ${WORK_DIR}")
add_custom_target(work
    /bin/mkdir -p ${WORK_DIR}/bin
    COMMAND /bin/cp -avf
        $<TARGET_FILE:cclargs_lite>
        $<TARGET_FILE:editfst>
        $<TARGET_FILE:flipit>
        $<TARGET_FILE:fstcomp>
        $<TARGET_FILE:fststat>
        $<TARGET_FILE:maingemdm>
        $<TARGET_FILE:gemgrid>
        $<TARGET_FILE:yy2global>
        $<TARGET_FILE:feseri>
        $<TARGET_FILE:prphynml>
        $<TARGET_FILE:checkdmpart>
        $<TARGET_FILE:prgemnml>
        $<TARGET_FILE:gem_monitor_output>
        $<TARGET_FILE:gem_monitor_end>
        $<TARGET_FILE:pgsm>
        $<TARGET_FILE:r.fstinfo>
        $<TARGET_FILE:voir>
        ${WORK_DIR}/bin
    COMMAND /bin/ln -sf ${ROOT}/configurations ${WORK_DIR}
    COMMAND /bin/cp -avf ${ROOT}/doc/README.run ${WORK_DIR}

    DEPENDS
        cclargs_lite
        editfst
        flipit
        fstcomp
        fststat
        maingemdm
        gemgrid
        yy2global
        feseri
        prphynml
        checkdmpart
        prgemnml
        gem_monitor_output
        gem_monitor_end
        r.fstinfo
        voir
)

# TODO: Make the actual installation in CMAKE_INSTALL_PREFIX
    # message(STATUS "CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}")
    # dir_writable(CMAKE_INSTALL_PREFIX TRUE)
