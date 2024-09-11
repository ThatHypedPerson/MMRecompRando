BUILD_DIR := build
OUTPUT_NAME := mm_recomp_rando
MOD_TOML := mod.toml

CC      := clang
LD      := ld.lld
MOD_TOOL := ./RecompModTool
OFFLINE_RECOMP := ./OfflineModRecomp
TARGET  := $(BUILD_DIR)/mod.elf
MANIFEST := $(wildcard $(OUTPUT_NAME)/$(OUTPUT_NAME)*.nrm)
OUTPUT_NAME_W_VER := $(notdir $(MANIFEST:.nrm=))

LDSCRIPT := mod.ld
CFLAGS   := -target mips -mips2 -mabi=32 -O2 -G0 -mno-abicalls -mno-odd-spreg -mno-check-zero-division \
			-fomit-frame-pointer -ffast-math -fno-unsafe-math-optimizations -fno-builtin-memset \
			-Wall -Wextra -Wno-incompatible-library-redeclaration -Wno-unused-parameter -Wno-unknown-pragmas -Wno-unused-variable \
			-Wno-missing-braces -Wno-unsupported-floating-point-opt -Werror=section
CPPFLAGS := -nostdinc -D_LANGUAGE_C -DMIPS -I include -I include/dummy_headers -I mm-decomp/include -I mm-decomp/src -I mm-decomp/assets
LDFLAGS  := -nostdlib -T $(LDSCRIPT) -Map $(BUILD_DIR)/mod.map --unresolved-symbols=ignore-all --emit-relocs -e 0 --no-nmagic

C_SRCS := $(wildcard src/*.c)
C_OBJS := $(addprefix $(BUILD_DIR)/, $(C_SRCS:.c=.o))
C_DEPS := $(addprefix $(BUILD_DIR)/, $(C_SRCS:.c=.d))


ifeq ($(OS),Windows_NT)

define make_folder
	mkdir $(subst /,\,$(1))
endef

$(OUTPUT_NAME)/$(OUTPUT_NAME_W_VER).dll: build/mod_recompiled.c
ifeq ($(MANIFEST),)
	@$(MAKE) --no-print-directory
else
	clang-cl build/mod_recompiled.c -fuse-ld=lld -Z7 /Ioffline_build   /MD /O2 /link /DLL /OUT:$@
endif

else

define make_folder
	mkdir -p $(1)
endef

$(OUTPUT_NAME)/$(OUTPUT_NAME_W_VER).so: build/mod_recompiled.c
ifeq ($(MANIFEST),)
	@$(MAKE) --no-print-directory
else
	clang build/mod_recompiled.c -shared -fvisibility=hidden -fPIC -O2 -Ioffline_build -o $@
endif

endif


build/mod_recompiled.c: $(OUTPUT_NAME)/mod_binary.bin
	$(OFFLINE_RECOMP) $(OUTPUT_NAME)/mod_syms.bin $(OUTPUT_NAME)/mod_binary.bin Zelda64RecompSyms/mm.us.rev1.syms.toml $@

$(OUTPUT_NAME)/mod_binary.bin: $(TARGET) $(MOD_TOML) | $(OUTPUT_NAME)
	$(MOD_TOOL) $(MOD_TOML) $(OUTPUT_NAME)

$(OUTPUT_NAME):
	$(call make_folder, $@)

$(TARGET): $(C_OBJS) $(LDSCRIPT)  | $(BUILD_DIR)
	$(LD) $(C_OBJS) $(LDFLAGS) -o $@

$(BUILD_DIR) $(BUILD_DIR)/src:
	$(call make_folder, $@)

$(C_OBJS): $(BUILD_DIR)/%.o : %.c | $(BUILD_DIR) $(BUILD_DIR)/src
	$(CC) $(CFLAGS) $(CPPFLAGS) $< -MMD -MF $(@:.o=.d) -c -o $@

clean:
	rm -rf $(BUILD_DIR) $(OUTPUT_NAME)

-include $(C_DEPS)

.PHONY: clean
