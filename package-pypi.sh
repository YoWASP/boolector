#!/bin/sh -ex

PYTHON=${PYTHON:-python}

cp -r boolector-build/bin/boolector.wasm pypi/src/yowasp_boolector

cd pypi
rm -rf build && ${PYTHON} -m build -w
sha256sum dist/*.whl
