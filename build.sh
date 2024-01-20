#!/bin/sh -ex

export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)

PYTHON=$(which ${PYTHON:-python})

WASI_SDK=wasi-sdk-20.0
WASI_SDK_URL=https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20/wasi-sdk-20.0-linux.tar.gz
if ! [ -d ${WASI_SDK} ]; then curl -L ${WASI_SDK_URL} | tar xzf -; fi
WASI_SDK_PATH=$(pwd)/${WASI_SDK}

PICOSAT_DIR=$(cat picosat-version)
PICOSAT_URL=http://fmv.jku.at/picosat/${PICOSAT_DIR}.tar.gz
if ! [ -d ${PICOSAT_DIR} ]; then curl -L ${PICOSAT_URL} | tar xzf -; fi

WASI_TARGET="wasm32-wasi"
WASI_SYSROOT="--sysroot ${WASI_SDK_PATH}/share/wasi-sysroot"
WASI_CFLAGS="-flto"
WASI_LDFLAGS="-flto -Wl,--strip-all"

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
set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE:-ccache})
set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE:-ccache})

set(CMAKE_C_COMPILER_TARGET ${WASI_TARGET})
set(CMAKE_CXX_COMPILER_TARGET ${WASI_TARGET})
set(CMAKE_C_FLAGS "${WASI_SYSROOT} ${WASI_CFLAGS}" CACHE STRING "wasienv build")
set(CMAKE_CXX_FLAGS "${WASI_SYSROOT} ${WASI_CFLAGS}" CACHE STRING "wasienv build")
set(CMAKE_EXE_LINKER_FLAGS "${WASI_LDFLAGS}" CACHE STRING "wasienv build")
set(CMAKE_EXECUTABLE_SUFFIX_C ".wasm")
set(CMAKE_EXECUTABLE_SUFFIX_CXX ".wasm")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
END

mkdir -p $(pwd)/picosat-prefix
(cd $PICOSAT_DIR && CC="${CCACHE:-ccache} ${WASI_SDK_PATH}/bin/clang" \
    CFLAGS="-DNGETRUSAGE -DNALLSIGNALS" \
    ./configure.sh)

make -C $PICOSAT_DIR picosat.o version.o
${WASI_SDK_PATH}/bin/ar rc $PICOSAT_DIR/libpicosat.a $PICOSAT_DIR/picosat.o $PICOSAT_DIR/version.o
${WASI_SDK_PATH}/bin/ranlib $PICOSAT_DIR/libpicosat.a
cp $PICOSAT_DIR/libpicosat.a $PICOSAT_DIR/picosat.h $(pwd)/picosat-prefix

(cd btor2tools-src && git apply < ../btor2tools.patch || git apply --reverse --check < ../btor2tools.patch)
cmake -B btor2tools-build -S btor2tools-src \
  -DCMAKE_TOOLCHAIN_FILE=../Toolchain-WASI.cmake \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_TOOLS=OFF \
  -DCMAKE_INSTALL_PREFIX=$(pwd)/btor2tools-prefix
make -C btor2tools-build install

(cd boolector-src && git apply < ../boolector.patch || git apply --reverse --check < ../boolector.patch)
cmake -B boolector-build -S boolector-src \
    -DCMAKE_TOOLCHAIN_FILE=../Toolchain-WASI.cmake \
    -DCMAKE_INCLUDE_PATH="$(pwd)/btor2tools-prefix/include;$(pwd)/picosat-prefix" \
    -DCMAKE_LIBRARY_PATH="$(pwd)/btor2tools-prefix/lib;$(pwd)/picosat-prefix"
cmake --build boolector-build -t boolector-bin
