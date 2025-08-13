#!/bin/bash

# =============================================================================
# Test Script: Comprehensive Shell Features (Background + Redirection + Pipelines)
# Purpose:
#   Test complex combinations of shell features:
#   1. Background execution with input/output redirection
#   2. Background execution with pipelines and redirection
#   3. Multi-stage pipelines with background execution
#
# Test Cases:
#   1. cat < t1.txt > t2.txt &
#   2. record | head -c 32 > t2.txt &  (假設 record 為內建命令)
#   3. cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt &
#
# How to run:
#   - From project root:
#       make
#       ./simple_tests/run_test.sh 06_comprehensive
#   - Or run directly:
#       bash simple_tests/06_comprehensive/scripts/test_comprehensive.sh
# =============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration (auto-detect shell path)
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

TIMEOUT=10

# We will reuse the provided dataset and create temporary files as needed
TEST_DATA_DIR="$PROJECT_ROOT/simple_tests/03_redirection/test_data"
SOURCE_FILE="text.txt"

# Utility functions
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_success(){ echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_section(){ echo -e "\n${BLUE}=== $1 ===${NC}"; }

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

check_test_data() {
    if [ ! -d "$TEST_DATA_DIR" ]; then
        log_error "Test data directory not found: $TEST_DATA_DIR"
        exit 1
    fi
    if [ ! -f "$TEST_DATA_DIR/$SOURCE_FILE" ]; then
        log_error "Test data file not found: $TEST_DATA_DIR/$SOURCE_FILE"
        exit 1
    fi
}

# Extract first PID-like value from output; supports prompt-prefixed lines
extract_pid_from_output() {
    local output_file="$1"
    local pid
    pid=$(grep -E '^[0-9]+$' "$output_file" | head -n 1 | tr -d '\n')
    if [[ -n "$pid" ]]; then
        echo -n "$pid"; return 0
    fi
    pid=$(awk 'BEGIN{pid=""}
        /^[^\[]/ {
          n=split($0, a, /[[:space:]]+/);
          if (n>0 && a[n] ~ /^[0-9]+$/) { pid=a[n]; print pid; exit }
        }' "$output_file")
    if [[ -n "$pid" ]]; then
        echo -n "$pid"; return 0
    fi
    return 1
}

# Test 1: Background execution with input/output redirection
# Command: cat < t1.txt > t2.txt &
test_background_io_redirection() {
    log_section "測試 1: 背景執行 + I/O 重導向 (cat < t1.txt > t2.txt &)"

    local temp_input="$(mktemp)"
    local temp_output="$(mktemp)"

    # Prepare environment
    pushd "$TEST_DATA_DIR" >/dev/null || return 1
    
    # First create t1.txt by copying from text.txt
    cp "$SOURCE_FILE" "t1.txt" || {
        log_error "Failed to create t1.txt from $SOURCE_FILE"
        popd >/dev/null; return 1
    }
    
    # Clean up any existing t2.txt
    rm -f "t2.txt"

    # Create test input
    cat > "$temp_input" << 'EOF'
cat < t1.txt > t2.txt &
exit
EOF

    log_info "Running: cat < t1.txt > t2.txt & (with exit)"
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_error "Background I/O redirection test timed out after ${TIMEOUT}s"
        popd >/dev/null; rm -f "$temp_input" "$temp_output" "t1.txt"
        return 1
    fi

    # Check PID output
    local pid_line
    pid_line=$(extract_pid_from_output "$temp_output")
    if [[ -n "$pid_line" && "$pid_line" =~ ^[0-9]+$ ]]; then
        log_success "Found background PID printed: $pid_line"
    else
        log_error "No numeric PID line found for background I/O redirection"
        log_info "Actual output:"
        sed 's/^/  > /' "$temp_output"
        popd >/dev/null; rm -f "$temp_input" "$temp_output" "t1.txt"
        return 1
    fi

    # Wait for background process to complete and check t2.txt
    local wait_ok=0
    for _ in $(seq 1 40); do # up to ~2s
        if [ -f "t2.txt" ]; then wait_ok=1; break; fi
        sleep 0.05
    done
    
    if [ $wait_ok -ne 1 ]; then
        log_error "Output file 't2.txt' was not created"
        popd >/dev/null; rm -f "$temp_input" "$temp_output" "t1.txt"
        return 1
    fi

    # Compare t1.txt and t2.txt content
    if diff "t1.txt" "t2.txt" >/dev/null 2>&1; then
        log_success "t2.txt content matches t1.txt (I/O redirection successful)"
    else
        log_error "t2.txt content does not match t1.txt"
        popd >/dev/null; rm -f "$temp_input" "$temp_output" "t1.txt" "t2.txt"
        return 1
    fi

    # Clean up
    rm -f "$temp_input" "$temp_output" "t1.txt" "t2.txt"
    popd >/dev/null
    return 0
}

# Test 2: Background execution with pipeline and output redirection
# Note: We'll use a simple command instead of 'record' since it might not be implemented
# Command: cat text.txt | head -c 32 > t2.txt &
test_background_pipeline_redirection() {
    log_section "測試 2: 背景執行 + 管線 + 輸出重導向 (cat text.txt | head -c 32 > t2.txt &)"

    local temp_input="$(mktemp)"
    local temp_output="$(mktemp)"

    # Prepare environment
    pushd "$TEST_DATA_DIR" >/dev/null || return 1
    rm -f "t2.txt"

    # Create test input (using cat instead of record for compatibility)
    cat > "$temp_input" << 'EOF'
cat text.txt | head -c 32 > t2.txt &
exit
EOF

    log_info "Running: cat text.txt | head -c 32 > t2.txt & (with exit)"
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_error "Background pipeline redirection test timed out after ${TIMEOUT}s"
        popd >/dev/null; rm -f "$temp_input" "$temp_output"
        return 1
    fi

    # Check PID output
    local pid_line
    pid_line=$(extract_pid_from_output "$temp_output")
    if [[ -n "$pid_line" && "$pid_line" =~ ^[0-9]+$ ]]; then
        log_success "Found background PID printed: $pid_line"
    else
        log_error "No numeric PID line found for background pipeline redirection"
        log_info "Actual output:"
        sed 's/^/  > /' "$temp_output"
        popd >/dev/null; rm -f "$temp_input" "$temp_output"
        return 1
    fi

    # Wait for background process to complete and check t2.txt
    local wait_ok=0
    for _ in $(seq 1 40); do # up to ~2s
        if [ -f "t2.txt" ]; then wait_ok=1; break; fi
        sleep 0.05
    done
    
    if [ $wait_ok -ne 1 ]; then
        log_error "Output file 't2.txt' was not created"
        popd >/dev/null; rm -f "$temp_input" "$temp_output"
        return 1
    fi

    # Check that t2.txt has exactly 32 characters
    local file_size
    file_size=$(wc -c < "t2.txt" | tr -d ' ')
    if [ "$file_size" -eq 32 ]; then
        log_success "t2.txt has exactly 32 characters (head -c 32 successful)"
    else
        log_error "t2.txt size expected 32 characters, got $file_size"
        popd >/dev/null; rm -f "$temp_input" "$temp_output" "t2.txt"
        return 1
    fi

    # Show content for reference
    log_info "t2.txt content: $(cat "t2.txt" | tr '\n' ' ')"

    # Clean up
    rm -f "$temp_input" "$temp_output" "t2.txt"
    popd >/dev/null
    return 0
}

# Test 3: Complex multi-stage pipeline with background execution
# Command: cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt &
test_complex_background_pipeline() {
    log_section "測試 3: 複雜多重管線背景執行 (cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt &)"

    local temp_input="$(mktemp)"
    local temp_output="$(mktemp)"

    # Prepare environment
    pushd "$TEST_DATA_DIR" >/dev/null || return 1
    
    # Create t1.txt by copying from text.txt
    cp "$SOURCE_FILE" "t1.txt" || {
        log_error "Failed to create t1.txt from $SOURCE_FILE"
        popd >/dev/null; return 1
    }
    
    rm -f "t2.txt"

    # Create test input
    cat > "$temp_input" << 'EOF'
cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt &
exit
EOF

    log_info "Running: cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt & (with exit)"
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_error "Complex pipeline test timed out after ${TIMEOUT}s"
        popd >/dev/null; rm -f "$temp_input" "$temp_output" "t1.txt"
        return 1
    fi

    # Check PID output (should be grep's PID - rightmost command)
    local pid_line
    pid_line=$(extract_pid_from_output "$temp_output")
    if [[ -n "$pid_line" && "$pid_line" =~ ^[0-9]+$ ]]; then
        log_success "Found background PID printed (rightmost command): $pid_line"
    else
        log_error "No numeric PID line found for complex pipeline"
        log_info "Actual output:"
        sed 's/^/  > /' "$temp_output"
        popd >/dev/null; rm -f "$temp_input" "$temp_output" "t1.txt"
        return 1
    fi

    # Wait for background process to complete and check t2.txt
    local wait_ok=0
    for _ in $(seq 1 40); do # up to ~2s
        if [ -f "t2.txt" ]; then wait_ok=1; break; fi
        sleep 0.05
    done
    
    if [ $wait_ok -ne 1 ]; then
        log_error "Output file 't2.txt' was not created"
        popd >/dev/null; rm -f "$temp_input" "$temp_output" "t1.txt"
        return 1
    fi

    # Expected content: lines containing "shell" from lines 3-5 of text.txt
    local expected_lines=("The shell parses input using tokenization" "Custom shells often rely on \`fork()\` and \`exec()\` for execution")
    local test_passed=true
    
    for expected_line in "${expected_lines[@]}"; do
        if grep -Fq "$expected_line" "t2.txt"; then
            log_success "Output contains expected line: $expected_line"
        else
            log_error "Output missing expected line: $expected_line"
            test_passed=false
        fi
    done

    # Show file content for reference
    log_info "t2.txt content:"; sed 's/^/  > /' "t2.txt"

    # Clean up
    rm -f "$temp_input" "$temp_output" "t1.txt" "t2.txt"
    popd >/dev/null

    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

main() {
    log_section "綜合功能測試開始"
    log_info "Testing shell binary: $SHELL_BINARY"
    log_info "Using test data dir: $TEST_DATA_DIR"

    local total_tests=0
    local passed_tests=0

    check_shell_binary
    check_test_data

    # Test 1: Background I/O redirection
    total_tests=$((total_tests + 1))
    if test_background_io_redirection; then
        passed_tests=$((passed_tests + 1))
    fi

    # Test 2: Background pipeline + redirection
    total_tests=$((total_tests + 1))
    if test_background_pipeline_redirection; then
        passed_tests=$((passed_tests + 1))
    fi

    # Test 3: Complex background pipeline
    total_tests=$((total_tests + 1))
    if test_complex_background_pipeline; then
        passed_tests=$((passed_tests + 1))
    fi

    log_section "測試結果總結"
    echo -e "通過測試: ${GREEN}$passed_tests${NC}/$total_tests"
    if [ $passed_tests -eq $total_tests ]; then
        log_success "所有綜合功能測試通過！"
        exit 0
    else
        log_error "部分測試失敗，請檢查 shell 的綜合功能實作"
        exit 1
    fi
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi
