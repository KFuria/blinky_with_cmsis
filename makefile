# Makefile for STM32F446

######################################
SRC_DIR = Src
INC_DIR = Inc
CMSIS_DIR = Drivers/CMSIS/
HAL_DIR = Drivers/STM32F4xx_HAL_Driver

BUILD_DIR = build
TARGET = firmware


######################################
# Device setup

FP_FLAGS	?= -mfloat-abi=hard -mfpu=fpv4-sp-d16
ARCH_FLAGS	= -mthumb -mcpu=cortex-m4
DEFS 		+= -DSTM32 -DSTM32F4 -DSTM32F446xx
######################################
# Linkerscript

LD_SCRIPT 	= STM32F446RETX_FLASH.ld

######################################
# Includes

DEPS 	+= -I./
DEPS 	+= -I$(INC_DIR)
DEPS	+= -I$(CMSIS_DIR)/Include
DEPS	+= -I$(CMSIS_DIR)/Device/ST/STM32F4xx/Include
DEPS	+= -I$(HAL_DIR)/Inc

######################################
# Executables and TOOLCHAIN setup

PREFIX	?= arm-none-eabi-

CC			:= $(PREFIX)gcc
CXX			:= $(PREFIX)g++
LD			:= $(PREFIX)gcc
AR			:= $(PREFIX)ar
AS			:= $(PREFIX)as
OBJCOPY		:= $(PREFIX)objcopy
OBJDUMP		:= $(PREFIX)objdump
GDB			:= $(PREFIX)gdb
OS 			:= $(PREFIX)size

OPT 		:= -O0
DEBUG		:= -ggdb3
CSTD		?= -std=c99

######################################
 # Source Files

AS_SRC 		+= Startup/startup_stm32f446retx.s

C_SRC		+= $(SRC_DIR)/main.c
C_SRC		+= $(SRC_DIR)/syscalls.c
C_SRC		+= $(SRC_DIR)/sysmem.c


OBJS 		+= $(addprefix $(BUILD_DIR)/, $(notdir $(AS_SRC:.s=.o)))
vpath %.s $(sort $(dir $(AS_SRC)))
OBJS 		+= $(addprefix $(BUILD_DIR)/, $(notdir $(C_SRC:.c=.o)))  
vpath %.c $(sort $(dir $(C_SRC)))

#####################################
# Assembly Flags

ASFLAGS 	+= $(OPT) $(CSTD) $(DEBUG)
ASFLAGS 	+= $(ARCH_FLAGS)
ASFLAGS		+= --specs=nano.specs -x assembler-with-cpp
ASFLAGS 	+= -Wall -Wextra -Wshadow -Wimplicit-function-declaration
ASFLAGS 	+= -fmessage-length=0 -fno-common -ffunction-sections -fdata-sections


####################################
# C Flags

CFLAGS		+= $(OPT) $(CSTD) $(DEBUG)
CFLAGS		+= $(ARCH_FLAGS)
CFLAGS		+= --specs=nano.specs
CFLAGS		+= -Wall -Wundef -Wextra -Wshadow -Wimplicit-function-declaration
CFLAGS		+= -fmessage-length=0 -fno-common -ffunction-sections -fdata-sections
CFLAGS		+= $(DEPS) $(DEFS)

CFLAGS 		+= -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"

###################################
# Linker Flags

LFLAGS		+= $(ARCH_FLAGS) $(DEBUG)
LFLAGS		+= -T$(LD_SCRIPT)
LFLAGS		+= --specs=nosys.specs
LFLAGS		+= -Wl,-Map=$(BUILD_DIR)/$(TARGET).map
LFLAGS		+= -Wl,--gc-sections
LFLAGS		+= -static --specs=nano.specs

LDLIBS 		= -Wl,--start-group -lc -lm -Wl,--end-group

###################################

.SUFFIXES: .elf .bin .hex .srec .list .map .images
.SECONDEXPANSION:
.SECONDARY:

all: elf images bin

elf: $(BUILD_DIR)/$(TARGET).elf
bin: $(BUILD_DIR)/$(TARGET).bin
hex: $(BUILD_DIR)/$(TARGET).hex
srec: $(BUILD_DIR)/$(TARGET).srec
list: $(BUILD_DIR)/$(TARGET).list

GENERATED_BINARIES	= \
$(BUILD_DIR)/$(TARGET).elf \
$(BUILD_DIR)/$(TARGET).bin \
$(BUILD_DIR)/$(TARGET).hex \
$(BUILD_DIR)/$(TARGET).srec \
$(BUILD_DIR)/$(TARGET).list \
$(BUILD_DIR)/$(TARGET).map

images: $(BUILD_DIR)/$(TARGET).images

print-%:
	@echo $*=$($*)

$(BUILD_DIR)/%.images: $(BUILD_DIR)/%.elf $(BUILD_DIR)/%.hex $(BUILD_DIR)/%.srec $(BUILD_DIR)/%.list $(BUILD_DIR)/%.map
	@printf "*** $* images generated ***\n"

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	@printf "  OBJCOPY $(BUILD_DIR)/$(*).bin\n"
	@$(OBJCOPY) -Obinary $(BUILD_DIR)/$(*).elf $(BUILD_DIR)/$(*).bin
	@$(OS) $<

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	@printf "  OBJCOPY $(BUILD_DIR)/$(*).hex\n"
	@$(OBJCOPY) -Oihex $(BUILD_DIR)/$(*).elf $(BUILD_DIR)/$(*).hex

$(BUILD_DIR)/%.srec: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	@printf "  OBJCOPY $(BUILD_DIR)/$(*).srec\n"
	@$(OBJCOPY) -Osrec $(BUILD_DIR)/$(*).elf $(BUILD_DIR)/$(*).srec

$(BUILD_DIR)/%.list: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	@printf "  OBJDUMP $(BUILD_DIR)/$(*).list\n"
	@$(OBJDUMP) -S $(BUILD_DIR)/$(*).elf > $(BUILD_DIR)/$(*).list

$(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/%.map: $(OBJS) $(LDSCRIPT) makefile
	@printf "  LD      $(BUILD_DIR)/$(*).elf\n"
	@$(LD) $(LFLAGS) $(OBJS) $(LDLIBS) -o $(*).elf

$(BUILD_DIR)/%.o: %.c makefile | $(BUILD_DIR)
	@printf "  CC      $(*).c\n"
	@$(CC) $(CFLAGS) -o $@ -c $<

$(BUILD_DIR)/%.o: %.s makefile | $(BUILD_DIR)
	@printf "  CC      $(*).s\n"
	@$(CC) $(ASFLAGS) -o $@ -c $<

$(BUILD_DIR):
	mkdir $@

clean:
	@printf "  CLEAN\n"
	$(RM) -fR $(BUILD_DIR)


.PHONY: images clean elf bin hex srec list

-include $(OBJS:.o=.d)
