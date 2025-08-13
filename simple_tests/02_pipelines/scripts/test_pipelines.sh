#!/bin/bash

# =============================================================================
# Test Script: Two Process Pipelines
# Purpose: Test the shell's ability to execute two process pipelines using |
# Features tested:
#   - Basic pipeline execution (command1 | command2)
#   - Pipe data flow between processes
#   - Specific test cases: cat | head and cat | tail
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
elif [ -d "simple_tests/02_pipelines/test_data" ]; then
    TEST_DATA_DIR="simple_tests/02_pipelines/test_data"
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

# Test 1: cat text.txt | head -1
test_cat_head_pipeline() {
    log_section "測試 1: cat text.txt | head -1"
    
    local temp_output=$(mktemp)
    local expected_output="Hello world"
    
    # Change to test data directory for relative path tests
    cd "$TEST_DATA_DIR" || exit 1
    
    log_info "Testing pipeline: cat text.txt | head -1"
    log_info "Expected output: \"$expected_output\""
    
    # Run pipeline command in shell with timeout
    echo "cat text.txt | head -1" | timeout $TIMEOUT "$SHELL_BINARY" > "$temp_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Pipeline 'cat text.txt | head -1' timed out after ${TIMEOUT}s"
        rm -f "$temp_output"
        return 1
    elif [ $exit_code -ne 0 ]; then
        log_warn "Pipeline 'cat text.txt | head -1' exited with code: $exit_code"
        log_info "Output: $(cat "$temp_output")"
    fi
    
    # Check if output contains expected result
    if grep -q "$expected_output" "$temp_output"; then
        log_success "Pipeline 'cat text.txt | head -1' executed successfully"
        log_info "Actual output contains expected: \"$expected_output\""
        rm -f "$temp_output"
        return 0
    else
        log_error "Pipeline output doesn't match expected result"
        log_info "Expected: \"$expected_output\""
        log_info "Actual output: $(cat "$temp_output")"
        rm -f "$temp_output"
        return 1
    fi
}

# Test 2: cat text.txt | tail -2
test_cat_tail_pipeline() {
    log_section "測試 2: cat text.txt | tail -2"
    
    local temp_output=$(mktemp)
    local expected_line1="I/O redirection lets users manage data streams"
    local expected_line2="Shells often support pipelines for command chaining"
    
    # Should already be in test data directory from previous test
    
    log_info "Testing pipeline: cat text.txt | tail -2"
    log_info "Expected output (line 1): \"$expected_line1\""
    log_info "Expected output (line 2): \"$expected_line2\""
    
    # Run pipeline command in shell with timeout
    echo "cat text.txt | tail -2" | timeout $TIMEOUT "$SHELL_BINARY" > "$temp_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Pipeline 'cat text.txt | tail -2' timed out after ${TIMEOUT}s"
        rm -f "$temp_output"
        return 1
    elif [ $exit_code -ne 0 ]; then
        log_warn "Pipeline 'cat text.txt | tail -2' exited with code: $exit_code"
        log_info "Output: $(cat "$temp_output")"
    fi
    
    # Check if output contains both expected lines
    local test_passed=true
    
    if grep -q "$expected_line1" "$temp_output"; then
        log_success "Output contains expected line 1"
    else
        log_error "Output missing expected line 1: \"$expected_line1\""
        test_passed=false
    fi
    
    if grep -q "$expected_line2" "$temp_output"; then
        log_success "Output contains expected line 2"
    else
        log_error "Output missing expected line 2: \"$expected_line2\""
        test_passed=false
    fi
    
    if [ "$test_passed" = true ]; then
        log_success "Pipeline 'cat text.txt | tail -2' executed successfully"
        rm -f "$temp_output"
        return 0
    else
        log_error "Pipeline output doesn't match expected results"
        log_info "Actual output:"
        cat "$temp_output" | sed 's/^/  > /'
        rm -f "$temp_output"
        return 1
    fi
}

# Test 3: General pipeline functionality
test_pipeline_basics() {
    log_section "測試 3: 基本管道功能檢查"
    
    local temp_output=$(mktemp)
    
    log_info "Testing basic pipeline functionality with: echo hello | cat"
    
    # Test a simple pipeline that should always work
    echo "echo hello | cat" | timeout $TIMEOUT "$SHELL_BINARY" > "$temp_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Basic pipeline test timed out"
        rm -f "$temp_output"
        return 1
    elif [ $exit_code -ne 0 ]; then
        log_warn "Basic pipeline exited with code: $exit_code"
    fi
    
    # Check if output contains "hello"
    if grep -q "hello" "$temp_output"; then
        log_success "Basic pipeline functionality works"
        rm -f "$temp_output"
        return 0
    else
        log_error "Basic pipeline functionality failed"
        log_info "Output: $(cat "$temp_output")"
        rm -f "$temp_output"
        return 1
    fi
}

# Test 4: Pipeline with exit command
test_pipeline_exit() {
    log_section "測試 4: 管道命令後的退出功能"
    
    local temp_output=$(mktemp)
    local temp_input=$(mktemp)
    
    # Create input with pipeline and exit
    cat > "$temp_input" << 'EOF'
echo test | cat
exit
EOF
    
    log_info "Testing pipeline followed by exit command"
    
    # Run shell with pipeline and exit
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Pipeline + exit test timed out"
        rm -f "$temp_output" "$temp_input"
        return 1
    elif [ $exit_code -eq 0 ]; then
        log_success "Pipeline followed by exit works correctly"
        rm -f "$temp_output" "$temp_input"
        return 0
    else
        log_warn "Pipeline + exit returned code: $exit_code"
        log_info "Output: $(cat "$temp_output")"
        rm -f "$temp_output" "$temp_input"
        return 1
    fi
}

# Main test execution
main() {
    log_section "雙進程管道測試開始"
    log_info "Testing shell binary: $SHELL_BINARY"
    log_info "Test data directory: $TEST_DATA_DIR"
    
    local total_tests=0
    local passed_tests=0
    
    # Run all tests
    check_shell_binary
    
    # Test 1: cat | head pipeline
    total_tests=$((total_tests + 1))
    if test_cat_head_pipeline; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Test 2: cat | tail pipeline
    total_tests=$((total_tests + 1))
    if test_cat_tail_pipeline; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Test 3: Basic pipeline functionality
    total_tests=$((total_tests + 1))
    if test_pipeline_basics; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Test 4: Pipeline with exit
    total_tests=$((total_tests + 1))
    if test_pipeline_exit; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Final results
    log_section "測試結果總結"
    echo -e "通過測試: ${GREEN}$passed_tests${NC}/$total_tests"
    
    if [ $passed_tests -eq $total_tests ]; then
        log_success "所有雙進程管道測試通過！"
        exit 0
    else
        log_error "部分測試失敗，請檢查 shell 的管道實作"
        exit 1
    fi
}

# Script entry point
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
