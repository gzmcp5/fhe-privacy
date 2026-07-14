# OpenFHE wheel build

OpenFHE 1.5.1 and OpenFHE-Python 1.5.1.0 are built as separate CPython 3.13 wheels for:

- Ubuntu 24.04, x86-64;
- macOS 14 or later, Apple Silicon arm64;
- Windows x86-64 hosts using Ubuntu 26.04 under WSL 2.

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

Windows uses the PowerShell entrypoint because OpenShell's supported Windows host path is WSL 2.
The OpenFHE artifact is therefore a CPython 3.13 Linux wheel for that WSL distribution, not a native
Win32 wheel:

```powershell
.\tools\bootstrap-dev-runtime.ps1 -Distro Ubuntu-26.04
```

The WSL distribution needs `build-essential`, `cmake`, `git`, `curl`, `ca-certificates`, `patchelf`
and `ninja-build`; `python3.13` must be on its `PATH`. The build stays in the WSL filesystem and only
the ignored result is copied to `vendor/wheels/`.

`versions.lock` records the exact upstream commits, expected platform wheel names and the checksum
of each validated wheel. The macOS arm64 entry remains `UNVALIDATED` until the workflow or the
commands above run successfully on macOS and the resulting wheel checksum is recorded. Do not copy
the Linux wheel to macOS: native wheels must be built and verified independently for each target.
