# Building xDuke 19.7.1 with 32-bit MinGW GCC

This adds a separate GCC/MinGW32 build path. The original Visual Studio
solution and project files are retained unchanged.

The port is limited to compiler and build compatibility. It does not change
game simulation, movement, physics, timing, weapons, input, networking protocol,
or demo recording/playback logic.

## Requirements

- A **32-bit Windows MinGW GCC/G++ toolchain** and GNU Make.
  - The default compiler prefix is `i686-w64-mingw32-`.
  - If the compiler programs are named `gcc`, `g++`, `ar`, and `ranlib` in
a native MinGW32 environment, pass `CROSS_COMPILE=`.
- SDL **1.2.15** 32-bit MinGW headers, import/static libraries, and runtime DLL
  are bundled in `deps/SDL-1.2.15/`.
- SDL_mixer **1.2.12** 32-bit MinGW headers, import/static libraries, and
  primary runtime DLL are bundled in `deps/SDL_mixer-1.2.12/`.
- For a standalone runtime distribution, also provide the non-Windows DLL
  dependencies listed below; these are not all included in the SDL_mixer
  development package itself.
- ENet is already included in `Engine/src/enet`.

SDL 2.x is not a replacement for SDL 1.2 in this source tree. Do not mix
32-bit objects with 64-bit SDL libraries, or MSVC `.lib` files with MinGW.

Use a MinGW/MSYS-style shell when running the Makefile because its recipes use
standard Unix utilities (`mkdir`, `rm`, and `grep`).

## Build

From the xDuke source root (the archive includes a default `Makefile`):

```sh
make
```

You can also invoke the dedicated file explicitly:

```sh
make -f Makefile.mingw
```

For a different cross toolchain whose archiver utilities are target-prefixed,
override their names explicitly, for example:

```sh
make AR=i686-w64-mingw32-ar RANLIB=i686-w64-mingw32-ranlib
```

The Makefile checks that both `ar` and `ranlib` are available before compiling.

The output is:

```text
bin/duke3d_w32.exe
```

To remove generated objects and the executable:

```sh
make -f Makefile.mingw clean
```

## SDL dependency discovery

The Makefile first tries `pkg-config` packages named `sdl` and `SDL_mixer`.
If those packages are available, their compiler and linker flags are used.
Otherwise, the Makefile uses the project-local dependency directories:

```text
deps/SDL-1.2.15/
deps/SDL_mixer-1.2.12/
```

The bundled SDL package contains `include/SDL/SDL.h`, `lib/libSDL.dll.a`,
`lib/libSDL.a`, `lib/libSDLmain.a`, and `bin/SDL.dll`. A copy of `SDL.dll` is
also placed in the project's `bin/` directory beside the eventual executable.
The original MSYS2 package archive and its SHA-256 are retained in
`deps/packages/` for provenance.

The SDL_mixer 1.2.12 package payload is bundled in
`deps/SDL_mixer-1.2.12/`: `include/SDL/SDL_mixer.h`, both MinGW libraries,
`lib/pkgconfig/SDL_mixer.pc`, the license, and
`bin/libSDL_mixer-1-2-0.dll`. A copy of the primary mixer DLL is also in the
project's `bin/` directory. The original MSYS2 package archive and its SHA-256
are retained in `deps/packages/` for provenance.

The mixer DLL is PE32/i386. Its direct imports include `SDL.dll`,
`libmad-0.dll`, and `libgcc_s_dw2-1.dll` (plus Windows system DLLs). SDL.dll
is bundled. `libmad-0.dll` and the MinGW GCC runtime DLL are not part of the
SDL_mixer package payload; they must be available from the matching MinGW32
installation or placed beside the executable for a standalone runtime build.
The mixer package metadata also lists FLAC, Vorbis, and libmikmod dependencies;
codec functionality that uses those backends may require their runtime DLLs.

You can override paths and flags on the make command line, for example:

```sh
make -f Makefile.mingw \
  CROSS_COMPILE= \
  SDL_CFLAGS="-IC:/MinGW32/include/SDL" \
  SDL_LIBS="-LC:/MinGW32/lib -lSDLmain -lSDL" \
  SDL_MIXER_CFLAGS="-IC:/MinGW32/include/SDL" \
  SDL_MIXER_LIBS="-LC:/MinGW32/lib -lSDL_mixer"
```

The example link flags are illustrative: use the libraries and any additional
system/dependency libraries supplied by your SDL_mixer build. If you use DLL
import libraries, deploy their required runtime DLLs beside the executable.

## Compatibility notes

- The Visual Studio project specifies 32-bit Win32. This Makefile rejects a
  compiler whose target is not 32-bit MinGW/Windows. The engine also relies on
  32-bit pointer/`long` assumptions, so this is deliberately not a 64-bit port.
