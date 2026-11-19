# xDuke 19.7.1 - 32-bit MinGW build
# This build file is deliberately separate from the original Visual Studio projects.

CROSS_COMPILE ?= i686-w64-mingw32-
CC      = $(CROSS_COMPILE)gcc
CXX     = $(CROSS_COMPILE)g++
# MSYS2 MINGW32 installs GNU binutils as ar.exe/ranlib.exe (unprefixed),
# while its compiler drivers use the i686-w64-mingw32- prefix.
# Override AR/RANLIB on the make command line for other cross toolchains.
AR      = ar
RANLIB  = ranlib
PKG_CONFIG ?= pkg-config

BUILD_DIR = build-mingw32
TARGET    = bin/13duke.exe
ENGINE_LIB = $(BUILD_DIR)/libengine.a

# SDL 1.2 and SDL_mixer 1.2 must be built for the same 32-bit MinGW toolchain.
# pkg-config is preferred. Fallback paths expect SDL/SDL_mixer to have already
# been built with this MinGW32 toolchain and installed into these directories.
# Do not point these at VisualC/*.lib outputs: MSVC libraries are not linkable
# by MinGW's GNU linker.
SDL_ROOT       ?= deps/SDL-1.2.15
SDL_MIXER_ROOT ?= deps/SDL_mixer-1.2.12

SDL_PKG_CFLAGS       := $(shell $(PKG_CONFIG) --cflags sdl 2>/dev/null)
SDL_PKG_LIBS         := $(shell $(PKG_CONFIG) --libs sdl 2>/dev/null)
SDL_MIXER_PKG_CFLAGS := $(shell $(PKG_CONFIG) --cflags SDL_mixer 2>/dev/null)
SDL_MIXER_PKG_LIBS   := $(shell $(PKG_CONFIG) --libs SDL_mixer 2>/dev/null)

ifeq ($(strip $(SDL_PKG_CFLAGS)),)
SDL_CFLAGS ?= -I"$(SDL_ROOT)/include" -I"$(SDL_ROOT)/include/SDL"
else
SDL_CFLAGS ?= $(SDL_PKG_CFLAGS)
endif
ifeq ($(strip $(SDL_PKG_LIBS)),)
# These must be GNU/MinGW import or static libraries (.a), never the MSVC .lib files.
SDL_LIBS ?= -L"$(SDL_ROOT)/lib" -lmingw32 -lSDLmain -lSDL -luser32 -lgdi32 -limm32 -lversion -lsetupapi -ldxguid
else
SDL_LIBS ?= $(SDL_PKG_LIBS)
endif

ifeq ($(strip $(SDL_MIXER_PKG_CFLAGS)),)
SDL_MIXER_CFLAGS ?= -I"$(SDL_MIXER_ROOT)" -I"$(SDL_MIXER_ROOT)/include" -I"$(SDL_MIXER_ROOT)/include/SDL"
else
SDL_MIXER_CFLAGS ?= $(SDL_MIXER_PKG_CFLAGS)
endif
ifeq ($(strip $(SDL_MIXER_PKG_LIBS)),)
SDL_MIXER_LIBS ?= -L"$(SDL_MIXER_ROOT)/lib" -lSDL_mixer
else
SDL_MIXER_LIBS ?= $(SDL_MIXER_PKG_LIBS)
endif

# These options mirror the old MSVC project as closely as GCC allows:
# -funsigned-char matches Visual C++'s DefaultCharIsUnsigned=true;
# -fwrapv and -fno-strict-aliasing avoid aggressive assumptions in legacy code;
# -fcommon supports the old common-symbol style used by some original sources.
COMMON_CFLAGS   = -O2 -funsigned-char -fwrapv -fno-strict-aliasing -fcommon
COMMON_CXXFLAGS = -O2 -funsigned-char -fwrapv -fno-strict-aliasing -fcommon
CFLAGS   ?= $(COMMON_CFLAGS) -std=gnu89
CXXFLAGS ?= $(COMMON_CXXFLAGS) -std=gnu++98 -fpermissive
LDFLAGS  ?=

