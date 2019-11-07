# Try to find external_lib
# Exchange-Correlation functional library
#
# If successful, will define the required variables
# external_lib_FOUND - true if external_lib was found
# external_lib_INCLUDE_DIR - Containing xc_f03_lib_m.mod
# external_lib_LIBRARY - Location of external_lib.a and external_libf03.a
#
# Copyright (c) 2019 Marco Scavino
# Distributed under the GNU Lesser General Public License.

#Where to look for external_lib

set(_EXTERNAL_LIB_NORMAL_SEARCH
  "/usr/local"
  "/usr/local/external_lib"
  "/usr/opt/local/external_lib")

# read the environmental variable for ExternalLib.
set(EXTERNAL_LIB_ENV $ENV{EXTERNAL_LIB_ROOT})

# If environmental varaibel exists, set up the local variable
if(EXTERNAL_LIB_ENV)
  set(EXTERNAL_LIB_ROOT ${EXTERNAL_LIB_ENV})
endif()

# Some printing for the final user, about which path is used to search
if(EXTERNAL_LIB_ROOT)
   message("-- external_lib will be searched for based on EXTERNAL_LIB_ROOT=" ${EXTERNAL_LIB_ROOT})
else()
   message("-- external_lib will be searched for based on default path ${_EXTERNAL_LIB_NORMAL_SEARCH}")
endif()

# Use the find_package macro to search in some possible paths the cmake files of library

find_package(External_lib
  CONFIG
  PATHS ${EXTERNAL_LIB_ROOT} ${_EXTERNAL_LIB_NORMAL_SEARCH} # path to search
  NO_DEFAULT_PATH # no search in default path
  QUIET # no print if package is not found. However it will print a misleading "Package not found!"
)

if(external_lib_LIBRARY)
   # If found external_lib, get the library path
   get_filename_component(external_lib_DIR ${external_lib_LIBRARY} DIRECTORY)

   set(external_lib_LIBRARY ${external_lib_DIR}/external_libf03.a ${external_lib_LIBRARY})
   set(external_lib_INCLUDE_DIR ${external_lib_INCLUDE_DIRS})

else()

   #prepare for external project

   include(GNUInstallDirs)
   include(ExternalProject)

   set(external_lib_library ${CMAKE_CURRENT_SOURCE_DIR}/external/external_lib)

   set(external_lib_install ${external_lib_library}/install)

   message("-- Setting up the external project for external_lib in: ${external_lib_library}")

   #External project to construct
   ExternalProject_add(project_external_lib
      # git repository url
      GIT_REPOSITORY # <= put here the external library git repository to clone it if needed
      GIT_TAG 4.3.4
      # root directory of the project
      PREFIX ${external_lib_library}
      # source directory in which git clones the repository
      SOURCE_DIR ${external_lib_library}/repository
      # pacth for allow func_reference.c
      PATCH_COMMAND ${CMAKE_COMMAND} -E copy
         "${CMAKE_CURRENT_SOURCE_DIR}/cmake/findexternal_lib/Patch_external_lib.txt"
         "${external_lib_library}/repository/CMakeLists.txt"
      # arguments pass to cmake to configure the library project
      # CMAKE_INSTALL_PREFIX set for the project the install directory
      CMAKE_ARGS -DENABLE_FORTRAN03=on
               -DCMAKE_INSTALL_PREFIX:PATH=${external_lib_install}
               -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
               -DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}
      # build directory
      BINARY_DIR ${external_lib_library}/build
      #  temporary directory for the project
      STAMP_DIR ${external_lib_library}/stamp
      TMP_DIR ${external_lib_library}/tmp
      # command used to compile the code in the build directory
      BUILD_COMMAND $(MAKE)
      # install command
      INSTALL_COMMAND $(MAKE) install
      UPDATE_COMMAND ""
   )

   # add the two libraries
   add_library(external_lib STATIC IMPORTED)
   add_library(external_libf03 STATIC IMPORTED)

   # link the IMPORTED library to its files
   set_property(TARGET external_lib
      PROPERTY IMPORTED_LOCATION ${external_lib_install}/${CMAKE_INSTALL_LIBDIR}/external_lib.a)
   set_property(TARGET external_libf03
      PROPERTY IMPORTED_LOCATION ${external_lib_install}/${CMAKE_INSTALL_LIBDIR}/external_libf03.a)

   # mandatory. set the library dependencies
   add_dependencies(external_lib project_external_lib)
   add_dependencies(external_libf03 external_lib)

   #set DFT variables
   set(external_lib_INCLUDE_DIR ${external_lib_install}/include)
   set(external_lib_LIBRARY external_libf03 external_lib)

endif()


# Let the module handle the variables
include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(external_lib
   FOUND_VAR external_lib_FOUND
   REQUIRED_VARS external_lib_INCLUDE_DIR
                  external_lib_LIBRARY)
