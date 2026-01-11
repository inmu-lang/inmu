#!/bin/bash
# INMU Stage 0 Test Runner

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to script directory
cd "$(dirname "$0")"

echo -e "${BLUE}=== INMU Stage 0 Test Runner ===${NC}"
echo ""

# Check if inmu binary exists
if [ ! -f "./inmu" ]; then
    echo -e "${RED}Error: ./inmu not found. Building...${NC}"
    make clean && make
    echo ""
fi

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0

# Function to run a single test
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file")
    
    total_tests=$((total_tests + 1))
    
    echo -ne "${YELLOW}Testing:${NC} $test_name ... "
    
    if ./inmu "$test_file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}

# Function to run test with output
run_test_verbose() {
    local test_file=$1
    local test_name=$(basename "$test_file")
    
    echo -e "${BLUE}>>> $test_name${NC}"
    ./inmu "$test_file"
    echo ""
}

# Parse command line arguments
VERBOSE=false
SHOW_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            SHOW_OUTPUT=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose    Show verbose output"
            echo "  -o, --output     Show test outputs"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Run tests
if [ "$SHOW_OUTPUT" = true ]; then
    echo -e "${BLUE}=== Running Tests with Output ===${NC}"
    echo ""
    for test in tests/*.inmu; do
        run_test_verbose "$test"
    done
else
    echo -e "${BLUE}=== Running Unit Tests ===${NC}"
    echo ""
    
    for test in tests/*.inmu; do
        run_test "$test"
    done
    
    echo ""
    echo -e "${BLUE}=== Running Example Programs ===${NC}"
    echo ""
    
    for example in ../examples/*.inmu; do
        if [ -f "$example" ]; then
            run_test "$example"
        fi
    done
fi

# Print summary
echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "Total:  $total_tests"
echo -e "${GREEN}Passed: $passed_tests${NC}"

if [ $failed_tests -gt 0 ]; then
    echo -e "${RED}Failed: $failed_tests${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
