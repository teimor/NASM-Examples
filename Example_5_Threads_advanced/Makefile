# Create build folder
BUILD_FOLDER = build
BUILD_PATH = ./$(BUILD_FOLDER)
SUBDIRS = . $(BUILD_FOLDER)
SUBDIRSCLEAN=$(addsuffix clean,$(SUBDIRS))

CC = gcc
LD = ld
NASM = nasm

CFLAGS = -no-pie -m64 -o
CFLAGSEND = -lm -lpthread
NASMFLAGS = -f elf64
NASMOUTPUT = -o
RUNARGS = 2 1000 13.2

#Change only this for your program name
PROG = threads_fix

ASM = $(PROG).asm
OBJS = $(BUILD_PATH)/$(PROG).o
LST = $(BUILD_PATH)/$(PROG).lst
OUTPUT = $(BUILD_PATH)/$(PROG)

# Run
run: $(BUILD_PATH)/$(PROG)
	$(BUILD_PATH)/$(PROG) $(RUNARGS)

#GCC Linker
$(BUILD_PATH)/$(PROG): $(OBJS)
	$(CC) $(CFLAGS) $(OUTPUT) $(OBJS) $(CFLAGSEND)

# NASM Build
$(OBJS): $(ASM) $(BUILD_FOLDER)
	$(NASM) $(NASMFLAGS) $(NASMOUTPUT) $(OBJS) $(ASM)
	
# Create Build Folder
$(BUILD_FOLDER):
	mkdir -p $(BUILD_FOLDER)

# Clean

clean: $(SUBDIRSCLEAN)

clean_curdir:
	 rm -rfv *.o $(PROG) *.lst *~

%clean: %
	$(MAKE) -C $< -f $(PWD)/Makefile clean_curdir