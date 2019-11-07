# Try to find Libxc
# Exchange-Correlation functional library
#
# If successful, will define the required variables
# LibXC_FOUND - true if Libxc was found
# LibXC_INCLUDE_DIR - Containing xc_f03_lib_m.mod
# LibXC_LIBRARY - Location of libxc.a and libxcf03.a
#
# Copyright (c) 2019 Marco Scavino
# Distributed under the GNU Lesser General Public License.

#Where to look for Libxc

set(_LIBXC_NORMAL_SEARCH
  "/usr/local"
  "/usr/local/libxc"
  "/usr/opt/local/libxc")

set(LIBXC_ENV $ENV{LIBXC_ROOT})

if(LIBXC_ENV)
  set(LIBXC_ROOT ${LIBXC_ENV})
endif()

if(LIBXC_ROOT)
   message("-- LibXC will be searched for based on LIBXC_ROOT=" ${LIBXC_ROOT})
else()
   message("-- LibXC will be searched for based on default path ${_LIBXC_NORMAL_SEARCH}")
endif()

# Use the find_package macro to search in some possible paths

find_package(Libxc
  CONFIG
  PATHS ${LIBXC_ROOT} ${_LIBXC_NORMAL_SEARCH}
  NO_DEFAULT_PATH
  QUIET)

if(Libxc_LIBRARY)
   # If found libxc, get the library path
   get_filename_component(Libxc_DIR ${Libxc_LIBRARY} DIRECTORY)

   set(LibXC_LIBRARY ${Libxc_DIR}/libxcf03.a ${Libxc_LIBRARY})
   set(LibXC_INCLUDE_DIR ${Libxc_INCLUDE_DIRS})

else()

   #prepare for external project

   include(GNUInstallDirs)
   include(ExternalProject)

   set(libxc_library ${CMAKE_CURRENT_SOURCE_DIR}/external/libxc)

   set(libxc_install ${libxc_library}/install)

   message("-- Setting up the external project for LibXC in: ${libxc_library}")

   #External project to construct
   ExternalProject_add(project_libxc
      # git repository url
      GIT_REPOSITORY https://gitlab.com/libxc/libxc.git
      GIT_TAG 4.3.4
      # root directory of the project
      PREFIX ${libxc_library}
      # source directory in which git clones the repository
      SOURCE_DIR ${libxc_library}/repository
      # pacth for allow func_reference.c
      PATCH_COMMAND ${CMAKE_COMMAND} -E copy
         "${CMAKE_CURRENT_SOURCE_DIR}/cmake/findLibXC/Patch_libXC.txt"
         "${libxc_library}/repository/CMakeLists.txt"
      # arguments pass to cmake to configure the library project
      # CMAKE_INSTALL_PREFIX set for the project the install directory
      CMAKE_ARGS -DENABLE_FORTRAN03=on
               -DCMAKE_INSTALL_PREFIX:PATH=${libxc_install}
               -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
               -DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}
      # build directory
      BINARY_DIR ${libxc_library}/build
      #  temporary directory for the project
      STAMP_DIR ${libxc_library}/stamp
      TMP_DIR ${libxc_library}/tmp
      # command used to compile the code in the build directory
      BUILD_COMMAND $(MAKE)
      # install command
      INSTALL_COMMAND $(MAKE) install
      UPDATE_COMMAND ""
   )

   # add the two libraries
   add_library(libxc STATIC IMPORTED)
   add_library(libxcf03 STATIC IMPORTED)

   # link the IMPORTED library to its files
   set_property(TARGET libxc
      PROPERTY IMPORTED_LOCATION ${libxc_install}/${CMAKE_INSTALL_LIBDIR}/libxc.a)
   set_property(TARGET libxcf03
      PROPERTY IMPORTED_LOCATION ${libxc_install}/${CMAKE_INSTALL_LIBDIR}/libxcf03.a)

   # mandatory. set the library dependencies
   add_dependencies(libxc project_libxc)
   add_dependencies(libxcf03 libxc)

   #set DFT variables
   set(LibXC_INCLUDE_DIR ${libxc_install}/include)
   set(LibXC_LIBRARY libxcf03 libxc)

endif()


# Let the module handle the variables
include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(LibXC
   FOUND_VAR LibXC_FOUND
   REQUIRED_VARS LibXC_INCLUDE_DIR
                  LibXC_LIBRARY)
