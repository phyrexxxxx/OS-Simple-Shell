#!/bin/bash

# =============================================================================
# Test Script: Input and Output Redirection
# Purpose: Test the shell's ability to handle input and output redirection
# Features tested:
#   - Input redirection: cat < text.txt
#   - Output redirection: cat text.txt > out_test.txt
#   - File creation: output redirection creates new files
#   - Content verification: redirected output matches expected content
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
elif [ -d "simple_tests/03_redirection/test_data" ]; then
    TEST_DATA_DIR="simple_tests/03_redirection/test_data"
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

# Helper function to compare file contents
compare_files() {
    local file1="$1"
    local file2="$2"
    local description="$3"
    
    if [ ! -f "$file1" ]; then
        log_error "$description: File '$file1' does not exist"
        return 1
    fi
    
    if [ ! -f "$file2" ]; then
        log_error "$description: File '$file2' does not exist"
        return 1
    fi
    
    if diff -q "$file1" "$file2" > /dev/null; then
        log_success "$description: Files match exactly"
        return 0
    else
        log_error "$description: Files do not match"
        log_info "Expected content (from $file1):"
        head -n 3 "$file1" | sed 's/^/  > /'
        log_info "Actual content (from $file2):"
        head -n 3 "$file2" | sed 's/^/  > /'
        return 1
    fi
}

# Test 1: Input redirection - cat < text.txt
test_input_redirection() {
    log_section "測試 1: 輸入重導向 (cat < text.txt)"
    
    local temp_output=$(mktemp)
    local original_content="text.txt"
    
    # Change to test data directory for relative path tests
    cd "$TEST_DATA_DIR" || exit 1
    
    log_info "Testing input redirection: cat < text.txt"
    log_info "Expected: same content as 'cat text.txt'"
    
    # Run input redirection command in shell with timeout
    echo "cat < text.txt" | timeout $TIMEOUT "$SHELL_BINARY" > "$temp_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Input redirection 'cat < text.txt' timed out after ${TIMEOUT}s"
        rm -f "$temp_output"
        return 1
    elif [ $exit_code -ne 0 ]; then
        log_warn "Input redirection 'cat < text.txt' exited with code: $exit_code"
        log_info "Output: $(cat "$temp_output")"
    fi
    
    # Compare with expected content (should be the same as original file)
    local expected_lines=("Hello world" "A shell interprets user commands into system calls" "The shell parses input using tokenization")
    local test_passed=true
    
    for expected_line in "${expected_lines[@]}"; do
        if grep -q "$expected_line" "$temp_output"; then
            log_success "Output contains expected line: \"$expected_line\""
        else
            log_error "Output missing expected line: \"$expected_line\""
            test_passed=false
        fi
    done
    
    if [ "$test_passed" = true ]; then
        log_success "Input redirection 'cat < text.txt' executed successfully"
        rm -f "$temp_output"
        return 0
    else
        log_error "Input redirection output doesn't match expected content"
        log_info "Actual output:"
        cat "$temp_output" | sed 's/^/  > /'
        rm -f "$temp_output"
        return 1
    fi
}

# Test 2: Output redirection - cat text.txt > out_test.txt
test_output_redirection() {
    log_section "測試 2: 輸出重導向 (cat text.txt > out_test.txt)"
    
    local temp_shell_output=$(mktemp)
    local output_file="out_test.txt"
    
    # Should already be in test data directory from previous test
    
    # Clean up any existing output file from previous tests
    rm -f "$output_file"
    
    log_info "Testing output redirection: cat text.txt > out_test.txt"
    log_info "Expected: creates out_test.txt with same content as text.txt"
    
    # Verify output file doesn't exist before test
    if [ -f "$output_file" ]; then
        log_warn "Output file '$output_file' already exists, removing it first"
        rm -f "$output_file"
    fi
    
    # Run output redirection command in shell with timeout
    echo "cat text.txt > out_test.txt" | timeout $TIMEOUT "$SHELL_BINARY" > "$temp_shell_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Output redirection 'cat text.txt > out_test.txt' timed out after ${TIMEOUT}s"
        rm -f "$temp_shell_output"
        return 1
    elif [ $exit_code -ne 0 ]; then
        log_warn "Output redirection 'cat text.txt > out_test.txt' exited with code: $exit_code"
        log_info "Shell output: $(cat "$temp_shell_output")"
    fi
    
    # Check if output file was created
    if [ ! -f "$output_file" ]; then
        log_error "Output file '$output_file' was not created"
        log_info "Shell output: $(cat "$temp_shell_output")"
        rm -f "$temp_shell_output"
        return 1
    fi
    
    log_success "Output file '$output_file' was created successfully"
    
    # Compare the created file with the original file
    if compare_files "text.txt" "$output_file" "Output redirection content verification"; then
        log_success "Output redirection 'cat text.txt > out_test.txt' executed successfully"
        
        # Show file sizes for additional verification
        local original_size=$(wc -l < "text.txt")
        local output_size=$(wc -l < "$output_file")
        log_info "Original file lines: $original_size, Output file lines: $output_size"
        
        # Clean up
        rm -f "$temp_shell_output" "$output_file"
        return 0
    else
        log_error "Output redirection created file with incorrect content"
        rm -f "$temp_shell_output" "$output_file"
        return 1
    fi
}

