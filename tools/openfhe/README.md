# OpenFHE wheel build

OpenFHE 1.5.1 and OpenFHE-Python 1.5.1.0 are built as separate CPython 3.13 wheels for:

- Ubuntu 24.04, x86-64;
- macOS 14 or later, Apple Silicon arm64.

The upstream Ubuntu wheel is not used because it is tagged `py3-none-any` while containing a
CPython 3.12-only native module. `build-wheel.sh` builds from pinned upstream commits, corrects the
Python ABI and platform tags, and writes the ignored artifact to `vendor/wheels/`.

Linux prerequisites are CMake, a C++17 compiler and Python 3.13. macOS additionally requires the
Homebrew `libomp` package. Run:

```bash
PYTHON=python3.13 ./tools/openfhe/build-wheel.sh
python3.13 -m venv build/openfhe-wheel-test
build/openfhe-wheel-test/bin/pip install vendor/wheels/openfhe-*.whl
build/openfhe-wheel-test/bin/python tools/openfhe/smoke.py
```

The smoke test covers BFV, BGV, CKKS, Boolean FHE and two-party partial decrypt/fusion. It is a
backend compatibility check, not proof that the final product's device-separated 2-of-2 protocol
or secret-lifecycle constraints are complete.

On a fresh clone, agents should normally run `./tools/bootstrap-dev-runtime.sh` instead of invoking
these steps separately. The bootstrap builds a missing platform wheel and executes this smoke test.

`versions.lock` records the exact upstream commits, expected platform wheel names and the checksum
of each validated wheel. The macOS arm64 entry remains `UNVALIDATED` until the workflow or the
commands above run successfully on macOS and the resulting wheel checksum is recorded. Do not copy
the Linux wheel to macOS: native wheels must be built and verified independently for each target.
