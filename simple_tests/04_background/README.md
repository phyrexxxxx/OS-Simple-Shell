# 背景執行測試 (Background Execution Test)
## 測試目的

測試 shell 的背景執行功能：

1. **背景執行**: `ls &` 應在父行程（shell）印出背景子行程的 PID
2. **短暫存活驗證**: `sleep 1 &` 所印出的 PID 在短時間內應可於 `/proc/<PID>` 查到
3. **工作資訊行**: 印出 `[<job_id>] <pgid>` 的工作資訊

## 目錄結構
```
04_background/
├── README.md                # 此說明文件
├── scripts/
│   └── test_background.sh   # 主要測試腳本
└── expected/                # (保留給未來擴展)
```

> 本測試不需要額外的測試資料檔案，直接使用系統指令（如 `ls`, `sleep`）。

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

# 執行背景執行測試
./simple_tests/run_test.sh 04_background
```

#### 方式 B

```bash
# 進入測試腳本目錄
cd ~/OS-Simple-Shell/simple_tests/04_background/scripts

# 執行測試
./test_background.sh
```

### 測試輸出說明

測試腳本會使用顏色標記來顯示結果：

- **🔵 [INFO]**: 一般資訊和進度更新
- **🟡 [WARN]**: 警告訊息（例如命令返回非零退出碼但可能仍正常）
- **🟢 [PASS]**: 測試通過
- **🔴 [FAIL]**: 測試失敗

## 預期行為和驗證方法

### 測試 1: 背景執行 PID 輸出（ls &）

**命令**: `ls &`

**預期行為**:
- shell 應印出一行「僅數字」的 PID（背景子行程的 PID）
- 有些實作同時會印出一行工作資訊，如 `[1] 12345`（選配）

**驗證方法**:
- 檢查輸出中是否有數字 PID 行（或提示字元後方的最後一個欄位為數字 PID）

### 測試 2: 背景 PID 存活性（sleep 1 &）

**命令**: `sleep 1 &`

**預期行為**:
- shell 應印出背景子行程的 PID
- 在短時間內，`/proc/<PID>` 應可被觀察到存在，之後程序結束

**驗證方法**:
- 快速檢查 `/proc/<PID>` 是否於觀察窗口內存在

### 測試 3: 工作資訊行

**命令**: `sleep 1 &`

**預期行為**:
- 若實作支援工作資訊，應印出 `[<job_id>] <pgid>` 的行

**驗證方法**:
- 檢查是否存在符合 `^[[]\d+] \d+$` 的輸出行

## 手動測試
如果需要手動驗證，可以直接執行 shell：
```bash
cd ~/OS-Simple-Shell
./my_shell
```

然後手動輸入以下命令：

```bash
# 測試背景執行（列出目前目錄）
ls &
# 預期：印出一個 PID（可能另有一行 [job_id] pgid）

# 測試背景執行（短暫程序）
sleep 1 &
# 預期：印出一個 PID，該 PID 在短時間內於 /proc 可見

# 結束測試
exit
```

## 背景執行實作要點

此測試主要驗證以下實作面向：

1. **語法解析**：正確解析 `&` 並將工作標記為背景執行
2. **PID 輸出**：在父行程印出背景子行程的 PID（建議印出管線最右端程序的 PID）
3. **工作資訊**：可印出 `[job_id] pgid` 以利追蹤背景工作
4. **前景回復**：不等待背景程序完成，立即回到可接受輸入的狀態並列印提示字元
5. **程序群組**：正確設定 `pgid` 與訊號處理，確保前景/背景行為一致

## 故障排除
### 常見問題

1. **沒有印出 PID**  
   - 檢查是否在背景分支中由父行程印出子行程的 PID
   - 確認 `&` 解析結果有正確設定背景執行模式

2. **只印出工作資訊 `[1] 12345`，沒有單獨 PID 行**  
   - 題目要求「父行程應印出子行程 PID」，建議同時印出獨立的 PID 行以符合測試

3. **`/proc/<PID>` 查無該 PID**  
   - 背景程序可能瞬間結束，改用 `sleep 1 &` 等可觀察的命令
   - 確認印出的 PID 是實際子行程（例如管線最右端程序）

4. **測試超時或測試腳本找不到 shell**  
   - 先執行 `make`，並確認 `my_shell` 在專案根目錄且具執行權限

### 偵錯建議

1. **查看詳細輸出**：
   ```bash
   ./simple_tests/04_background/scripts/test_background.sh 2>&1 | tee background_test_log.txt
   ```

2. **手動多次觀察 `/proc`**：
   ```bash
   for i in {1..10}; do ls /proc/<PID> 2>/dev/null && echo exist || echo missing; sleep 0.05; done
   ```

## 預期測試結果
如果 shell 的背景執行功能實作正確，應該看到：
```
=== 背景執行 ( & ) 測試開始 ===
[INFO] Testing shell binary: ~/OS-Simple-Shell/my_shell

=== 環境檢查 ===
[PASS] Shell binary found and executable

=== 測試 1: ls & 的背景執行 PID 輸出 ===
[INFO] Running: ls & (with exit)
[PASS] Found background PID printed: 3686

=== 測試 2: sleep 1 & 的 PID 應為短暫存活的程序 ===
[INFO] Running: sleep 1 & (with exit)
[INFO] Printed PID: 3702 (checking /proc)
[PASS] PID 3702 exists in /proc (background process observed)

=== 測試 3: 背景工作資訊行格式 ([job_id] pgid) ===
[INFO] Running: sleep 1 & (with exit) to check job info line
[PASS] Found job info line like: [<job_id>] <pgid>

=== 測試結果總結 ===
通過測試: 3/3
[PASS] 背景執行相關測試全部通過！
```
