#!/bin/bash

# =============================================================================
# Test Script: Single Process Command Execution
# Purpose: Test the shell's ability to execute single process commands
# Features tested:
#   - Basic command execution (ls, cat, whoami, pwd)
#   - Handling empty lines (spaces/tabs only)
#   - Exit command functionality
# =============================================================================

# Color definitions for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
# Auto-detect the shell binary location and convert to absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"

if [ -f "$PROJECT_ROOT/my_shell" ]; then
    SHELL_BINARY="$PROJECT_ROOT/my_shell"
elif [ -f "../../my_shell" ]; then
    SHELL_BINARY="$(cd "$(dirname "$0")/../../" && pwd)/my_shell"
elif [ -f "my_shell" ]; then
    SHELL_BINARY="$(pwd)/my_shell"
else
    SHELL_BINARY="my_shell"  # fallback, will fail gracefully
fi

# Auto-detect test data directory
if [ -d "../test_data" ]; then
    TEST_DATA_DIR="../test_data"
elif [ -d "simple_tests/01_single_command/test_data" ]; then
    TEST_DATA_DIR="simple_tests/01_single_command/test_data"
else
    TEST_DATA_DIR="test_data"  # fallback
fi

OUTPUT_DIR="../expected"
TIMEOUT=10

# Utility functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Check if shell binary exists
check_shell_binary() {
    log_section "環境檢查"
    
    if [ ! -f "$SHELL_BINARY" ]; then
        log_error "Shell binary not found at: $SHELL_BINARY"
        log_info "Please compile the shell first using: make"
        exit 1
    fi
    
    if [ ! -x "$SHELL_BINARY" ]; then
        log_error "Shell binary is not executable: $SHELL_BINARY"
        exit 1
    fi
    
    log_success "Shell binary found and executable"
}

# Test 1: Basic command execution
test_basic_commands() {
    log_section "測試 1: 基本命令執行"
    
    local test_passed=true
    local temp_output=$(mktemp)
    
    # Change to test data directory for relative path tests
    cd "$TEST_DATA_DIR" || exit 1
    
    # Test individual commands
    local commands=("ls" "pwd" "whoami" "cat text.txt")
    
    for cmd in "${commands[@]}"; do
        log_info "Testing command: $cmd"
        
        # Run command in shell with timeout
        echo "$cmd" | timeout $TIMEOUT "$SHELL_BINARY" > "$temp_output" 2>&1
        local exit_code=$?
        
        if [ $exit_code -eq 124 ]; then
            log_error "Command '$cmd' timed out after ${TIMEOUT}s"
            test_passed=false
        elif [ $exit_code -ne 0 ]; then
            log_warn "Command '$cmd' exited with code: $exit_code"
            log_info "Output: $(cat "$temp_output")"
        else
            # Check if output contains expected results
            case "$cmd" in
                "ls")
                    if grep -q "text.txt" "$temp_output"; then
                        log_success "ls command executed successfully"
                    else
                        log_error "ls output doesn't contain expected files"
                        test_passed=false
                    fi
                    ;;
                "pwd")
                    if grep -q "01_single_command/test_data" "$temp_output"; then
                        log_success "pwd command executed successfully"
                    else
                        log_error "pwd output unexpected"
                        test_passed=false
                    fi
                    ;;
                "whoami")
                    if [ -s "$temp_output" ]; then
                        log_success "whoami command executed successfully"
                    else
                        log_error "whoami produced no output"
                        test_passed=false
                    fi
                    ;;
                "cat text.txt")
                    if grep -q "Hello world" "$temp_output"; then
                        log_success "cat command executed successfully"
                    else
                        log_error "cat output doesn't contain expected content"
                        test_passed=false
                    fi
                    ;;
            esac
        fi
        
        # Show partial output for verification
        log_info "Output preview: $(head -n 3 "$temp_output" | tr '\n' ' ')..."
    done
    
    rm -f "$temp_output"
    
    if [ "$test_passed" = true ]; then
        log_success "Basic commands test PASSED"
        return 0
    else
        log_error "Basic commands test FAILED"
        return 1
    fi
}

# Test 2: Empty line handling
test_empty_lines() {
    log_section "測試 2: 空行處理 (只有空格/Tab的行)"
    
    local temp_output=$(mktemp)
    local temp_input=$(mktemp)
    
    # Create input with empty lines and spaces/tabs
    cat > "$temp_input" << 'EOF'
   
	
  	  
pwd
exit
EOF
    
    log_info "Testing empty line handling..."
    
    # Run shell with empty lines input
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Empty line test timed out"
        rm -f "$temp_output" "$temp_input"
        return 1
    fi
    
    # Check that shell continues to work after empty lines
    if grep -q "$(pwd)" "$temp_output"; then
        log_success "Shell correctly handles empty lines and continues execution"
        rm -f "$temp_output" "$temp_input"
        return 0
    else
        log_error "Shell may have issues with empty line handling"
        log_info "Output: $(cat "$temp_output")"
        rm -f "$temp_output" "$temp_input"
        return 1
    fi
}

# Test 3: Exit command
test_exit_command() {
    log_section "測試 3: Exit 命令"
    
    local temp_output=$(mktemp)
    
    log_info "Testing exit command..."
    
    # Test exit command
    echo "exit" | timeout $TIMEOUT "$SHELL_BINARY" > "$temp_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Exit command test timed out (shell may not be exiting properly)"
        rm -f "$temp_output"
        return 1
    elif [ $exit_code -eq 0 ]; then
        log_success "Exit command works correctly"
        rm -f "$temp_output"
        return 0
    else
        log_warn "Exit command returned code: $exit_code"
        log_info "Output: $(cat "$temp_output")"
        rm -f "$temp_output"
        return 1
    fi
}

# Main test execution
main() {
    log_section "單一進程命令測試開始"
    log_info "Testing shell binary: $SHELL_BINARY"
    log_info "Test data directory: $TEST_DATA_DIR"
    
    local total_tests=0
    local passed_tests=0
    
    # Run all tests
    check_shell_binary
    
    # Test 1: Basic commands
    total_tests=$((total_tests + 1))
    if test_basic_commands; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Test 2: Empty lines
    total_tests=$((total_tests + 1))
    if test_empty_lines; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Test 3: Exit command
    total_tests=$((total_tests + 1))
    if test_exit_command; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Final results
    log_section "測試結果總結"
    echo -e "通過測試: ${GREEN}$passed_tests${NC}/$total_tests"
    
    if [ $passed_tests -eq $total_tests ]; then
        log_success "所有單一進程命令測試通過！"
        exit 0
    else
        log_error "部分測試失敗，請檢查 shell 實作"
        exit 1
    fi
}

# Script entry point
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
