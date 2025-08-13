# 多重管線與背景執行測試 (Multi-Pipelines Background Execution Test)
## 測試目的
測試 shell 的多重管線與背景執行功能：

1. **多重管線**：支援結合 I/O 重導向與管線的複合命令
2. **背景執行的 PID 輸出**：當多重管線在背景執行時，父行程（shell）應印出「最右側指令」之子行程 PID
3. **輸出內容正確性**：透過 `pipeout.txt` 驗證輸出結果是否符合預期

## 目錄結構
```
05_multi_pipelines/
├── README.md                    # 此說明文件
├── scripts/
│   └── test_multi_pipelines.sh  # 主要測試腳本
└── test_data/
    └── text.txt                 # 測試用文本文件
```

## 測試資料

`text.txt` 範例內容：

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

# 執行多重管線測試
./simple_tests/run_test.sh 05_multi_pipelines
```

#### 方式 B

```bash
# 進入測試腳本目錄
cd ~/OS-Simple-Shell/simple_tests/05_multi_pipelines/scripts

# 執行測試
./test_multi_pipelines.sh
```

### 測試輸出說明

測試腳本會使用顏色標記來顯示結果：

- **🔵 [INFO]**: 一般資訊和進度更新
- **🟡 [WARN]**: 警告訊息（命令返回非零退出碼但可能仍正常）
- **🟢 [PASS]**: 測試通過
- **🔴 [FAIL]**: 測試失敗

## 預期行為和驗證方法

### 測試 1: 多重管線背景執行 PID 輸出

**命令**：

```bash
cat < text.txt | head -4 | tail -2 | grep shell > pipeout.txt &
```

**預期行為**：
- shell 應印出背景執行的 PID，且該 PID 為「最右側指令」（此例為 `grep`）之子行程 PID
- 可能同時印出工作資訊行（例如 `[4] 30800`），但不影響此測試的必要條件

**驗證方法**：
- 解析 shell 輸出，擷取數字 PID（容忍提示字元前綴的情況）

### 測試 2: 多重管線輸出內容驗證

**命令**：

```bash
cat < text.txt | head -4 | tail -2 | grep shell > pipeout.txt &
```

**預期行為**：
- 背景管線完成後，應產生 `pipeout.txt` 檔案
- `pipeout.txt` 應包含以下兩行文字：
  - `The shell parses input using tokenization`
  - `Custom shells often rely on \`fork()\` and \`exec()\` for execution`

**驗證方法**：
- 等待背景工作短時間完成，檢查 `pipeout.txt` 是否存在
- 驗證檔案是否包含上述兩行內容，並可選擇檢查行數為 2 行

## 手動測試

如果需要手動驗證，可以直接執行 shell：

```bash
cd ~/OS-Simple-Shell
./my_shell
```

然後手動輸入以下命令：

```bash
cd ~/OS-Simple-Shell/simple_tests/05_multi_pipelines/test_data
cat < text.txt | head -4 | tail -2 | grep shell > pipeout.txt &
# 預期：第一行印出最右側指令 (grep) 的子行程 PID；第二行印出 [job_id] pgid

# 確認原檔案
cat text.txt

# 檢查輸出結果
cat pipeout.txt

# 清理
rm pipeout.txt

# 退出
exit
```

## 實作要點

此測試主要驗證以下實作面向：

1. **多重管線解析與連接**：正確處理 `<`、`|`、`>` 的組合
2. **背景執行的 PID 印出**：於父行程印出「最右側」子行程 PID
3. **程序群組與等待策略**：背景工作不阻塞 shell 提示字元，並能完成輸出
4. **輸出檔案正確性**：`pipeout.txt` 內容應符合預期

## 故障排除

### 常見問題

1. **沒有印出 PID**  
   - 檢查是否於背景模式下，由父行程印出最右側命令的子行程 PID

2. **`pipeout.txt` 未生成**  
   - 可能背景程序尚未完成，延長等待時間再檢查
   - 檢查重導向與管線連接是否正確

3. **輸出內容不匹配**  
   - 檢查 `head -4` 與 `tail -2` 的管線是否正確傳遞
   - 確認 `grep shell` 的大小寫與比對字串

### 偵錯建議

1. **查看詳細輸出**：
   ```bash
   ./simple_tests/05_multi_pipelines/scripts/test_multi_pipelines.sh 2>&1 | tee ~/OS-Simple-Shell/multi_pipelines_test_log.txt
   ```

2. **手動驗證單段命令**：
   ```bash
   cd ~/OS-Simple-Shell/simple_tests/05_multi_pipelines/test_data
   echo "cat < text.txt | head -4 | tail -2 | grep shell" | ../../../../my_shell
   ```