# Do not add Game/src/audiolib to the global include path: it contains a
# legacy assert.h which would shadow the MinGW C runtime's <assert.h>.
# Audio sources find their own local headers relative to their source folder.
# ENet headers use a private time.h. Keep their directory in the quote-only
# search path so <time.h> in normal game/Windows code resolves to the C runtime.
INCLUDES = -IEngine/src -iquote Engine/src/enet/include -IGame/src -IGame/src/midi $(SDL_CFLAGS) $(SDL_MIXER_CFLAGS)

ENGINE_CPPFLAGS = -DWIN32 -DPLATFORM_WIN32 -DUDP_NETWORKING -DnDBGRECORD -DnDEBUG \
                  -D_LIB -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE
GAME_CPPFLAGS   = -DWIN32 -DPLATFORM_WIN32 -DnDBGRECORD -DCHECK_XDUKE_REV -DnDEBUG \
                  -D_CONSOLE -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE

# Source lists are taken from the checked-in Visual Studio project files.
# Engine.vcproj calls Engine.c, but the actual source file is engine.c; use the
# real filename so this also works on case-sensitive build hosts.
ENGINE_C_SRCS = \
    Engine/src/a.c \
    Engine/src/cache1d.c \
    Engine/src/engine.c \
    Engine/src/mmulti.c \
    Engine/src/pragmas.c \
    Engine/src/sdl_driver.c \
    Engine/src/enet/host.c \
    Engine/src/enet/list.c \
    Engine/src/enet/memory.c \
    Engine/src/enet/packet.c \
    Engine/src/enet/peer.c \
    Engine/src/enet/protocol.c \
    Engine/src/enet/unix.c \
    Engine/src/enet/win32.c

ENGINE_CXX_SRCS = Engine/src/mmulti_stable.cpp

GAME_C_SRCS = \
    Game/src/actors.c \
    Game/src/animlib.c \
    Game/src/config.c \
    Game/src/control.c \
    Game/src/game.c \
    Game/src/gamedef.c \
    Game/src/global.c \
    Game/src/keyboard.c \
    Game/src/menues.c \
    Game/src/player.c \
    Game/src/premap.c \
    Game/src/rts.c \
    Game/src/scriplib.c \
    Game/src/sector.c \
    Game/src/sounds.c \
    Game/src/audiolib/dsl.c \
    Game/src/audiolib/fx_man.c \
    Game/src/audiolib/ll_man.c \
    Game/src/audiolib/multivoc.c \
    Game/src/audiolib/mv_mix.c \
    Game/src/audiolib/mvreverb.c \
    Game/src/audiolib/nodpmi.c \
    Game/src/audiolib/pitch.c \
    Game/src/audiolib/user.c \
    Game/src/console.c \
    Game/src/cvar_defs.c \
    Game/src/cvars.c

GAME_CXX_SRCS = \
    Game/src/midi/win_midiout.cpp \
    Game/src/midi/xmidi.cpp

engine_obj = $(BUILD_DIR)/engine_$(subst /,_,$(patsubst Engine/src/%,%,$(basename $(1)))).o
game_obj   = $(BUILD_DIR)/game_$(subst /,_,$(patsubst Game/src/%,%,$(basename $(1)))).o

ENGINE_OBJS = $(foreach f,$(ENGINE_C_SRCS),$(call engine_obj,$(f))) \
              $(foreach f,$(ENGINE_CXX_SRCS),$(call engine_obj,$(f)))
GAME_OBJS   = $(foreach f,$(GAME_C_SRCS),$(call game_obj,$(f))) \
              $(foreach f,$(GAME_CXX_SRCS),$(call game_obj,$(f)))

.PHONY: all clean print-config check-toolchain
all: check-toolchain $(TARGET)

$(BUILD_DIR): check-toolchain
	mkdir -p "$@"

bin:
	mkdir -p "$@"

# Generate one rule per source so nested source paths can be flattened into the
# single object directory (also works with mingw32-make on Windows).
define COMPILE_ENGINE_C
$(call engine_obj,$(1)): $(1) | $(BUILD_DIR)
	$$(CC) $$(CPPFLAGS) $$(INCLUDES) $$(ENGINE_CPPFLAGS) $$(CFLAGS) -MMD -MP -MF $$(@:.o=.d) -c $$< -o $$@
endef
$(foreach f,$(ENGINE_C_SRCS),$(eval $(call COMPILE_ENGINE_C,$(f))))

define COMPILE_ENGINE_CXX
$(call engine_obj,$(1)): $(1) | $(BUILD_DIR)
	$$(CXX) $$(CPPFLAGS) $$(INCLUDES) $$(ENGINE_CPPFLAGS) $$(CXXFLAGS) -MMD -MP -MF $$(@:.o=.d) -c $$< -o $$@
endef
$(foreach f,$(ENGINE_CXX_SRCS),$(eval $(call COMPILE_ENGINE_CXX,$(f))))

define COMPILE_GAME_C
$(call game_obj,$(1)): $(1) | $(BUILD_DIR)
	$$(CC) $$(CPPFLAGS) $$(INCLUDES) $$(GAME_CPPFLAGS) $$(CFLAGS) -MMD -MP -MF $$(@:.o=.d) -c $$< -o $$@
endef
$(foreach f,$(GAME_C_SRCS),$(eval $(call COMPILE_GAME_C,$(f))))

define COMPILE_GAME_CXX
$(call game_obj,$(1)): $(1) | $(BUILD_DIR)
	$$(CXX) $$(CPPFLAGS) $$(INCLUDES) $$(GAME_CPPFLAGS) $$(CXXFLAGS) -MMD -MP -MF $$(@:.o=.d) -c $$< -o $$@
endef
$(foreach f,$(GAME_CXX_SRCS),$(eval $(call COMPILE_GAME_CXX,$(f))))

$(ENGINE_LIB): $(ENGINE_OBJS) | $(BUILD_DIR)
	$(AR) rcs "$@" $^
	$(RANLIB) "$@"

$(TARGET): $(GAME_OBJS) $(ENGINE_LIB) | bin
	$(CXX) $(LDFLAGS) -o "$@" $(GAME_OBJS) $(ENGINE_LIB) $(SDL_MIXER_LIBS) $(SDL_LIBS) -lwinmm -lws2_32 -ldxguid

check-toolchain:
	@echo "CC target: $$($(CC) -dumpmachine)"
	@echo "CXX target: $$($(CXX) -dumpmachine)"
	@echo "AR: $(AR)"
	@echo "RANLIB: $(RANLIB)"
	@$(CC) -dumpmachine | grep -Eq '^(i[3-6]86)-.*(mingw|windows)' || { echo "ERROR: CC must target 32-bit MinGW/Windows."; exit 1; }
	@$(CXX) -dumpmachine | grep -Eq '^(i[3-6]86)-.*(mingw|windows)' || { echo "ERROR: CXX must target 32-bit MinGW/Windows."; exit 1; }
	@command -v "$(AR)" >/dev/null 2>&1 || { echo "ERROR: GNU archiver '$(AR)' not found. In MSYS2 MINGW32 run: pacman -S mingw-w64-i686-binutils"; exit 1; }
	@command -v "$(RANLIB)" >/dev/null 2>&1 || { echo "ERROR: GNU ranlib '$(RANLIB)' not found. In MSYS2 MINGW32 run: pacman -S mingw-w64-i686-binutils"; exit 1; }

print-config:
	@echo CC=$(CC)
	@echo CXX=$(CXX)
	@echo AR=$(AR)
	@echo RANLIB=$(RANLIB)
	@echo SDL_CFLAGS=$(SDL_CFLAGS)
	@echo SDL_LIBS=$(SDL_LIBS)
	@echo SDL_MIXER_CFLAGS=$(SDL_MIXER_CFLAGS)
	@echo SDL_MIXER_LIBS=$(SDL_MIXER_LIBS)
	@echo TARGET=$(TARGET)

clean:
	rm -rf "$(BUILD_DIR)" "$(TARGET)"

-include $(ENGINE_OBJS:.o=.d) $(GAME_OBJS:.o=.d)
