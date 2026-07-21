# Calling Custom Fortran Code from MATLAB
### A Step-by-Step Guide for Apple Silicon (ARM64) Macs

### Author: Kyle Monette, [kylemonette.github.io](https://kylemonette.github.io)


#### Updated: July 21, 2026

## Disclaimer:

These instructions have not been audited carefully for mistakes, errors, or inefficiencies, and the majority of the content was generated with the help of Claude.
This repository is provided as-is, with no warranty of correctness or fitness for any particular purpose. I take no responsibility for any unintended consequences of using these files. Most likely, I will not troubleshoot issues that come up, though I may look into ones that meaningfully improve the quality of the material.

## Why This Guide Exists

MATLAB on Apple Silicon (M1/M2/M3/M4) Macs no longer supports the legacy commercial Fortran compilers that older Intel-based MATLAB installations relied on. The only Fortran compiler MATLAB's own toolchain documentation points to on ARM64 is the commercial NAG compiler. If you don't have a NAG license, you can still compile and call your own Fortran routines using the free, open-source `gfortran` compiler — you just need one extra bridging step. This document walks through that process end to end, using a minimal worked example, and assumes only that you have a Mac with [Homebrew](https://brew.sh) installed but have never done this before.

### The Big Picture

The workflow has three pieces:

1. **Compile your Fortran code into a native ARM64 shared library** (a `.dylib` file) using `gfortran` in the Terminal.
2. **Write a small C "gateway" file** that MATLAB's `mex` compiler can build. This gateway takes MATLAB's input arrays, hands raw pointers to your Fortran routine, and hands the result back.
3. **Compile the gateway with `mex` inside MATLAB**, linking it against your Fortran `.dylib`. The result is a callable MATLAB function.

> **Note:** Fortran and C/MATLAB disagree on two things that matter here: (1) Fortran passes everything *by reference* (as a pointer), never by value, and (2) the Fortran compiler appends a trailing underscore to subroutine names in the compiled object file (e.g. `compute_product` becomes the symbol `compute_product_`). The C gateway file exists specifically to paper over both of these differences.

---

## 0. One-Time Terminal Setup

Skip any of these steps you've already completed.

**Step 0.1 — Confirm Homebrew targets Apple Silicon**

Homebrew on Apple Silicon must live under `/opt/homebrew` (the Intel location, `/usr/local`, will not work for native ARM64 tools). If you don't have Homebrew yet, install it with:

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

> **Note:** macOS Terminal windows launch as *login shells*, which is why `.bash_profile` is the right target on bash rather than `.bashrc` (which only loads for non-login interactive shells). On zsh, `.zshrc` is loaded for both cases, so there's no such distinction to worry about.

**Step 0.2 — Install gfortran**

```bash
brew install gcc
```

This installs the GNU compiler collection, which includes `gfortran`.

**Step 0.3 — Verify the install**

```bash
which gfortran
```

This **must** print `/opt/homebrew/bin/gfortran`. If it prints something under `/usr/local` instead, Homebrew is not correctly configured for Apple Silicon and the library you build in Step 2 will not match MATLAB's native ARM64 architecture.

---

## 1. Worked Example: Multiplying Two Numbers

We'll build the simplest possible example first: a Fortran subroutine that multiplies two scalar numbers together. Once this works, the same recipe scales up to real numerical routines (see [Extending to Matrices](#2-extending-to-matrices--example)).

Create a new, empty folder to work in and place every file from this section inside it.

### Step 1: The Fortran Source File

Open the file [mysub.f90](/mysub.f90).

The `iso_c_binding` module and the `real(c_double)` type are what guarantee this data will line up byte-for-byte with a C `double` — and, in turn, with MATLAB's default `double` type.

**In the Terminal**, from inside the folder containing `mysub.f90`:

```bash
gfortran -c -fPIC mysub.f90 -o mysub.o
gfortran -shared -o libmysub.dylib mysub.o
```

- `-c` compiles to an object file without linking.
- `-fPIC` produces position-independent code, required for anything going into a shared library.
- `-shared` links the object file into a `.dylib` (macOS's shared library format, analogous to a `.so` on Linux or `.dll` on Windows).

Confirm the library is a native ARM64 binary:

```bash
file libmysub.dylib
```

The output must contain the word `arm64`. If it says `x86_64` instead, gfortran is not the Apple Silicon build from Homebrew, and MATLAB will refuse to link against it later.

### Step 2: The C Gateway File

Save the file [fortran_gateway.c](/fortran_gateway.c) in the *same* folder.

A few things worth understanding line by line:

- `extern void compute_product_(...)` declares the Fortran symbol *as the linker will actually see it* — lowercase, with the trailing underscore gfortran adds automatically.
- `mxGetPr` extracts a raw `double*` pointer to MATLAB's underlying array data — no copying occurs.
- Because Fortran expects arguments by reference, we simply forward the pointers we already have; no dereferencing is needed on the C side.

### Step 3: Compile and Run, Inside MATLAB

Save the file [demo_fortran_library.m](/demo_fortran_library.m) in the same folder, then open MATLAB, `cd` into that folder, and run it.


> **Note:** The `install_name_tool` call rewrites the `.dylib`'s internal identity so that MATLAB's MEX binary can find it at `@loader_path` (i.e. "wherever the calling binary lives") rather than at the absolute path where it was originally compiled. Without this, the compiled `fortran_gateway` MEX file may fail to locate `libmysub.dylib` once moved or shared to another machine.

If everything is set up correctly, you should see:

```bash
=== Starting Fortran-MATLAB Integration Demo ===

Applying macOS library path fix...
Compiling C Gateway (fortran_gateway.c) with MATLAB MEX...
Success: MEX binary "fortran_gateway" created.

Calling Fortran routine with inputs: 4.5 and 2...

=== Results ===
MATLAB received output value: 9
```

---

## 2. Extending to Matrices — Example

The scalar example above generalizes directly to arrays and matrices.


### Step 1: Fortran Source

Download the file [matrix_mult.f90](/matrix_mult.f90).


Compile it the same way as before:

```bash
gfortran -c -fPIC matrix_mult.f90 -o matrix_mult.o
gfortran -shared -o libmatrixmult.dylib matrix_mult.o
```

### Step 2: C Gateway

Download the gateway file [matrix_gateway.c](/matrix_gateway.c).



### Step 3: MATLAB Driver Script

Download and run the MATLAB driver script file in [demo_matrix_library.m](/demo_matrix_library.m).

---

## Troubleshooting Checklist

- **`which gfortran` doesn't print `/opt/homebrew/bin/gfortran`:** Homebrew installed to the wrong prefix, or your shell profile doesn't source `brew shellenv`. Re-run the Step 0.1 commands.
- **`file lib*.dylib` doesn't say `arm64`:** You're linking against an x86_64 (Rosetta) copy of gfortran. Uninstall it and reinstall Homebrew/gcc natively as in Step 0.
- **MATLAB error about an undefined symbol at link time (e.g. `compute_product`):** Double check the trailing underscore in the C gateway's `extern` declaration — it must match what `gfortran` actually emits.
- **MEX file builds but errors at runtime saying the `.dylib` can't be found:** Re-run the `install_name_tool -id "@loader_path/..."` command from the same folder as the `.dylib` *before* calling `mex`.
- **Wrong number/type of output values:** Remember MATLAB always passes doubles by default; if your Fortran routine uses a different `iso_c_binding` kind (e.g. `c_float` or `c_int`), the C gateway and MATLAB-side calls must be updated to match.
- **Linker warning about mismatched macOS deployment versions** (e.g. `ld: warning: building for macOS-13.3, but linking with dylib ... which was built for newer version 26.0`): Harmless as long as your Fortran routine doesn't use macOS-version-specific APIs. It happens because `gfortran` targets whichever SDK is installed on your Mac by default, while MATLAB's `mex` links against an older minimum version for backward compatibility. To silence it, add `-mmacosx-version-min=13.3` (or match whatever version MEX reports) to both `gfortran` compile commands.
