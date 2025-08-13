# Two Process Pipelines Test

## 測試目的
測試 shell 的雙行程管道功能，包括：

1. **基本管道執行**: `command1 | command2` 語法
2. **數據流轉**: 第一個行程的輸出正確傳遞給第二個行程
3. **特定測試案例**: 
   - `cat text.txt | head -1` - 取第一行
   - `cat text.txt | tail -2` - 取最後兩行

## 目錄結構
```
02_pipelines/
├── README.md           # 此說明文件
├── scripts/
│   └── test_pipelines.sh    # 主要測試腳本
├── test_data/
│   └── text.txt        # 測試用文本文件
└── expected/           # (保留給未來擴展)
```

## 測試資料
### text.txt 內容
```
Hello world
A shell interprets user commands into system calls
The shell parses input using tokenization
Custom shells often rely on `fork()` and `exec()` for execution
I/O redirection lets users manage data streams
Shells often support pipelines for command chaining
```

## 執行測試
### 前置準備

1. 確保 shell 已編譯完成：
   ```bash
   cd ~/OS-Simple-Shell
   make
   ```

2. 確認 `my_shell` 執行檔存在且可執行。

### 執行測試腳本
#### 方式 A
```bash
cd ~/OS-Simple-Shell

# 執行管道測試
./simple_tests/run_test.sh 02_pipelines
```

#### 方式 B
```bash
# 進入測試腳本目錄
cd ~/OS-Simple-Shell/simple_tests/02_pipelines/scripts

# 執行測試
./test_pipelines.sh
```

### 測試輸出說明
測試腳本會使用顏色標記來顯示結果：

- **🔵 [INFO]**: 一般資訊和進度更新
- **🟡 [WARN]**: 警告訊息 (命令返回非零退出碼但可能仍正常)
- **🟢 [PASS]**: 測試通過
- **🔴 [FAIL]**: 測試失敗

## 預期行為和驗證方法

### 測試 1: cat text.txt | head -1

**命令**: `cat text.txt | head -1`

**預期輸出**: 
```
Hello world
```

**驗證方法**: 
- 檢查輸出是否包含 "Hello world"
- 確認只有第一行被輸出

### 測試 2: cat text.txt | tail -2

**命令**: `cat text.txt | tail -2`

**預期輸出**:
```
I/O redirection lets users manage data streams
Shells often support pipelines for command chaining
```

**驗證方法**: 
- 檢查輸出是否包含倒數第二行: "I/O redirection lets users manage data streams"
- 檢查輸出是否包含最後一行: "Shells often support pipelines for command chaining"

### 測試 3: 基本管道功能

**命令**: `echo hello | cat`

**預期輸出**: 
```
hello
```

**驗證方法**: 
- 檢查最基本的管道功能是否正常
- 確認數據能夠在行程間正確傳遞

### 測試 4: 管道後退出功能

**測試序列**:
```
echo test | cat
exit
```

**驗證方法**: 
- 確認管道執行後 shell 仍能正常處理 exit 命令
- 驗證 shell 正確退出

## 手動測試

如果需要手動驗證，可以直接執行 shell：

```bash
cd ~/OS-Simple-Shell
./my_shell
```

然後手動輸入以下命令：

```bash
# 進入測試資料目錄
cd simple_tests/02_pipelines/test_data

# 測試第一個管道
cat text.txt | head -1
# 預期看到: Hello world

# 測試第二個管道  
cat text.txt | tail -2
# 預期看到最後兩行

# 測試基本管道
echo hello | cat
# 預期看到: hello

help | tail -3
# 預期看到: help 輸出指令的最後三行

echo 300 | grep 3
# 預期看到: 300

# 退出
exit
```

## 管道實作要點

這個測試驗證 shell 是否正確實作了：

1. **行程創建**: 能夠創建兩個子行程
2. **管道建立**: 使用 `pipe()` 系統調用創建管道
3. **文件描述符重導向**: 
   - 第一個行程的 stdout 連接到管道的寫端
   - 第二個行程的 stdin 連接到管道的讀端
4. **行程同步**: 父行程正確等待兩個子行程完成
5. **資源清理**: 正確關閉不需要的文件描述符

## 故障排除

### 常見問題

1. **"Shell binary not found"**
   - 確認是否已執行 `make` 編譯
   - 檢查 `my_shell` 檔案是否存在

2. **測試超時**
   - 可能管道實作有死鎖問題
   - 檢查文件描述符是否正確關閉

3. **輸出不正確**
   - 檢查管道的讀寫端連接是否正確
   - 確認 `fork()` 和 `exec()` 的順序

4. **行程不結束**
   - 可能沒有正確關閉管道的文件描述符
   - 檢查父行程是否正確等待子行程

### 偵錯建議

1. **查看詳細輸出**: 
   ```bash
   ./test_pipelines.sh 2>&1 | tee pipeline_test_log.txt
   ```

2. **手動測試簡單管道**:
   ```bash
   echo "echo hello | cat" | ./my_shell
   ```

3. **檢查行程狀態**:
   ```bash
   # 在另一個終端監控行程
   ps aux | grep my_shell
   ```

4. **檢查文件描述符**:
   ```bash
   # 如果 shell 掛起，檢查是否有未關閉的文件描述符
   lsof -p <shell_pid>
   ```

## 預期測試結果

如果 shell 的管道功能實作正確，應該看到：

```
=== 雙進程管道測試開始 ===
[INFO] Testing shell binary: /home/yucskr/OS-Simple-Shell/my_shell
[INFO] Test data directory: ../test_data

=== 環境檢查 ===
[PASS] Shell binary found and executable

=== 測試 1: cat text.txt | head -1 ===
[INFO] Testing pipeline: cat text.txt | head -1
[INFO] Expected output: "Hello world"
[PASS] Pipeline 'cat text.txt | head -1' executed successfully
[INFO] Actual output contains expected: "Hello world"

=== 測試 2: cat text.txt | tail -2 ===
[INFO] Testing pipeline: cat text.txt | tail -2
[INFO] Expected output (line 1): "I/O redirection lets users manage data streams"
[INFO] Expected output (line 2): "Shells often support pipelines for command chaining"
[PASS] Output contains expected line 1
[PASS] Output contains expected line 2
[PASS] Pipeline 'cat text.txt | tail -2' executed successfully

=== 測試 3: 基本管道功能檢查 ===
[INFO] Testing basic pipeline functionality with: echo hello | cat
[PASS] Basic pipeline functionality works

=== 測試 4: 管道命令後的退出功能 ===
[INFO] Testing pipeline followed by exit command
[PASS] Pipeline followed by exit works correctly

=== 測試結果總結 ===
通過測試: 4/4
[PASS] 所有雙進程管道測試通過！
```
