#!/bin/bash

# =============================================================================
# Test Script: Multi-Pipelines & Background Execution (1.6)
# Purpose:
#   - Verify the shell can run multi-stage pipelines combining redirection and pipes
#   - When running in background, the shell should print the PID of the RIGHT-MOST
#     command in the pipeline (e.g., grep in the example).
#
# Example pipeline (background):
#   cat < text.txt | head -4 | tail -2 | grep shell > pipeout.txt &
#
# How to run:
#   - From project root:
#       make
#       ./simple_tests/run_test.sh 05_multi_pipelines
#   - Or run directly:
#       bash simple_tests/05_multi_pipelines/scripts/test_multi_pipelines.sh
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

# We will reuse the provided dataset at simple_tests/03_redirection/test_data/text.txt
TEST_DATA_DIR="$PROJECT_ROOT/simple_tests/03_redirection/test_data"
TEST_INPUT_FILE="text.txt"
OUTPUT_FILE="pipeout.txt"

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
    if [ ! -f "$TEST_DATA_DIR/$TEST_INPUT_FILE" ]; then
        log_error "Test data file not found: $TEST_DATA_DIR/$TEST_INPUT_FILE"
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

# Test 1: Run multi-pipeline in background and verify PID is printed (right-most)
test_multi_pipeline_background_pid() {
    log_section "測試 1: 多重管線背景執行 PID 輸出"

    local temp_input="$(mktemp)"
    local temp_output="$(mktemp)"

    # Prepare environment
    pushd "$TEST_DATA_DIR" >/dev/null || return 1
    rm -f "$OUTPUT_FILE"

    # The exact pipeline from the requirement
    cat > "$temp_input" << 'EOF'
cat < text.txt | head -4 | tail -2 | grep shell > pipeout.txt &
exit
EOF

    log_info "Running multi-pipeline in background..."
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_error "Multi-pipeline test timed out after ${TIMEOUT}s"
        popd >/dev/null
        rm -f "$temp_input" "$temp_output"
        return 1
    fi

    # Extract printed PID and (optionally) job info line
    local pid_line
    pid_line=$(extract_pid_from_output "$temp_output")
    if [[ -n "$pid_line" && "$pid_line" =~ ^[0-9]+$ ]]; then
        log_success "Found background PID printed (right-most command): $pid_line"
    else
        log_error "No numeric-only PID line found for multi-pipeline background run"
        log_info "Actual output:"
        sed 's/^/  > /' "$temp_output"
        popd >/dev/null
        rm -f "$temp_input" "$temp_output"
        return 1
    fi

    # Optional: job info line like: [<job_id>] <pgid>
    if grep -Eq '^\[[0-9]+\] [0-9]+$' "$temp_output"; then
        log_success "Found job info line: [<job_id>] <pgid>"
    else
        log_warn "Job info line not found (optional)"
    fi

    popd >/dev/null
    rm -f "$temp_input" "$temp_output"
    return 0
}

# Test 2: Verify pipeout.txt content is correct
test_multi_pipeline_output_content() {
    log_section "測試 2: 多重管線輸出內容驗證 (pipeout.txt)"

    pushd "$TEST_DATA_DIR" >/dev/null || return 1

    # Wait briefly for background to finish and file to appear
    local wait_ok=0
    for _ in $(seq 1 40); do # up to ~2s
        if [ -f "$OUTPUT_FILE" ]; then wait_ok=1; break; fi
        sleep 0.05
    done
    if [ $wait_ok -ne 1 ]; then
        log_error "Output file '$OUTPUT_FILE' was not created"
        popd >/dev/null
        return 1
    fi

    # Expected two lines
    local expected1='The shell parses input using tokenization'
    local expected2='Custom shells often rely on `fork()` and `exec()` for execution'

    local test_passed=true
    if grep -Fxq "$expected1" "$OUTPUT_FILE"; then
        log_success "Output contains expected line 1"
    else
        log_error "Output missing expected line 1: $expected1"
        test_passed=false
    fi

    if grep -Fxq "$expected2" "$OUTPUT_FILE"; then
        log_success "Output contains expected line 2"
    else
        log_error "Output missing expected line 2: $expected2"
        test_passed=false
    fi

    # Optionally check exactly two lines
    local line_count
    line_count=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
    if [ "$line_count" -eq 2 ]; then
        log_success "Output file has exactly 2 lines"
    else
        log_warn "Output file line count expected 2, got $line_count"
    fi

    # Show file content for reference
    log_info "pipeout.txt content:"; sed 's/^/  > /' "$OUTPUT_FILE"

    # Clean up
    rm -f "$OUTPUT_FILE"
    popd >/dev/null

    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

main() {
    log_section "多重管線與背景執行測試開始"
    log_info "Testing shell binary: $SHELL_BINARY"
    log_info "Using test data dir: $TEST_DATA_DIR"

    local total_tests=0
    local passed_tests=0

    check_shell_binary
    check_test_data

    total_tests=$((total_tests + 1))
    if test_multi_pipeline_background_pid; then
        passed_tests=$((passed_tests + 1))
    fi

    total_tests=$((total_tests + 1))
    if test_multi_pipeline_output_content; then
        passed_tests=$((passed_tests + 1))
    fi

    log_section "測試結果總結"
    echo -e "通過測試: ${GREEN}$passed_tests${NC}/$total_tests"
    if [ $passed_tests -eq $total_tests ]; then
        log_success "多重管線與背景執行相關測試全部通過！"
        exit 0
    else
        log_error "部分測試失敗，請檢查 shell 的多重管線/背景執行實作"
        exit 1
    fi
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi


