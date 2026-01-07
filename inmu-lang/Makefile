# Makefile for INMU language interpreter

ASM = as
LD = ld
TARGET = inmu

# Detect architecture
ARCH := $(shell uname -m)

# Set source file based on architecture
ifeq ($(ARCH),arm64)
    SOURCE = src/mac/arm64/main.s
    ARCH_FLAG = arm64
else ifeq ($(ARCH),x86_64)
    SOURCE = src/mac/x86_64/main.s
    ARCH_FLAG = x86_64
else
    $(error Unsupported architecture: $(ARCH))
endif

.PHONY: all clean test universal install

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(ASM) -o $(TARGET).o $(SOURCE)
	$(LD) -o $(TARGET) $(TARGET).o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main -arch $(ARCH_FLAG)

# Build universal binary (both architectures)
universal:
	$(ASM) -arch arm64 -o $(TARGET)_arm64.o src/mac/arm64/main.s
	$(LD) -arch arm64 -o $(TARGET)_arm64 $(TARGET)_arm64.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main
	$(ASM) -arch x86_64 -o $(TARGET)_x86_64.o src/mac/x86_64/main.s
	$(LD) -arch x86_64 -o $(TARGET)_x86_64 $(TARGET)_x86_64.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main
	lipo -create $(TARGET)_arm64 $(TARGET)_x86_64 -output $(TARGET)
	rm -f $(TARGET)_arm64 $(TARGET)_x86_64 $(TARGET)_arm64.o $(TARGET)_x86_64.o

clean:
	rm -f $(TARGET) $(TARGET).o $(TARGET)_arm64 $(TARGET)_x86_64 $(TARGET)_arm64.o $(TARGET)_x86_64.o

test: $(TARGET)
	./$(TARGET) examples/hello.inmu

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/
