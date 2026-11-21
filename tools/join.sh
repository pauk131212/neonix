#!/bin/sh
# Собирает ISO из частей релиза и сверяет SHA-256.
#   sh join.sh
# Положи этот файл рядом с neonix-1.1-amd64.iso.part*
set -e
cd "$(dirname "$0")"

OUT=neonix-personal-1.1-amd64.iso
EXPECTED=93b2174a1105b6b70718d7c819cf41e1c9eaab08f35c36b513ad21efbfbe6fb5

ls neonix-1.1-amd64.iso.part* >/dev/null 2>&1 || { echo "не найдены части (neonix-1.1-amd64.iso.partN)"; exit 1; }

cat neonix-1.1-amd64.iso.part* > "$OUT"
echo "размер: $(wc -c < "$OUT") байт"
echo "sha256: $(sha256sum "$OUT" | cut -d' ' -f1)"

if [ "$(sha256sum "$OUT" | cut -d' ' -f1)" = "$EXPECTED" ]; then
    echo "OK: хеш совпал"
else
    echo "ОШИБКА: хеш не совпал, перекачай части"
    exit 1
fi
