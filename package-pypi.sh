#!/bin/sh -ex

PYTHON=${PYTHON:-python}

cp -r boolector-build/bin/boolector.wasm pypi/src/yowasp_boolector

cd pypi
rm -rf build && pdm build
sha256sum dist/*.whl
