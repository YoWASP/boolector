import sys
import yowasp_runtime


def run_boolector(argv):
    return yowasp_runtime.run_wasm(__package__, "boolector.wasm",
                                   argv=["yowasp-boolector", *argv])


def _run_boolector_argv():
    sys.exit(run_boolector(sys.argv[1:]))
