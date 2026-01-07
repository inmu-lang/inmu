# Makefile for INMU Language - Bootstrap Build System
# This orchestrates the multi-stage bootstrap process

.PHONY: all stage0 stage1 stage2 stage3 clean test install help

# Default target - build Stage 0 interpreter
all: stage0

# Stage 0: Assembly interpreter (foundation for everything)
stage0:
	@echo "Building Stage 0: Assembly Interpreter"
	cd stage0 && $(MAKE)
	cp stage0/inmu ./inmu

# Stage 1: INMU language compiler (written in INMU, runs on Stage 0)
stage1: stage0
	@echo "Building Stage 1: Self-hosting compiler (INMU -> Assembly)"
	@echo "Not yet implemented - needs Stage 0 feature expansion first"
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
	cd stage0 && $(MAKE) clean
	rm -f inmu
	# cd stage1 && $(MAKE) clean
	# cd stage2 && $(MAKE) clean
	# cd stage3 && $(MAKE) clean

# Run tests for all implemented stages
test: stage0
	@echo "Running Stage 0 tests..."
	cd stage0 && $(MAKE) test
	# @echo "Running Stage 1 tests..."
	# cd stage1 && $(MAKE) test

# Install the current working compiler
install: stage0
	@echo "Installing INMU compiler..."
	cd stage0 && $(MAKE) install

# Show help
help:
	@echo "INMU Language Bootstrap Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build Stage 0 (default)"
	@echo "  stage0   - Build assembly interpreter"
	@echo "  stage1   - Build self-hosting compiler (not yet implemented)"
	@echo "  stage2   - Build verified self-hosted compiler (not yet implemented)"
	@echo "  stage3   - Build optimizing compiler (not yet implemented)"
	@echo "  clean    - Remove all build artifacts"
	@echo "  test     - Run all tests"
	@echo "  install  - Install INMU to /usr/local/bin"
	@echo "  help     - Show this help message"
	@echo ""
	@echo "For more information, see BOOTSTRAP.md"
