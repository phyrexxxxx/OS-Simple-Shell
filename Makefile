# Makefile for Simple Shell
# 支援多檔案結構的編譯

# 編譯器和選項
CC := gcc
CFLAGS := -Wall -Wextra -std=c99 -g
LDFLAGS :=

# 目錄設定
SRCDIR := src
INCDIR := include
OBJDIR := obj

# 檔案定義
TARGET := my_shell
MAIN_SRC := my_shell.c
SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
MAIN_OBJ := $(OBJDIR)/my_shell.o

# 預設目標
all: $(TARGET)

# 建立目標執行檔
$(TARGET): $(OBJECTS) $(MAIN_OBJ)
	@echo "正在連結 $@..."
	@$(CC) $(OBJECTS) $(MAIN_OBJ) -o $@ $(LDFLAGS)
	@echo "編譯完成！"

# 編譯主程式
$(MAIN_OBJ): $(MAIN_SRC) | $(OBJDIR)
	@echo "編譯主程式 $<..."
	@$(CC) $(CFLAGS) -I$(INCDIR) -c $< -o $@

# 編譯來源檔
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@echo "編譯 $<..."
	@$(CC) $(CFLAGS) -I$(INCDIR) -c $< -o $@

# 建立目標目錄
$(OBJDIR):
	@mkdir -p $(OBJDIR)

# 清理
clean:
	@echo "清理編譯檔案..."
	@rm -rf $(OBJDIR) $(TARGET)
	@echo "清理完成！"

# 重新編譯
rebuild: clean all

# 執行程式
run: $(TARGET)
	@echo "執行 Simple Shell..."
	@./$(TARGET)

# 偵錯模式編譯
debug: CFLAGS += -DDEBUG -O0
debug: $(TARGET)

# 最佳化編譯
release: CFLAGS += -O2 -DNDEBUG
release: $(TARGET)

# 顯示幫助
help:
	@echo "可用的目標："
	@echo "  all      - 編譯程式 (預設)"
	@echo "  clean    - 清理編譯檔案"
	@echo "  rebuild  - 清理後重新編譯"
	@echo "  run      - 編譯並執行程式"
	@echo "  debug    - 偵錯模式編譯"
	@echo "  release  - 最佳化編譯"
	@echo "  help     - 顯示此幫助訊息"

# 聲明偽目標
.PHONY: all clean rebuild run debug release help

# 依賴關係
$(OBJECTS): $(wildcard $(INCDIR)/*.h)
$(MAIN_OBJ): $(wildcard $(INCDIR)/*.h)