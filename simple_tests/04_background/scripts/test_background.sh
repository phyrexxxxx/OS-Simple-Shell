#!/bin/bash

# =============================================================================
# Test Script: Background Execution (commands with &)
# Purpose: Verify that the shell prints the PID of the child process when a
#          command is executed in the background (e.g., `ls &`).
#
# This script performs the following checks:
#   1) Run `ls &` and verify that a numeric PID line is printed.
#   2) Run `sleep 1 &` and verify that the printed PID corresponds to a live
#      process briefly (by checking /proc/<PID>), then allow it to finish.
#   3) Optionally verify that a job info line like `[<job_id>] <pgid>` appears.
#
# How to run:
#   - From project root:
#       make
#       ./simple_tests/run_test.sh 04_background
#   - Or run directly:
#       bash simple_tests/04_background/scripts/test_background.sh
#
# Expected behavior:
#   - The shell should print at least one line that is ONLY digits, which is the
#     child PID of the background command.
#   - The shell may also print a job info line like: `[1] 12345`
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

# Extract first numeric-only line from output as a candidate PID
extract_pid_from_output() {
    local output_file="$1"
    # Strategy:
    # 1) Prefer a numeric-only line.
    # 2) Fallback: a line (not starting with '[') whose LAST field is numeric
    #    (handles cases like "prompt >>> $ 12345").
    local pid
    pid=$(grep -E '^[0-9]+$' "$output_file" | head -n 1 | tr -d '\n')
    if [[ -n "$pid" ]]; then
        echo -n "$pid"
        return 0
    fi
    pid=$(awk 'BEGIN{pid=""}
        /^[^\[]/ {
          n=split($0, a, /[[:space:]]+/);
          if (n>0 && a[n] ~ /^[0-9]+$/) { pid=a[n]; print pid; exit }
        }' "$output_file")
    if [[ -n "$pid" ]]; then
        echo -n "$pid"
        return 0
    fi
    return 1
}

# Test 1: `ls &` should print a numeric PID line
test_ls_background() {
    log_section "測試 1: ls & 的背景執行 PID 輸出"

    local temp_input
    local temp_output
    temp_input=$(mktemp)
    temp_output=$(mktemp)

    cat > "$temp_input" << 'EOF'
ls &
exit
EOF

    log_info "Running: ls & (with exit)"
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_error "ls & test timed out after ${TIMEOUT}s"
        rm -f "$temp_input" "$temp_output"
        return 1
    fi

    local pid_line
    pid_line=$(extract_pid_from_output "$temp_output")

    if [[ -n "$pid_line" && "$pid_line" =~ ^[0-9]+$ ]]; then
        log_success "Found background PID printed: $pid_line"
        log_info "Output preview: $(head -n 6 "$temp_output" | tr '\n' ' ') ..."
        rm -f "$temp_input" "$temp_output"
        return 0
    else
        log_error "No numeric-only PID line found in output for 'ls &'"
        log_info "Actual output:"
        sed 's/^/  > /' "$temp_output"
        rm -f "$temp_input" "$temp_output"
        return 1
    fi
}

# Test 2: `sleep 1 &` should print a PID that exists briefly in /proc
test_sleep_background_pid_exists() {
    log_section "測試 2: sleep 1 & 的 PID 應為短暫存活的程序"

    local temp_input
    local temp_output
    temp_input=$(mktemp)
    temp_output=$(mktemp)

    cat > "$temp_input" << 'EOF'
sleep 1 &
exit
EOF

    log_info "Running: sleep 1 & (with exit)"
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_error "sleep 1 & test timed out after ${TIMEOUT}s"
        rm -f "$temp_input" "$temp_output"
        return 1
    fi

    local pid_line
    pid_line=$(extract_pid_from_output "$temp_output")

    if [[ -z "$pid_line" || ! "$pid_line" =~ ^[0-9]+$ ]]; then
        log_error "No numeric-only PID line found in output for 'sleep 1 &'"
        log_info "Actual output:"
        sed 's/^/  > /' "$temp_output"
        rm -f "$temp_input" "$temp_output"
        return 1
    fi

    log_info "Printed PID: $pid_line (checking /proc)"

    # Give the background process a short time window to be observable
    local found=0
    for _ in $(seq 1 10); do
        if [ -d "/proc/$pid_line" ]; then
            found=1
            break
        fi
        sleep 0.05
    done

    if [ "$found" -eq 1 ]; then
        log_success "PID $pid_line exists in /proc (background process observed)"
        rm -f "$temp_input" "$temp_output"
        return 0
    else
        log_warn "/proc/$pid_line not observed; command may have exited quickly"
        # Still consider this a failure for this specific check
        log_error "sleep 1 & did not show a live PID in the observation window"
        log_info "Output preview: $(head -n 6 "$temp_output" | tr '\n' ' ') ..."
        rm -f "$temp_input" "$temp_output"
        return 1
    fi
}

# Test 3: Optional job info line like: [<job_id>] <pgid>
test_job_info_line() {
    log_section "測試 3: 背景工作資訊行格式 ([job_id] pgid)"

    local temp_input
    local temp_output
    temp_input=$(mktemp)
    temp_output=$(mktemp)

    cat > "$temp_input" << 'EOF'
sleep 1 &
exit
EOF

    log_info "Running: sleep 1 & (with exit) to check job info line"
    timeout $TIMEOUT "$SHELL_BINARY" < "$temp_input" > "$temp_output" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_error "Job info test timed out after ${TIMEOUT}s"
        rm -f "$temp_input" "$temp_output"
        return 1
    fi

    # Example expected: "[1] 12345"
    if grep -Eq '^\[[0-9]+\] [0-9]+$' "$temp_output"; then
        log_success "Found job info line like: [<job_id>] <pgid>"
        rm -f "$temp_input" "$temp_output"
        return 0
    else
        log_warn "Job info line not found; shell may not print job metadata"
        log_info "This is optional for the specific requirement, but recommended."
        log_info "Actual output:"
        sed 's/^/  > /' "$temp_output"
        rm -f "$temp_input" "$temp_output"
        # Do not hard-fail here if strictly testing only PID printing. To be strict, return 1.
        return 0
    fi
}

# Main execution
main() {
    log_section "背景執行 ( & ) 測試開始"
    log_info "Testing shell binary: $SHELL_BINARY"

    local total_tests=0
    local passed_tests=0

    check_shell_binary

    # Test 1: ls & prints PID
    total_tests=$((total_tests + 1))
    if test_ls_background; then
        passed_tests=$((passed_tests + 1))
    fi

    # Test 2: sleep 1 & PID exists briefly
    total_tests=$((total_tests + 1))
    if test_sleep_background_pid_exists; then
        passed_tests=$((passed_tests + 1))
    fi

    # Test 3: job info line (optional)
    total_tests=$((total_tests + 1))
    if test_job_info_line; then
        passed_tests=$((passed_tests + 1))
    fi

    log_section "測試結果總結"
    echo -e "通過測試: ${GREEN}$passed_tests${NC}/$total_tests"

    if [ $passed_tests -eq $total_tests ]; then
        log_success "背景執行相關測試全部通過！"
        exit 0
    else
        log_error "部分測試失敗，請檢查 shell 的背景執行實作"
        exit 1
    fi
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi


