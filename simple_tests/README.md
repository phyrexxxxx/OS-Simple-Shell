# Simple Shell Tests
## 概述
這是一個簡潔明瞭的 shell 功能測試框架。每個測試專注於測試一個特定功能，讓開發者能夠快速理解和驗證 shell 的各項能力。

## 設計原則
1. **一個功能一個測試**: 每個測試目錄只測試一個特定功能
2. **清晰的結構**: 標準化的目錄結構，易於理解和擴展
3. **詳細的日誌**: 使用顏色標記和清晰的訊息格式
4. **自動化驗證**: 腳本自動驗證輸出並報告結果
5. **良好的文檔**: 每個測試都有完整的說明文件

## 目錄結構
```
simple_tests/
├── README.md                   # 此總覽文件
├── run_test.sh                 # 快速測試執行器
│
├── 01_single_command/          # 單一進程命令測試
│   ├── README.md              # 測試說明
│   ├── scripts/
│   │   └── test_single_command.sh
│   ├── test_data/
│   │   ├── text.txt
│   │   └── commands.txt
│   └── expected/              # (未來擴展用)
│
├── 02_pipelines/              # 管道測試
│   ├── README.md              # 測試說明
│   ├── scripts/
│   │   └── test_pipelines.sh
│   └── test_data/
│       └── text.txt
│
├── 03_redirection/            # 重導向測試
│   ├── README.md              # 測試說明
│   ├── scripts/
│   │   └── test_redirection.sh
│   └── test_data/
│       └── text.txt
│
├── 04_background/             # 背景執行測試
│   ├── README.md              # 測試說明
│   └── scripts/
│       └── test_background.sh
│
├── 05_multi_pipelines/        # 多重管道測試
│   ├── README.md              # 測試說明
│   ├── scripts/
│   │   └── test_multi_pipelines.sh
│   └── test_data/
│       └── text.txt
│
└── 06_comprehensive/          # 綜合功能測試
    ├── README.md              # 測試說明
    ├── scripts/
    │   └── test_comprehensive.sh
    └── test_data/
        └── text.txt
```

## 快速開始
### 1. 編譯 Shell
```bash
cd ~/OS-Simple-Shell
make
```

### 2. 執行測試
有兩種方式執行測試：

#### 方式 A
```bash
# 查看可用測試
./simple_tests/run_test.sh

# 執行特定測試
./simple_tests/run_test.sh 01_single_command
```

#### 方式 B
```bash
cd simple_tests/01_single_command/scripts
./test_single_command.sh
```

## 測試輸出說明
所有測試腳本使用統一的顏色標記系統：

- 🔵 **[INFO]** - 一般資訊和進度更新
- 🟡 **[WARN]** - 警告訊息 (不一定是錯誤)
- 🟢 **[PASS]** - 測試通過
- 🔴 **[FAIL]** - 測試失敗

### 範例輸出
```
=== 單一進程命令測試開始 ===
[INFO] Testing shell binary: /home/yucskr/OS-Simple-Shell/my_shell
[INFO] Test data directory: ../test_data

=== 環境檢查 ===
[PASS] Shell binary found and executable

=== 測試 1: 基本命令執行 ===
[INFO] Testing command: ls
[PASS] ls command executed successfully
[INFO] Output preview: commands.txt text.txt :/home/yucskr/OS-Simple-Shell/simple_tests/01_single_command/test_data >>> $ :/home/yucskr/OS-Simple-Shell/simple_tests/01_single_command/test_data >>> $ ...
[INFO] Testing command: pwd
[PASS] pwd command executed successfully
[INFO] Output preview: /home/yucskr/OS-Simple-Shell/simple_tests/01_single_command/test_data :/home/yucskr/OS-Simple-Shell/simple_tests/01_single_command/test_data >>> $ :/home/yucskr/OS-Simple-Shell/simple_tests/01_single_command/test_data >>> $ ...
[INFO] Testing command: whoami
[PASS] whoami command executed successfully
[INFO] Output preview: yucskr :/home/yucskr/OS-Simple-Shell/simple_tests/01_single_command/test_data >>> $ :/home/yucskr/OS-Simple-Shell/simple_tests/01_single_command/test_data >>> $ ...
[INFO] Testing command: cat text.txt
[PASS] cat command executed successfully
[INFO] Output preview: Hello world A shell interprets user commands into system calls The shell parses input using tokenization ...
[PASS] Basic commands test PASSED

=== 測試 2: 空行處理 (只有空格/Tab的行) ===
[INFO] Testing empty line handling...
[PASS] Shell correctly handles empty lines and continues execution

=== 測試 3: Exit 命令 ===
[INFO] Testing exit command...
[PASS] Exit command works correctly

=== 測試結果總結 ===
通過測試: 3/3
[PASS] 所有單一進程命令測試通過！
```

## 測試腳本開發指南
### 必要函數結構

```bash
#!/bin/bash

# Color definitions (使用標準顏色定義)
RED='\033[0;31m'
GREEN='\033[0;32m'
# ... 其他顏色

# Utility functions (使用標準工具函數)
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }

# Test functions
test_feature_1() {
    log_section "測試 1: 功能描述"
    # 測試邏輯
    return 0  # 成功時返回 0
}

# Main function
main() {
    log_section "測試開始"
    # 執行所有測試
    # 計算通過率
    # 顯示最終結果
}

main "$@"
```

## 故障排除
### 常見問題

1. **Permission denied**: 確保測試腳本有執行權限
   ```bash
   chmod +x simple_tests/*/scripts/*.sh
   ```

2. **Shell not found**: 確保已編譯 shell
   ```bash
   make clean && make
   ```

3. **測試超時**: 檢查 shell 是否正確處理輸入/輸出

### 偵錯技巧

1. **查看完整日誌**:
   ```bash
   ./simple_tests/run_test.sh 01_single_command 2>&1 | tee debug.log
   ```

2. **手動測試有問題的命令**:
   ```bash
   echo "ls" | ./my_shell
   ```

3. **檢查測試資料**:
   ```bash
   cat simple_tests/01_single_command/test_data/text.txt
   ```
