# I/O 重導向測試 (Input and Output Redirection Test)
## 測試目的

測試 shell 的 I/O 重導向功能，包括：

1. **輸入重導向**: `cat < text.txt` - 從檔案讀取輸入
2. **輸出重導向**: `cat text.txt > out_test.txt` - 將輸出寫入檔案
3. **檔案創建**: 輸出重導向自動創建不存在的檔案
4. **內容驗證**: 重導向的輸出內容正確性檢查

## 目錄結構
```
03_redirection/
├── README.md               # 此說明文件
├── scripts/
│   └── test_redirection.sh # 主要測試腳本
├── test_data/
│   └── text.txt           # 測試用文本文件
└── expected/              # (保留給未來擴展)
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

# 執行 I/O 重導向測試
./simple_tests/run_test.sh 03_redirection
```

#### 方式 B

```bash
# 進入測試腳本目錄
cd ~/OS-Simple-Shell/simple_tests/03_redirection/scripts

# 執行測試
./test_redirection.sh
```

### 測試輸出說明

測試腳本會使用顏色標記來顯示結果：

- **🔵 [INFO]**: 一般資訊和進度更新
- **🟡 [WARN]**: 警告訊息 (命令返回非零退出碼但可能仍正常)
- **🟢 [PASS]**: 測試通過
- **🔴 [FAIL]**: 測試失敗

## 預期行為和驗證方法

### 測試 1: 輸入重導向 (cat < text.txt)

**命令**: `cat < text.txt`

**預期行為**: 
- shell 將 `text.txt` 的內容重導向為 `cat` 命令的標準輸入
- 輸出應該與直接執行 `cat text.txt` 相同

**驗證方法**: 
- 檢查輸出是否包含 "Hello world"
- 檢查輸出是否包含 "A shell interprets user commands into system calls"
- 檢查輸出是否包含 "The shell parses input using tokenization"

### 測試 2: 輸出重導向 (cat text.txt > out_test.txt)

**命令**: `cat text.txt > out_test.txt`

**預期行為**:
- shell 將 `cat text.txt` 的輸出重導向到 `out_test.txt` 檔案
- 如果 `out_test.txt` 不存在，自動創建該檔案
- 檔案內容應該與原始 `text.txt` 完全相同

**驗證方法**: 
- 檢查 `out_test.txt` 檔案是否被創建
- 使用 `diff` 比較原始檔案和輸出檔案的內容
- 確認兩個檔案的行數相同

### 測試 3: 輸出重導向檔案創建功能

**命令**: `echo 'test content' > new_created_file.txt`

**預期行為**:
- shell 創建一個新檔案 `new_created_file.txt`
- 檔案包含指定的內容 "test content"

**驗證方法**: 
- 確認檔案被成功創建
- 檢查檔案內容是否正確

### 測試 4: 綜合重導向功能

**測試序列**:
```bash
echo 'line1' > temp_file.txt
echo 'line2' >> temp_file.txt
echo 'line3' >> temp_file.txt
cat < temp_file.txt > final_output.txt
```

**預期行為**:
- 測試多種重導向操作的組合
- 驗證 shell 能正確處理複雜的重導向場景

**驗證方法**: 
- 檢查最終輸出檔案內容是否包含所有預期行

## 手動測試
如果需要手動驗證，可以直接執行 shell：

```bash
cd ~/OS-Simple-Shell
./my_shell
```

然後手動輸入以下命令：

```bash
# 進入測試資料目錄
cd simple_tests/03_redirection/test_data

# 測試輸入重導向
cat < text.txt
# 預期看到: text.txt 的完整內容

# 測試輸出重導向
cat text.txt > out_test.txt
ls -la out_test.txt
# 預期看到: 檔案被創建

# 檢查輸出檔案內容
cat out_test.txt
# 預期看到: 與原始 text.txt 相同的內容

# 清理測試檔案
rm out_test.txt

# 退出
exit
```

## I/O 重導向實作要點

這個測試驗證 shell 是否正確實作了：

