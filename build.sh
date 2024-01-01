#!/bin/sh -ex

export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)

PYTHON=$(which ${PYTHON:-python})

WASI_SDK=wasi-sdk-20.0
WASI_SDK_URL=https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20/wasi-sdk-20.0-linux.tar.gz
if ! [ -d ${WASI_SDK} ]; then curl -L ${WASI_SDK_URL} | tar xzf -; fi
WASI_SDK_PATH=$(pwd)/${WASI_SDK}

PICOSAT_DIR=picosat-965
PICOSAT_URL=http://fmv.jku.at/picosat/picosat-965.tar.gz
if ! [ -d ${PICOSAT_DIR} ]; then curl -L ${PICOSAT_URL} | tar xzf -; fi

# Threading is currently experimental.
WASI_TARGET="wasm32-wasi"
WASI_SYSROOT="--sysroot ${WASI_SDK_PATH}/share/wasi-sysroot"
WASI_CFLAGS="-flto"
WASI_LDFLAGS="-flto -Wl,--strip-all"
# BOOST_THREADING="single"
# BOOST_ADD_CXXFLAGS="-DBOOST_NO_CXX11_HDR_MUTEX"
# BOOST_ADD_LIBRARIES=""
if [ ${THREADS:-0} -ne 0 ]; then
  WASI_TARGET="${WASI_TARGET}-threads"
  WASI_CFLAGS="${WASI_CFLAGS} -pthread"
  WASI_LDFLAGS="${WASI_LDFLAGS} -Wl,--import-memory,--export-memory,--max-memory=4294967296"
#   BOOST_THREADING="multi"
#   BOOST_ADD_CXXFLAGS=""
#   BOOST_ADD_LIBRARIES="--with-thread"
fi

cat >Toolchain-WASI.cmake <<END
cmake_minimum_required(VERSION 3.4.0)

set(WASI TRUE)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)

set(CMAKE_C_COMPILER ${WASI_SDK_PATH}/bin/clang)
set(CMAKE_CXX_COMPILER ${WASI_SDK_PATH}/bin/clang++)
set(CMAKE_LINKER ${WASI_SDK_PATH}/bin/wasm-ld CACHE STRING "wasienv build")
set(CMAKE_AR ${WASI_SDK_PATH}/bin/ar CACHE STRING "wasienv build")
set(CMAKE_RANLIB ${WASI_SDK_PATH}/bin/ranlib CACHE STRING "wasienv build")
set(CMAKE_C_COMPILER_LAUNCHER sccache)
set(CMAKE_CXX_COMPILER_LAUNCHER sccache)

set(CMAKE_C_COMPILER_TARGET ${WASI_TARGET})
set(CMAKE_CXX_COMPILER_TARGET ${WASI_TARGET})
set(CMAKE_C_FLAGS "${WASI_SYSROOT} ${WASI_CFLAGS}" CACHE STRING "wasienv build")
set(CMAKE_CXX_FLAGS "${WASI_SYSROOT} ${WASI_CFLAGS}" CACHE STRING "wasienv build")
set(CMAKE_EXE_LINKER_FLAGS "${WASI_LDFLAGS}" CACHE STRING "wasienv build")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
END

# mkdir -p $(pwd)/picosat-prefix
# (cd $PICOSAT_DIR &&
# CC="sccache ${WASI_SDK_PATH}/bin/clang" \
# CFLAGS="-DNGETRUSAGE -DNALLSIGNALS -D_WASI_EMULATED_SIGNAL" \
# ./configure.sh
# )

make -C $PICOSAT_DIR picosat.o version.o
${WASI_SDK_PATH}/bin/ar rc $PICOSAT_DIR/libpicosat.a $PICOSAT_DIR/picosat.o $PICOSAT_DIR/version.o
${WASI_SDK_PATH}/bin/ranlib $PICOSAT_DIR/libpicosat.a 
cp $PICOSAT_DIR/libpicosat.a $PICOSAT_DIR/picosat.h $(pwd)/picosat-prefix

# # mkdir -p lingeling-build
# # (cd lingeling-build)

# (cd $(pwd)/btor2tools/ && git checkout src/btorsim/btorsim.cpp)
# cat >> $(pwd)/btor2tools/src/btorsim/btorsim.cpp <<EOF
# #if defined(__wasm)
# extern "C" {
# 	// FIXME: WASI does not currently support exceptions.
# 	void* __cxa_allocate_exception(size_t thrown_size) throw() {
# 		return malloc(thrown_size);
# 	}
# 	bool __cxa_uncaught_exception() throw();
# 	void __cxa_throw(void* thrown_exception, struct std::type_info * tinfo, void (*dest)(void*)) {
# 		std::terminate();
# 	}
# }
# #endif
# EOF

# (cd $(pwd)/btor2tools/ && git checkout src/btorsplit.cpp)
# cat >> $(pwd)/btor2tools/src/btorsplit.cpp <<EOF
# #if defined(__wasm)
# extern "C" {
# 	// FIXME: WASI does not currently support exceptions.
# 	void* __cxa_allocate_exception(size_t thrown_size) throw() {
# 		return malloc(thrown_size);
# 	}
# 	bool __cxa_uncaught_exception() throw();
# 	void __cxa_throw(void* thrown_exception, struct std::type_info * tinfo, void (*dest)(void*)) {
# 		std::terminate();
# 	}
# }
# #endif
# EOF

