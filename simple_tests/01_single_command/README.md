# 單一進程命令測試 (Single Process Command Test)

## 測試目的

測試 shell 的基本單一進程命令執行功能，包括：

1. **基本命令執行**: `ls`, `cat`, `whoami`, `pwd`
2. **空行處理**: 只包含空格或 tab 字符的輸入行應該被忽略
3. **退出功能**: `exit` 命令應該正常結束 shell

## 目錄結構

```
01_single_command/
├── README.md           # 此說明文件
├── scripts/
│   └── test_single_command.sh  # 主要測試腳本
├── test_data/
│   ├── text.txt        # 測試用文本文件
│   └── commands.txt    # 測試命令列表
└── expected/           # (保留給未來擴展)
```

## 執行測試

### 前置準備

1. 確保 shell 已編譯完成：
   ```bash
   cd OS-Simple-Shell
   make
   ```

2. 確認 `my_shell` 執行檔存在且可執行。

### 執行測試腳本

```bash
# 進入測試腳本目錄
cd simple_tests/01_single_command/scripts

# 執行測試
./test_single_command.sh
```

### 測試輸出說明

測試腳本會使用顏色標記來顯示結果：

- **🔵 [INFO]**: 一般資訊
- **🟡 [WARN]**: 警告訊息
- **🟢 [PASS]**: 測試通過
- **🔴 [FAIL]**: 測試失敗

### 預期行為

#### 測試 1: 基本命令執行
- `ls`: 應顯示當前目錄檔案列表，包含 `text.txt`
- `pwd`: 應顯示當前工作目錄路徑
- `whoami`: 應顯示當前使用者名稱
- `cat text.txt`: 應顯示檔案內容，包含 "Hello world" 等文字

#### 測試 2: 空行處理
- 輸入只包含空格或 tab 的行時，shell 應該：
  - 不執行任何操作
  - 繼續顯示 prompt
  - 不產生錯誤訊息

#### 測試 3: Exit 命令
- `exit` 命令應該：
  - 正常結束 shell 程序
  - 返回適當的退出碼 (通常是 0)

## 手動測試

如果需要手動測試，可以直接執行 shell：

```bash
cd OS-Simple-Shell
./my_shell
```

然後手動輸入以下命令進行驗證：

```bash
# 測試基本命令
ls
pwd
whoami
cat simple_tests/01_single_command/test_data/text.txt

# 測試空行處理 (輸入幾個只有空格的行)
   
	

# 測試退出
exit
```

## 故障排除

### 常見問題

1. **"Shell binary not found"**
   - 確認是否已執行 `make` 編譯
   - 檢查 `my_shell` 檔案是否存在

2. **測試超時**
   - 可能 shell 在等待輸入時沒有正確處理
   - 檢查 shell 的 prompt 實作

3. **命令執行失敗**
   - 檢查 shell 的 `fork()` 和 `exec()` 實作
   - 確認環境變數 PATH 設定正確

### 偵錯建議

1. **查看詳細輸出**: 
   ```bash
   ./test_single_command.sh 2>&1 | tee test_log.txt
   ```

2. **手動執行有問題的命令**:
   ```bash
   echo "ls" | ./my_shell
   ```

3. **檢查 shell 的錯誤輸出**:
   ```bash
   ./my_shell 2> error.log
   ```

## 預期測試結果
如果 shell 的單一進程命令執行功能實作正確，應該看到：
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