1. **語法解析**: 正確識別 `<` 和 `>` 重導向符號
2. **檔案操作**: 
   - 輸入重導向: 打開檔案用於讀取
   - 輸出重導向: 創建或覆蓋檔案用於寫入
3. **文件描述符重導向**: 
   - 輸入重導向: 將檔案描述符連接到 stdin (0)
   - 輸出重導向: 將檔案描述符連接到 stdout (1)
4. **進程執行**: 在設定重導向後正確執行命令
5. **資源管理**: 正確關閉打開的檔案描述符

## 故障排除

### 常見問題

1. **"Shell binary not found"**
   - 確認是否已執行 `make` 編譯
   - 檢查 `my_shell` 檔案是否存在

2. **輸入重導向失敗**
   - 檢查檔案是否存在且可讀取
   - 確認重導向語法解析正確

3. **輸出重導向失敗**
   - 檢查檔案權限，確保可以創建/寫入檔案
   - 確認 stdout 重導向實作正確

4. **檔案內容不匹配**
   - 可能存在緩衝區問題，檢查是否正確刷新輸出
   - 確認重導向在 `exec()` 之前正確設定

### 偵錯建議

1. **查看詳細輸出**: 
   ```bash
   ./test_redirection.sh 2>&1 | tee redirection_test_log.txt
   ```

2. **手動測試簡單重導向**:
   ```bash
   echo "cat < simple_tests/03_redirection/test_data/text.txt" | ./my_shell
   ```

3. **檢查檔案權限**:
   ```bash
   ls -la simple_tests/03_redirection/test_data/
   ```

4. **檢查 shell 錯誤輸出**:
   ```bash
   echo "cat text.txt > test_output.txt" | ./my_shell 2> error.log
   cat error.log
   ```

5. **監控檔案操作**:
   ```bash
   # 在另一個終端監控檔案變化
   watch -n 1 'ls -la simple_tests/03_redirection/test_data/'
   ```

## 預期測試結果

如果 shell 的 I/O 重導向功能實作正確，應該看到：

```
=== I/O 重導向測試開始 ===
[INFO] Testing shell binary: /home/yucskr/OS-Simple-Shell/my_shell
[INFO] Test data directory: ../test_data

=== 環境檢查 ===
[PASS] Shell binary found and executable

=== 測試 1: 輸入重導向 (cat < text.txt) ===
[INFO] Testing input redirection: cat < text.txt
[INFO] Expected: same content as 'cat text.txt'
[PASS] Output contains expected line: "Hello world"
[PASS] Output contains expected line: "A shell interprets user commands into system calls"
[PASS] Output contains expected line: "The shell parses input using tokenization"
[PASS] Input redirection 'cat < text.txt' executed successfully

=== 測試 2: 輸出重導向 (cat text.txt > out_test.txt) ===
[INFO] Testing output redirection: cat text.txt > out_test.txt
[INFO] Expected: creates out_test.txt with same content as text.txt
[PASS] Output file 'out_test.txt' was created successfully
[PASS] Output redirection content verification: Files match exactly
[PASS] Output redirection 'cat text.txt > out_test.txt' executed successfully
[INFO] Original file lines: 6, Output file lines: 6

=== 測試 3: 輸出重導向文件創建功能 ===
[INFO] Testing file creation: echo 'test content' > new_created_file.txt
[INFO] Expected: creates new file with specified content
[PASS] New file 'new_created_file.txt' was created successfully
[PASS] File creation with correct content verified

=== 測試 4: 綜合重導向功能測試 ===
[INFO] Testing combined functionality: input and output redirection together
[PASS] Final output contains expected line: "Hello world"
[PASS] Final output contains expected line: "A shell interprets user commands into system calls"
[PASS] Final output contains expected line: "I/O redirection lets users manage data streams"
[PASS] Combined redirection functionality works correctly

=== 測試結果總結 ===
通過測試: 4/4
[PASS] 所有 I/O 重導向測試通過！
```