# Test 3: Output redirection file creation
test_output_file_creation() {
    log_section "測試 3: 輸出重導向文件創建功能"
    
    local temp_shell_output=$(mktemp)
    local new_output_file="new_created_file.txt"
    
    # Should already be in test data directory
    
    # Ensure the file doesn't exist
    rm -f "$new_output_file"
    
    log_info "Testing file creation: echo 'test content' > new_created_file.txt"
    log_info "Expected: creates new file with specified content"
    
    # Run output redirection command that creates a new file
    echo "echo 'test content' > new_created_file.txt" | timeout $TIMEOUT "$SHELL_BINARY" > "$temp_shell_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "File creation test timed out after ${TIMEOUT}s"
        rm -f "$temp_shell_output"
        return 1
    elif [ $exit_code -ne 0 ]; then
        log_warn "File creation test exited with code: $exit_code"
        log_info "Shell output: $(cat "$temp_shell_output")"
    fi
    
    # Check if new file was created
    if [ ! -f "$new_output_file" ]; then
        log_error "New file '$new_output_file' was not created"
        log_info "Shell output: $(cat "$temp_shell_output")"
        rm -f "$temp_shell_output"
        return 1
    fi
    
    log_success "New file '$new_output_file' was created successfully"
    
    # Check if the content is correct
    if grep -q "test content" "$new_output_file"; then
        log_success "File creation with correct content verified"
        rm -f "$temp_shell_output" "$new_output_file"
        return 0
    else
        log_error "Created file does not contain expected content"
        log_info "Expected: 'test content'"
        log_info "Actual: $(cat "$new_output_file")"
        rm -f "$temp_shell_output" "$new_output_file"
        return 1
    fi
}

# Test 4: Combined redirection functionality
test_combined_redirection() {
    log_section "測試 4: 綜合重導向功能測試"
    
    local temp_shell_output=$(mktemp)
    local temp_input_file=$(mktemp)
    local final_output_file="combined_test_output.txt"
    
    # Should already be in test data directory
    
    # Create a temporary input file with test content
    echo -e "line1\nline2\nline3" > "$temp_input_file"
    local temp_input_basename=$(basename "$temp_input_file")
    
    # Clean up any existing output file
    rm -f "$final_output_file"
    
    log_info "Testing combined functionality: input and output redirection together"
    
    # Test sequence: use input redirection from existing file to create output file
    local test_commands=$(mktemp)
    cat > "$test_commands" << EOF
cat < text.txt > $final_output_file
exit
EOF
    
    # Run the test sequence
    timeout $TIMEOUT "$SHELL_BINARY" < "$test_commands" > "$temp_shell_output" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        log_error "Combined redirection test timed out after ${TIMEOUT}s"
        rm -f "$temp_shell_output" "$test_commands" "$temp_input_file" "$temp_input_basename"
        return 1
    elif [ $exit_code -ne 0 ]; then
        log_warn "Combined redirection test exited with code: $exit_code"
        log_info "Shell output: $(cat "$temp_shell_output")"
    fi
    
    # Check if final output file was created
    if [ ! -f "$final_output_file" ]; then
        log_error "Final output file '$final_output_file' was not created"
        rm -f "$temp_shell_output" "$test_commands" "$temp_input_file" "$temp_input_basename"
        return 1
    fi
    
    # Check if the content matches the original text.txt content
    local expected_lines=("Hello world" "A shell interprets user commands into system calls" "I/O redirection lets users manage data streams")
    local test_passed=true
    
    for expected_line in "${expected_lines[@]}"; do
        if grep -q "$expected_line" "$final_output_file"; then
            log_success "Final output contains expected line: \"$expected_line\""
        else
            log_error "Final output missing expected line: \"$expected_line\""
            test_passed=false
        fi
    done
    
    if [ "$test_passed" = true ]; then
        log_success "Combined redirection functionality works correctly"
        rm -f "$temp_shell_output" "$test_commands" "$temp_input_file" "$temp_input_basename" "$final_output_file"
        return 0
    else
        log_error "Combined redirection test failed"
        log_info "Final output content:"
        cat "$final_output_file" | sed 's/^/  > /'
        rm -f "$temp_shell_output" "$test_commands" "$temp_input_file" "$temp_input_basename" "$final_output_file"
        return 1
    fi
}

# Main test execution
main() {
    log_section "I/O 重導向測試開始"
    log_info "Testing shell binary: $SHELL_BINARY"
    log_info "Test data directory: $TEST_DATA_DIR"
    
    local total_tests=0
    local passed_tests=0
    
    # Run all tests
    check_shell_binary
    
    # Test 1: Input redirection
    total_tests=$((total_tests + 1))
    if test_input_redirection; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Test 2: Output redirection
    total_tests=$((total_tests + 1))
    if test_output_redirection; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Test 3: Output file creation
    total_tests=$((total_tests + 1))
    if test_output_file_creation; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Test 4: Combined redirection
    total_tests=$((total_tests + 1))
    if test_combined_redirection; then
        passed_tests=$((passed_tests + 1))
    fi
    
    # Final results
    log_section "測試結果總結"
    echo -e "通過測試: ${GREEN}$passed_tests${NC}/$total_tests"
    
    if [ $passed_tests -eq $total_tests ]; then
        log_success "所有 I/O 重導向測試通過！"
        exit 0
    else
        log_error "部分測試失敗，請檢查 shell 的 I/O 重導向實作"
        exit 1
    fi
}

# Script entry point
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