- The Build Engine C renderer is used. `USE_I386_ASM` is not defined.
- `-funsigned-char` mirrors the Visual Studio projects' `DefaultCharIsUnsigned`
  setting. `-fwrapv`, `-fno-strict-aliasing`, and `-fcommon` are conservative
  compatibility settings for this legacy code.
- The Visual Studio project refers to `Engine.c`, but the actual source file is
  `Engine/src/engine.c`; the Makefile uses the real filename.
- `Game/src/dukewin.h` only supplies its `__int64` typedef when the compiler
  has not already defined that spelling. MinGW defines it through its CRT
  headers, so an unconditional typedef would expand to the invalid
  `long long long`.
- `Engine/src/win32_compat.h` likewise avoids redefining MinGW's existing
  `__int64` compatibility macro.
- The ENet header directory is added with GCC `-iquote`, not `-I`. ENet ships
its own private `time.h`; using `-I` would incorrectly shadow the C runtime
`<time.h>` and hide `CLOCKS_PER_SEC` from game sources. The one legacy
angle-bracket include of `enet.h` in `Engine/src/mmulti.c` is therefore written
as a quoted include so it is found through the quote-only search path.

The Makefile deliberately does not add `Game/src/audiolib` as a global
  include directory. That directory contains a legacy `assert.h`; putting it
  ahead of the system include directories makes ordinary `<assert.h>` includes
  resolve to the wrong file and triggers its deliberate duplicate-include
  error. Audio source files find their adjacent headers locally.
- The POSIX permission-name fallbacks in `Game/src/dukewin.h` are now guarded
  so they do not redefine names already supplied by MinGW's CRT.
- `Game/src/types.h` uses `unsigned char` for `boolean` on MinGW, matching the
  Windows RPC headers' existing typedef. This preserves the build's existing
  unsigned-char behavior; the original typedef is retained for non-MinGW
  builds. Integer-limit macros are guarded to avoid replacing equivalent
  definitions supplied by the Windows SDK.
- `Game/src/funct.h` no longer advertises `loadpheader` as an external
  function. The only definition and both call sites are inside
  `Game/src/menues.c`, where the function is already `static`; removing
  the stale shared-header declaration resolves GCC's conflicting-linkage
  error without changing the function or its behavior.
- `Game/src/funct.h` also no longer advertises `setanimation` as an
  external function. Its definition and every call site are confined to
  `Game/src/sector.c`, where it is already `static`; removing the stale
  declaration resolves the same GCC conflicting-linkage error without
  changing the function or its behavior.
- `Game/src/audiolib/_multivc.h` no longer declares `MV_Mix` with a stale
  two-argument signature. The only implementation in `multivoc.c` and its
  function-pointer type both take one `VoiceNode *`; the unused static
  declaration was removed from the shared header. The mixer routine and
  its call sites were not changed.
- All source changes are compiler/header compatibility only. No simulation
  or game logic was changed.

## Verification status

The source lists were checked against the original Visual Studio project files,
and the Makefile's command graph was dry-run. The reported MinGW header/include-
path failures have been addressed. The `types.h` compatibility change also
passed a focused GCC C89 header test with the same `boolean` typedef and Windows
SDK limit-macro collision simulated. Both bundled SDL and SDL_mixer DLLs were
inspected and are PE32/i386. The SDL_mixer package archive and SHA-256 are
retained in `deps/packages/` for provenance.

The latest user-supplied build log reached `multivoc.c`; the `MV_Mix`
declaration mismatch shown there has been corrected by removing the stale
prototype. This archive has not yet been compiled with the user's MinGW32
toolchain.

A Windows executable has **not** been produced or runtime-tested because this
environment does not contain the i686 MinGW compiler. The mixer DLL directly
imports `libmad-0.dll` and `libgcc_s_dw2-1.dll`, which are not in the SDL_mixer
package payload; ensure they are supplied by the user's MinGW32 runtime or
placed beside the executable. Other codec DLLs may be needed for their
respective audio formats. A successful Windows compile/link and runtime test
are still required.

## Revision 10 note

- Added an include guard to `Game/src/funct.h` and a file-scope forward
  declaration for `struct player_struct`. `cvar_defs.c` includes `funct.h`
  before `duke3d.h`; without the forward declaration, GCC treated the struct
  tags in the prototypes as prototype-scope declarations and then diagnosed
  repeated declarations as conflicting. This is a declaration/include-order
  portability fix only; no function signatures or implementations changed.


## Revision 11 note

- In `Engine/src/a.c`, replaced the MSVC-style compound assignment to a cast
  expression in `prevlineasm1` with an explicit unsigned-long right shift
  assigned back to `i4`. Standard C does not permit a cast expression as the
  left operand of `>>=`. On the required 32-bit MinGW target, `unsigned long`
  is 32 bits, so the operation preserves the intended 32-bit logical-shift
  behavior. This affects only the portable software renderer implementation;
  it does not alter game simulation or networking/demo behavior.
