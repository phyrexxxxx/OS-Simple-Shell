# Comprehensive Features Test
## 測試目的

測試 shell 的綜合功能，整合驗證多種特性的組合使用：

1. **背景執行 + I/O 重導向**：`cat < t1.txt > t2.txt &`
2. **背景執行 + 管線 + 輸出重導向**：`cat text.txt | head -c 32 > t2.txt &`
3. **複雜多重管線背景執行**：`cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt &`

這些測試案例涵蓋了 shell 的核心功能組合，確保各功能之間能夠正確協作。

## 目錄結構

```
06_comprehensive/
├── README.md                     # 此說明文件
├── scripts/
│   └── test_comprehensive.sh     # 主要測試腳本
└── test_data/
    └── text.txt                  # 測試用文本文件
```

## 測試資料

### 基礎檔案 (text.txt)
```
Hello world
A shell interprets user commands into system calls
The shell parses input using tokenization
Custom shells often rely on `fork()` and `exec()` for execution
I/O redirection lets users manage data streams
Shells often support pipelines for command chaining
```

### 測試過程檔案
- `t1.txt`：測試期間由 `text.txt` 複製產生
- `t2.txt`：各測試案例的輸出檔案
- 所有暫存檔案會在測試完成後自動清理

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
cd /home/yucskr/OS-Simple-Shell

# 執行綜合功能測試
./simple_tests/run_test.sh 06_comprehensive
```

#### 方式 B

```bash
# 進入測試腳本目錄
cd ~/OS-Simple-Shell/simple_tests/06_comprehensive/scripts

# 執行測試
./test_comprehensive.sh
```

### 測試輸出說明

測試腳本會使用顏色標記來顯示結果：

- **🔵 [INFO]**: 一般資訊和進度更新
- **🟡 [WARN]**: 警告訊息（命令返回非零退出碼但可能仍正常）
- **🟢 [PASS]**: 測試通過
- **🔴 [FAIL]**: 測試失敗

## 預期行為和驗證方法

### 測試 1: 背景執行 + I/O 重導向

**命令**：`cat < t1.txt > t2.txt &`

**預期行為**：
- shell 印出背景子行程的 PID
- 背景程序將 `t1.txt` 的內容重導向到 `t2.txt`
- `t2.txt` 內容應與 `t1.txt` 完全相同

**驗證方法**：
- 檢查 PID 輸出
- 等待背景程序完成，檢查 `t2.txt` 是否創建
- 使用 `diff` 比較 `t1.txt` 和 `t2.txt` 的內容

### 測試 2: 背景執行 + 管線 + 輸出重導向

**命令**：`cat text.txt | head -c 32 > t2.txt &`

**預期行為**：
- shell 印出背景管線最右側命令（`head`）的 PID
- 背景程序將 `text.txt` 的前 32 個字元寫入 `t2.txt`
- `t2.txt` 檔案大小應正好為 32 字元

**驗證方法**：
- 檢查 PID 輸出
- 等待背景程序完成，檢查 `t2.txt` 是否創建
- 驗證 `t2.txt` 檔案大小為 32 字元

### 測試 3: 複雜多重管線背景執行

**命令**：`cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt &`

**預期行為**：
- shell 印出背景管線最右側命令（`grep`）的 PID
- 處理流程：讀取 `t1.txt` → 取前 5 行 → 取後 3 行 → 篩選包含 "shell" 的行
- `t2.txt` 應包含兩行內容：
  - `The shell parses input using tokenization`
  - `Custom shells often rely on \`fork()\` and \`exec()\` for execution`

**驗證方法**：
- 檢查 PID 輸出（應為最右側 `grep` 命令的 PID）
- 等待背景程序完成，檢查 `t2.txt` 是否創建
- 驗證 `t2.txt` 包含預期的兩行內容

## 手動測試

如果需要手動驗證，可以直接執行 shell：

```bash
cd ~/OS-Simple-Shell
./my_shell
```

然後手動輸入以下命令序列：

