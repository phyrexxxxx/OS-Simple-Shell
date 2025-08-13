#!/bin/bash

# =============================================================================
# Quick Test Runner for Simple Shell Tests
# Usage: ./run_test.sh [test_name]
# Example: ./run_test.sh 01_single_command
# =============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if shell is compiled
check_shell() {
    if [ ! -f "my_shell" ]; then
        log_error "Shell binary 'my_shell' not found. Compiling..."
        if make; then
            log_success "Shell compiled successfully"
        else
            log_error "Failed to compile shell"
            exit 1
        fi
    else
        log_info "Shell binary found"
    fi
}

# Run specific test
run_test() {
    local test_name=$1
    local test_dir="simple_tests/$test_name"
    if [ ! -d "$test_dir" ]; then
        log_error "Test directory '$test_dir' not found"
        list_available_tests
        exit 1
    fi
    
    # Find the test script in the scripts directory
    local test_script=$(find "$test_dir/scripts" -name "*.sh" -executable | head -n 1)
    
    if [ -z "$test_script" ] || [ ! -f "$test_script" ]; then
        log_error "No executable test script found in '$test_dir/scripts/'"
        exit 1
    fi
    
    log_info "Running test: $test_name"
    log_info "Test script: $test_script"
    
    # Execute the test
    if bash "$test_script"; then
        log_success "Test '$test_name' completed successfully"
    else
        log_error "Test '$test_name' failed"
        exit 1
    fi
}

# List available tests
list_available_tests() {
    echo -e "\n${BLUE}Available tests:${NC}"
    for test_dir in simple_tests/*/; do
        if [ -d "$test_dir" ]; then
            local test_name=$(basename "$test_dir")
            echo "  - $test_name"
        fi
    done
    echo ""
}

# Main function
main() {
    echo -e "${BLUE}=== Simple Shell Test Runner ===${NC}"
    
    # Check if we're in the right directory
    if [ ! -f "Makefile" ] || [ ! -f "my_shell.c" ]; then
        log_error "Please run this script from the OS-Simple-Shell root directory"
        exit 1
    fi
    
    # Check and compile shell if needed
    check_shell
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        log_info "No test specified. Available tests:"
        list_available_tests
        echo "Usage: $0 <test_name>"
        echo "Example: $0 01_single_command"
        exit 0
    fi
    
    local test_name=$1
    run_test "$test_name"
}

# Run main function
main "$@"
