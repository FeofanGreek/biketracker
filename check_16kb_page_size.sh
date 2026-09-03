#!/bin/bash

# Скрипт: check_16kb_so_local.sh
# Назначение: проверяет все .so файлы в проекте Flutter (локальные и плагины) на 16KB (или 64KB) page size

set -e

echo "🔎 Проверяем .so файлы в build/ и .pub-cache..."

# Ищем llvm-readelf в NDK
READELF=$(find "$HOME/Library/Android/sdk/ndk" -name "llvm-readelf" | sort -V | tail -n 1)

if [ -z "$READELF" ]; then
    echo "❌ llvm-readelf не найден! Установите NDK в Android Studio."
    exit 1
fi

echo "✅ Используем $READELF"

# Пути для проверки
CHECK_PATHS=(
    "build/"                   # локальные сборки
    "$HOME/.pub-cache/hosted/" # глобальные пакеты pub
    "$HOME/.pub-cache/git/"    # git-плагины
)

FAIL_COUNT=0

for path in "${CHECK_PATHS[@]}"; do
    if [ ! -d "$path" ]; then
        continue
    fi
    SO_FILES=$(find "$path" -name "*.so")
    for sofile in $SO_FILES; do
        aligns=$("$READELF" -l "$sofile" 2>/dev/null | grep "LOAD" | grep -o "0x[0-9a-f]*" | tail -n 1)
        # 0x4000 = 16KB, 0x10000 = 64KB. Оба подходят!
        if [ "$aligns" != "0x4000" ] && [ "$aligns" != "0x10000" ] && [ -n "$aligns" ]; then
            echo "⚠ $sofile выравнено не на 16/64KB: $aligns"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    done
done

# Результат
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ Все найденные .so файлы соответствуют требованиям 16KB (или 64KB) page size!"
else
    echo "❌ Найдено $FAIL_COUNT .so файлов с неверным выравниванием!"
    echo "⚠️ Рекомендуется пересобрать эти библиотеки с NDK r28+ и page size 16KB/64KB"
fi
