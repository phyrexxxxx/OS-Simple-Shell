# Simple Shell Tests - 簡潔功能測試框架

## 概述

這是一個全新的、簡潔明瞭的 shell 功能測試框架，專門設計來取代複雜的 `tests/` 目錄。每個測試專注於測試一個特定功能，讓開發者能夠快速理解和驗證 shell 的各項能力。

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
└── (未來測試...)
    ├── 02_pipelines/          # 管道測試
    ├── 03_redirection/        # 重導向測試
    ├── 04_background/         # 背景執行測試
    └── ...
```

## 快速開始

### 1. 編譯 Shell

```bash
cd /home/yucskr/OS-Simple-Shell
make
```

### 2. 執行測試

有兩種方式執行測試：

#### 方式 A: 使用快速執行器 (推薦)

```bash
# 查看可用測試
./simple_tests/run_test.sh

# 執行特定測試
./simple_tests/run_test.sh 01_single_command
```

#### 方式 B: 直接執行測試腳本

```bash
cd simple_tests/01_single_command/scripts
./test_single_command.sh
```

## 目前可用測試

### 01_single_command - 單一進程命令測試

**測試內容:**
- 基本命令執行 (`ls`, `cat`, `whoami`, `pwd`)
- 空行處理 (只有空格/tab 的輸入)
- `exit` 命令功能

**執行方式:**
```bash
./simple_tests/run_test.sh 01_single_command
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
[INFO] Testing shell binary: ../../my_shell
[INFO] Test data directory: ../test_data

=== 環境檢查 ===
[PASS] Shell binary found and executable

=== 測試 1: 基本命令執行 ===
[INFO] Testing command: ls
[PASS] ls command executed successfully
[INFO] Testing command: pwd
[PASS] pwd command executed successfully
...

=== 測試結果總結 ===
通過測試: 3/3
[PASS] 所有單一進程命令測試通過！
```

## 擴展測試框架

### 添加新測試

1. **創建測試目錄**:
   ```bash
   mkdir -p simple_tests/02_new_feature/{scripts,test_data,expected}
   ```

2. **創建測試腳本**:
   - 複製 `01_single_command/scripts/test_single_command.sh` 作為範本
   - 修改函數名稱和測試邏輯
   - 保持相同的顏色標記和日誌格式

3. **添加測試資料**:
   - 在 `test_data/` 目錄放置所需的測試檔案
   - 在 `expected/` 目錄放置預期輸出 (如果需要)

4. **創建說明文件**:
   - 複製並修改 `README.md`
   - 說明測試目的、執行方式和預期行為

### 測試腳本開發指南

#### 必要函數結構

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

#### 最佳實踐

1. **使用 timeout**: 避免測試無限等待
2. **清理暫存檔**: 測試後清理 temp files
3. **詳細日誌**: 提供足夠的除錯資訊
4. **錯誤處理**: 適當處理各種錯誤情況
5. **可讀性**: 代碼註解清楚，函數命名有意義

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

## 與舊測試系統的差異

| 特性 | 舊 tests/ | 新 simple_tests/ |
|------|-----------|------------------|
| 複雜度 | 高，難以理解 | 低，一目了然 |
| 功能分離 | 混合測試多功能 | 一個測試一個功能 |
| 日誌格式 | 基本輸出 | 彩色標記，清晰分類 |
| 文檔 | 有限 | 每個測試都有完整說明 |
| 擴展性 | 複雜 | 容易添加新測試 |
| 除錯 | 困難 | 提供詳細除錯資訊 |

這個新的測試框架讓你能夠：
- **快速驗證**: 單一功能測試，問題定位更精確
- **容易理解**: 清晰的結構和豐富的註解
- **輕鬆擴展**: 標準化的模板，容易添加新測試
- **有效除錯**: 詳細的日誌和錯誤訊息
