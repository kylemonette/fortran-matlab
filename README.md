# Calling Custom Fortran Code from MATLAB

### Author: Kyle Monette, [kylemonette.github.io](https://kylemonette.github.io)

#### Updated: July 22, 2026

## Disclaimer

This repository is provided as-is, with no warranty of correctness or fitness for any particular purpose. I take no responsibility for any unintended consequences of using these files.

## Why This Guide Exists

MATLAB's officially documented Fortran toolchain support is limited. On Apple Silicon Macs in particular, the only compiler MATLAB's own docs point to is the commercial NAG compiler. If you don't have a commercial license, you can still compile and call custom Fortran routines using the free, open-source `gfortran` compiler — you just need one extra bridging step. This repo walks through that process end to end with two minimal worked examples.

### The Big Picture

The workflow has three pieces, and in this repo **all three happen inside MATLAB**.

1. **Compile your Fortran code into a native shared library** (a `.dylib` on macOS, a `.so` on Linux) using `gfortran`.
2. **Write a small C "gateway" file** that MATLAB's `mex` compiler can build. This gateway takes MATLAB's input arrays, hands raw pointers to your Fortran routine, and hands the result back.
3. **Compile the gateway with `mex`**, linking it against your Fortran shared library. The result is a callable MATLAB function.

Each worked example has a `build_*.m` script that does all three steps for you — you just call it once from MATLAB and it handles the rest.

> **Note:** Fortran and C/MATLAB disagree on two things that matter here: (1) Fortran passes everything *by reference* (as a pointer), never by value, and (2) the Fortran compiler appends a trailing underscore to subroutine names in the compiled object file (e.g. `compute_product` becomes the symbol `compute_product_`). The C gateway file exists specifically to paper over both of these differences.

## Locating the Compiler

MATLAB's `system()` calls run in a stripped-down subshell that does not always inherit your full shell `PATH`.

Every build script here resolves this the same way, through [`findGfortran.m`](./findGfortran.m):

1. Try `which gfortran` first.
2. Fall back to the usual install locations: `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`.
3. Fall back further to versioned binaries in those same folders (`gfortran-14`, `gfortran-13`, ...), picking the highest version found.
4. If none of that finds anything, it raises an error telling you how to install gfortran on your platform, and where in the file to add a path if your install lives somewhere else.

If your gfortran install is in a nonstandard location, the only file you should ever need to edit is `findGfortran.m` — add your path to the `candidates` cell array near the top. You never need to edit anything inside the `build_*.m` scripts, or your shell profile.

## Requirements

- Homebrew: Homebrew on Apple Silicon must live under `/opt/homebrew` (the Intel location, `/usr/local`, will not work for native ARM64 tools). If you don't have Homebrew yet, install it with:

  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

  Then make sure your shell can find it. macOS has used `zsh` as the default login shell since Catalina (2019), but you may be on `bash` — either because you're on an older macOS version or because you changed it yourself. Check first:

  ```bash
  echo $SHELL
  ```

  If this prints `/bin/zsh` (or `/opt/homebrew/bin/zsh`), use:

  ```bash
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zshrc
  source ~/.zshrc
  ```

  If it instead prints `/bin/bash`, use `~/.bash_profile` in place of `~/.zshrc`:

  ```bash
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
  source ~/.bash_profile
  ```

- MATLAB with a configured C compiler for MEX (run `mex -setup C` once if you've never used MEX before).
- `gfortran`:
  - **macOS**: `brew install gcc` (this installs the GNU compiler collection, which includes `gfortran`). Requires [Homebrew](https://brew.sh).
  - **Ubuntu/Debian**: `sudo apt install gfortran`
  - **Fedora/RHEL**: `sudo dnf install gcc-gfortran`
- Windows is not supported directly by these scripts (gfortran + MEX is a substantially rockier setup there). Use WSL2 and follow the Linux instructions above.


## 1. Worked Example: Multiplying Two Numbers

Open [`mysub.f90`](./mysub.f90) — a Fortran subroutine that multiplies two scalar numbers together. The `iso_c_binding` module and the `real(c_double)` type are what guarantee this data lines up byte-for-byte with a C `double`, and in turn with MATLAB's default `double` type.

Its C gateway, [`fortran_gateway.c`](./fortran_gateway.c):
- declares `extern void compute_product_(...)` — the Fortran symbol *as the linker will actually see it*: lowercase, with the trailing underscore gfortran adds automatically.
- uses `mxGetPr` to extract a raw `double*` pointer to MATLAB's underlying array data — no copying occurs.
- forwards the pointers it already has directly to the Fortran routine, since Fortran expects arguments by reference — no dereferencing needed on the C side.

**To run it**: open MATLAB, `cd` into this folder, and run [`demo_fortran_library.m`](./demo_fortran_library.m). That script calls `build_mysub(true)` (which compiles everything and prints its progress) and then calls the resulting `fortran_gateway` function directly. You should see something like:

```
Starting Fortran-MATLAB Integration Demo

Building mysub MEX Gateway

Using gfortran at: /opt/homebrew/bin/gfortran

Compiling mysub.f90...
Object file created.

Linking libmysub.dylib...
libmysub.dylib created.

Applying macOS library path fix...
Done.

Compiling gateway fortran_gateway.c...
fortran_gateway.c created.

Calling Fortran routine with inputs: 4.5 and 2...

Results:
MATLAB received output value: 9
```

Run it again and the build step becomes a one-line "up to date" message — `build_mysub.m` only recompiles when `mysub.f90` or `fortran_gateway.c` has actually changed.

## 2. Extending to Matrices

[`matrix_mult.f90`](./matrix_mult.f90) generalizes the same idea to a fixed-size 2×2 matrix multiplication, with its own gateway ([`matrix_gateway.c`](./matrix_gateway.c)) and build script ([`build_matrixmult.m`](./build_matrixmult.m)).

**To run it**: run [`demo_matrix_library.m`](./demo_matrix_library.m) the same way — it builds `matrix_gateway`, calls it on two sample 2×2 matrices, and checks the result against MATLAB's own `A * B`.

## Adapting this to your own Fortran routine

1. Write your subroutine using `iso_c_binding` types (`real(c_double)`, `integer(c_int)`, etc.) so its memory layout matches MATLAB's.
2. Write a gateway `.c` file modeled on `fortran_gateway.c` or `matrix_gateway.c`: declare your subroutine as `extern` with a trailing underscore, validate `nrhs`/`nlhs`, and pass `mxGetPr(...)` pointers straight through.
3. Copy `build_mysub.m`, rename it, and update the three filenames near the top (`fortranFile`, `gatewayFile`, `libFile`'s base name) plus the final `mex(...)` call's `-l` flag.
4. Call your new `build_*.m` from a demo script, then call the compiled gateway like any other MATLAB function.

## Cross-platform notes

- **macOS**: uses `install_name_tool` to fix the compiled library's install path so the MEX file can find it (`@loader_path`) regardless of your current directory.
- **Linux**: embeds `-Wl,-rpath,'$ORIGIN'` in the link step instead of `install_name_tool`, so the `.so` is found next to the MEX file without needing `LD_LIBRARY_PATH` set.

This logic lives in one place, [`libPlatformInfo.m`](./libPlatformInfo.m), so neither build script hardcodes a platform.

## Troubleshooting Checklist

- **"gfortran not found"** — install it (see Requirements), or add its full path to the `candidates` list in `findGfortran.m`.
- **MATLAB error about an undefined symbol at link time** (e.g. `compute_product`) — double check the trailing underscore in the C gateway's `extern` declaration; it must match what `gfortran` actually emits.
- **MEX file builds but errors at runtime saying the shared library can't be found** — delete the `.dylib`/`.so` and `.mex*` files and rerun the `build_*.m` script; `needsRebuild.m` will treat their absence as "needs rebuild" and redo the runtime-path fix.
- **Wrong number/type of output values** — MATLAB always passes doubles by default; if your Fortran routine uses a different `iso_c_binding` kind (e.g. `c_float` or `c_int`), the C gateway and MATLAB-side calls must be updated to match.
- **Linker warning about mismatched macOS deployment versions** (e.g. `ld: warning: building for macOS-13.3, but linking with dylib ... which was built for newer version 26.0`) — harmless as long as your Fortran routine doesn't use macOS-version-specific APIs. It happens because `gfortran` targets whichever SDK is installed on your Mac by default, while MATLAB's `mex` links against an older minimum version for backward compatibility. To silence it, add `-mmacosx-version-min=13.3` (or match whatever version MEX reports) to the compile/link commands inside the relevant `build_*.m`.
- **(Linux) Undefined symbol errors mentioning BLAS/LAPACK routines** — not applicable to either worked example here (neither uses BLAS/LAPACK), but if you extend one to call a real numerical library, you'll need `sudo apt install libblas-dev liblapack-dev` (or your distro's equivalent) and to add `-lblas -llapack` to the link command in your `build_*.m`.
