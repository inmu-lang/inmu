# Makefile for INMU language interpreter

ASM = as
LD = ld
TARGET = inmu
SOURCE = src/inmu.s

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(ASM) -o $(TARGET).o $(SOURCE)
	$(LD) -o $(TARGET) $(TARGET).o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main -arch arm64

clean:
	rm -f $(TARGET) $(TARGET).o

test: $(TARGET)
	./$(TARGET) examples/hello.inmu

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/