# cmake -B btor2tools-build -S btor2tools \
#   -DCMAKE_TOOLCHAIN_FILE=../Toolchain-WASI.cmake \
#   -DBUILD_SHARED_LIBS=OFF \
#   -DCMAKE_INSTALL_PREFIX=$(pwd)/btor2tools-prefix
# make -C btor2tools-build install
# cmake --build prjtrellis-build

cmake -B boolector-build -S boolector \
    -DCMAKE_TOOLCHAIN_FILE=../Toolchain-WASI.cmake \
    -DCMAKE_INCLUDE_PATH="$(pwd)/btor2tools-prefix/include;$(pwd)/picosat-prefix" \
    -DCMAKE_LIBRARY_PATH="$(pwd)/btor2tools-prefix/lib;$(pwd)/picosat-prefix"
cmake --build boolector-build

exit 0




# if ! [ -f ${BOOST}/tools/build/src/engine/b2 ]; then
#   (cd ${BOOST}/tools/build/src/engine && ./build.sh);
# fi
# cat >${BOOST}/project-config.jam <<END
# using clang : : ccache clang++ --target=${WASI_TARGET} ${WASI_SYSROOT} ${WASI_CFLAGS} -D_WASI_EMULATED_MMAN -DBOOST_NO_EXCEPTIONS ${BOOST_ADD_CXXFLAGS} ;
# project : default-build <toolset>clang ;

# libraries = --with-program_options --with-iostreams --with-filesystem --with-system ${BOOST_ADD_LIBRARIES} ;
# END
# (cd ${BOOST} && PATH=${WASI_SDK_PATH}/bin:$PATH ./tools/build/src/engine/b2 threading=${BOOST_THREADING} link=static)

# cmake -B eigen-build -S ${EIGEN} -DCMAKE_INSTALL_PREFIX=$(pwd)/eigen-prefix
# make -C eigen-build install

make -C icestorm-src EXE=".wasm" \
  CXX="ccache ${WASI_SDK_PATH}/bin/clang++" \
  CXXFLAGS="--target=${WASI_TARGET} ${WASI_SYSROOT} ${WASI_CFLAGS} -fno-exceptions" \
  LDFLAGS="--target=${WASI_TARGET} ${WASI_SYSROOT} ${WASI_LDFLAGS}" \
  SUBDIRS="icebox icepack icemulti icepll icebram" \
  PREFIX="" DESTDIR=$(pwd)/icestorm-prefix \
  install
cp icestorm-src/icefuzz/timings_*.txt $(pwd)/icestorm-prefix/share/icebox/

cmake -B prjtrellis-build -S prjtrellis-src/libtrellis \
  -DCMAKE_TOOLCHAIN_FILE=../Toolchain-WASI.cmake \
  -DBOOST_ROOT=$(pwd)/${BOOST} \
  -DSTATIC_BUILD=ON \
  -DBUILD_SHARED=OFF \
  -DBUILD_PYTHON=OFF
cmake --build prjtrellis-build

cmake -B libtrellis-build -S prjtrellis-src/libtrellis \
  -DCMAKE_INSTALL_PREFIX=$(pwd)/libtrellis-prefix \
  -DPYTHON_EXECUTABLE=${PYTHON} \
  -DBUILD_ECPBRAM=OFF \
  -DBUILD_ECPPACK=OFF \
  -DBUILD_ECPUNPACK=OFF \
  -DBUILD_ECPPLL=OFF \
  -DBUILD_ECPMULTI=OFF
make -C libtrellis-build install

# Rustc doesn't yet implement wasm32-wasi-threads; see:
# https://github.com/rust-lang/compiler-team/issues/574
cargo build --target-dir prjoxide-build \
  --manifest-path prjoxide-src/libprjoxide/prjoxide/Cargo.toml \
  --target wasm32-wasi \
  --release

cargo install --target-dir prjoxide-build \
  --path prjoxide-src/libprjoxide/prjoxide \
  --root prjoxide-prefix

cmake -B nextpnr-bba-build -S nextpnr-src/bba
cmake --build nextpnr-bba-build

${PYTHON} -m venv apycula-prefix
./apycula-prefix/bin/pip install -r apycula-meta/requirements.txt

mkdir -p nextpnr-build
cmake -B nextpnr-build -S nextpnr-src \
  -DCMAKE_TOOLCHAIN_FILE=../Toolchain-WASI.cmake \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DPYTHON_EXECUTABLE=${PYTHON} \
  -DSTATIC_BUILD=ON \
  -DBOOST_ROOT=$(pwd)/${BOOST} \
  -DEigen3_DIR=$(pwd)/eigen-prefix/share/eigen3/cmake \
  -DBBA_IMPORT=$(pwd)/nextpnr-bba-build/bba-export.cmake \
  -DBUILD_GUI=OFF \
  -DBUILD_PYTHON=OFF \
  -DEXTERNAL_CHIPDB=ON \
  -DEXTERNAL_CHIPDB_ROOT=/share \
  -DARCH="ice40;ecp5;machxo2;nexus;gowin" \
  -DICESTORM_INSTALL_PREFIX=$(pwd)/icestorm-prefix \
  -DTRELLIS_INSTALL_PREFIX=$(pwd)/libtrellis-prefix \
  -DOXIDE_INSTALL_PREFIX=$(pwd)/prjoxide-prefix \
  -DGOWIN_BBA_EXECUTABLE=$(pwd)/apycula-prefix/bin/gowin_bba
cmake --build nextpnr-build
