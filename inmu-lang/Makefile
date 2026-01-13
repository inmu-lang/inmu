# Makefile for INMU Language - Bootstrap Build System
# This orchestrates the multi-stage bootstrap process

.PHONY: all stage0 stage1 stage2 stage3 clean test install help run

# Platform detection
ifeq ($(OS),Windows_NT)
	PLATFORM := windows
	BINARY_EXT := .exe
	RM := del /Q
	CP := copy
	MKDIR := mkdir
	PATH_SEP := \\
else
	PLATFORM := unix
	BINARY_EXT :=
	RM := rm -f
	CP := cp
	MKDIR := mkdir -p
	PATH_SEP := /
endif

# Binary names
INMU_BIN := inmu$(BINARY_EXT)
INMU_SRC := stage0$(PATH_SEP)target$(PATH_SEP)release$(PATH_SEP)$(INMU_BIN)

# Default target - build Stage 0 interpreter
all: stage0

# Stage 0: Rust interpreter (foundation for everything)
stage0:
	@echo "Building Stage 0: Rust Interpreter"
	cd stage0 && cargo build --release
	@echo "Copying binary to root directory..."
ifeq ($(PLATFORM),windows)
	@if exist $(INMU_BIN) del /Q $(INMU_BIN)
	@copy stage0\target\release\inmu.exe inmu.exe
else
	@cp stage0/target/release/inmu ./inmu
endif
	@echo "Stage 0 build complete: $(INMU_BIN)"

# Quick run command for testing
run: stage0
	@echo "Running example program..."
ifeq ($(PLATFORM),windows)
	@.\inmu.exe examples\hello.inmu
else
	@./inmu examples/hello.inmu
endif

# Stage 1: INMU language compiler (written in INMU, runs on Stage 0)
stage1: stage0
	@echo "Building Stage 1: Self-hosting compiler (INMU -> Assembly)"
	@echo "Not yet implemented - needs Stage 0 feature expansion first"
	@echo "Required features: functions, while loops, arrays, file I/O"
	# cd stage1 && $(MAKE)

# Stage 2: Self-hosted compiler (Stage 1 compiles itself)
stage2: stage1
	@echo "Building Stage 2: Self-hosted compiler verification"
	@echo "Not yet implemented"
	# cd stage2 && $(MAKE)

# Stage 3: Optimizing compiler
stage3: stage2
	@echo "Building Stage 3: Optimizing compiler"
	@echo "Not yet implemented"
	# cd stage3 && $(MAKE)

# Clean all build artifacts
clean:
	@echo "Cleaning all stages..."
	cd stage0 && cargo clean
ifeq ($(PLATFORM),windows)
	@if exist inmu.exe del /Q inmu.exe
else
	@rm -f inmu
endif
	# cd stage1 && $(MAKE) clean
	# cd stage2 && $(MAKE) clean
	# cd stage3 && $(MAKE) clean

# Run tests for all implemented stages
test: stage0
	@echo "Running Stage 0 tests..."
	@echo "Testing hello.inmu..."
ifeq ($(PLATFORM),windows)
	@.\inmu.exe examples\hello.inmu
	@echo.
	@echo "Testing arithmetic.inmu..."
	@.\inmu.exe examples\arithmetic.inmu
	@echo.
	@echo "Testing variables.inmu..."
	@.\inmu.exe examples\variables.inmu
	@echo.
	@echo "Testing control.inmu..."
	@.\inmu.exe examples\control.inmu
	@echo.
	@echo "Testing assertions..."
	@.\inmu.exe examples\test_assert.inmu
else
	@./inmu examples/hello.inmu
	@echo ""
	@echo "Testing arithmetic.inmu..."
	@./inmu examples/arithmetic.inmu
	@echo ""
	@echo "Testing variables.inmu..."
	@./inmu examples/variables.inmu
	@echo ""
	@echo "Testing control.inmu..."
	@./inmu examples/control.inmu
	@echo ""
	@echo "Testing assertions..."
	@./inmu examples/test_assert.inmu
endif
	@echo ""
	@echo "All tests passed!"

# Install the current working compiler
install: stage0
ifeq ($(PLATFORM),windows)
	@echo "Installing INMU interpreter to C:\Program Files\inmu..."
	@echo "Note: This requires administrator privileges"
	@if not exist "C:\Program Files\inmu" mkdir "C:\Program Files\inmu"
	@copy inmu.exe "C:\Program Files\inmu\inmu.exe"
	@echo "Installation complete. Add C:\Program Files\inmu to your PATH."
else
	@echo "Installing INMU interpreter to /usr/local/bin..."
	@install -m 755 stage0/target/release/inmu /usr/local/bin/inmu
	@echo "Installation complete. You can now run 'inmu <file.inmu>' from anywhere."
endif

# Uninstall
uninstall:
ifeq ($(PLATFORM),windows)
	@echo "Removing INMU interpreter from C:\Program Files\inmu..."
	@if exist "C:\Program Files\inmu\inmu.exe" del /Q "C:\Program Files\inmu\inmu.exe"
	@if exist "C:\Program Files\inmu" rmdir "C:\Program Files\inmu"
	@echo "Uninstall complete."
else
	@echo "Removing INMU interpreter from /usr/local/bin..."
	@rm -f /usr/local/bin/inmu
	@echo "Uninstall complete."
endif

# Development build (debug mode)
dev:
	@echo "Building Stage 0 in debug mode..."
	cd stage0 && cargo build
ifeq ($(PLATFORM),windows)
	@if exist inmu-dev.exe del /Q inmu-dev.exe
	@copy stage0\target\debug\inmu.exe inmu-dev.exe
	@echo "Debug build complete: inmu-dev.exe"
else
	@cp stage0/target/debug/inmu ./inmu-dev
	@echo "Debug build complete: ./inmu-dev"
endif

# Format code
fmt:
	@echo "Formatting Rust code..."
	cd stage0 && cargo fmt

# Lint code
lint:
	@echo "Running clippy..."
	cd stage0 && cargo clippy -- -D warnings

# Check code without building
check:
	@echo "Checking Stage 0..."
	cd stage0 && cargo check

# Show help
help:
	@echo "INMU Language Bootstrap Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build Stage 0 (default)"
	@echo "  stage0   - Build Rust interpreter"
	@echo "  run      - Build and run hello.inmu example"
	@echo "  test     - Run all example programs as tests"
	@echo "  stage1   - Build self-hosting compiler (not yet implemented)"
	@echo "  stage2   - Build verified self-hosted compiler (not yet implemented)"
	@echo "  stage3   - Build optimizing compiler (not yet implemented)"
	@echo "  clean    - Remove all build artifacts"
	@echo "  install  - Install INMU to /usr/local/bin"
	@echo "  uninstall- Remove INMU from /usr/local/bin"
	@echo "  dev      - Build in debug mode"
	@echo "  fmt      - Format Rust source code"
	@echo "  lint     - Run clippy linter"
	@echo "  check    - Check code without building"
	@echo "  help     - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make              # Build Stage 0"
	@echo "  make run          # Build and run hello.inmu"
	@echo "  make test         # Run all tests"
	@echo "  make install      # Install to system"
	@echo ""
	@echo "For more information, see BOOTSTRAP.md"