```bash
# 進入測試資料目錄
cd ~/OS-Simple-Shell/simple_tests/06_comprehensive/test_data

# 準備測試檔案
cp text.txt t1.txt

# 測試 1: 背景 I/O 重導向
cat < t1.txt > t2.txt &
# 預期：印出 PID，等待完成後檢查 t2.txt

# 等待背景程序完成
sleep 1
cat t2.txt
# 預期：內容與 t1.txt 相同

# 測試 2: 背景管線 + 重導向
cat text.txt | head -c 32 > t2.txt &
# 預期：印出 PID

# 等待完成並檢查
sleep 1
wc -c t2.txt
# 預期：32 個字元

# 測試 3: 複雜多重管線
cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt &
# 預期：印出 PID

# 等待完成並檢查
sleep 1
cat t2.txt
# 預期：包含兩行 shell 相關內容

# 清理
rm t1.txt t2.txt

# 退出
exit
```

## 實作要點

此測試驗證以下綜合實作面向：

1. **多功能解析整合**：同時處理 `<`、`>`、`|`、`&` 符號
2. **背景程序管理**：正確印出最右側命令的 PID
3. **文件描述符管理**：在複雜管線中正確設定重導向
4. **程序同步**：背景程序能正確完成而不影響前景操作
5. **資源清理**：暫存檔案和文件描述符的正確管理

## 故障排除

### 常見問題

1. **PID 輸出問題**
   - 檢查背景執行實作是否正確印出最右側命令的 PID
   - 確認 PID 輸出格式符合預期

2. **輸出檔案未創建**
   - 檢查重導向實作是否正確
   - 確認背景程序有足夠時間完成執行

3. **管線連接問題**
   - 驗證多段管線的文件描述符連接
   - 檢查每個命令是否正確執行

4. **內容不匹配**
   - 確認 `head`、`tail`、`grep` 等命令的參數解析
   - 檢查管線中的資料流是否正確傳遞

### 偵錯建議

1. **查看詳細輸出**：
   ```bash
   ./simple_tests/06_comprehensive/scripts/test_comprehensive.sh 2>&1 | tee comprehensive_test_log.txt
   ```

2. **手動測試單個組件**：
   ```bash
   # 測試基本重導向
   echo "cat < text.txt > test_out.txt" | ./my_shell
   
   # 測試基本管線
   echo "cat text.txt | head -5" | ./my_shell
   ```

3. **檢查暫存檔案**：
   ```bash
   # 在測試目錄查看生成的檔案
   ls -la simple_tests/03_redirection/test_data/
   ```

## 預期測試結果

如果 shell 的綜合功能實作正確，應該看到：

```
=== 綜合功能測試開始 ===
[INFO] Testing shell binary: /home/yucskr/OS-Simple-Shell/my_shell
[INFO] Using test data dir: /home/yucskr/OS-Simple-Shell/simple_tests/03_redirection/test_data

=== 環境檢查 ===
[PASS] Shell binary found and executable

=== 測試 1: 背景執行 + I/O 重導向 (cat < t1.txt > t2.txt &) ===
[INFO] Running: cat < t1.txt > t2.txt & (with exit)
[PASS] Found background PID printed: 30306
[PASS] t2.txt content matches t1.txt (I/O redirection successful)

=== 測試 2: 背景執行 + 管線 + 輸出重導向 (cat text.txt | head -c 32 > t2.txt &) ===
[INFO] Running: cat text.txt | head -c 32 > t2.txt & (with exit)
[PASS] Found background PID printed: 30323
[PASS] t2.txt has exactly 32 characters (head -c 32 successful)
[INFO] t2.txt content: Hello world A shell interprets u

=== 測試 3: 複雜多重管線背景執行 (cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt &) ===
[INFO] Running: cat < t1.txt | head -5 | tail -3 | grep shell > t2.txt & (with exit)
[PASS] Found background PID printed (rightmost command): 30348
[PASS] Output contains expected line: The shell parses input using tokenization
[PASS] Output contains expected line: Custom shells often rely on `fork()` and `exec()` for execution
[INFO] t2.txt content:
  > The shell parses input using tokenization
  > Custom shells often rely on `fork()` and `exec()` for execution

=== 測試結果總結 ===
通過測試: 3/3
[PASS] 所有綜合功能測試通過！
```
