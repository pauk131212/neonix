# Neonix — кибер-ремикс Ubuntu 24.04 на XFCE

Свой дистрибутив на базе Ubuntu 24.04 LTS, собранный в VirtualBox через **Cubic**.
Тёмная кибер-эстетика, «код» на экране загрузки, свой логотип.
Слоган: **CODE // NEON // CONTROL**.

Артефакты брендинга: `branding/neonix/` (Plymouth, GRUB, LightDM, XFCE, скрипт установки).

## Скачать готовый ISO

Образ лежит в GitHub Releases (файл больше 2 ГБ, поэтому порезан на части):

```
https://github.com/ВАШ_ЛОГИН/neonix/releases/latest
```

Собрать части обратно и проверить:

```powershell
# Windows
copy /b neonix-1.0-amd64.iso.part01+neonix-1.0-amd64.iso.part02+neonix-1.0-amd64.iso.part03+neonix-1.0-amd64.iso.part04 neonix-1.0-amd64.iso
Get-FileHash .\neonix-1.0-amd64.iso -Algorithm SHA256
```

```bash
# Linux
cat neonix-1.0-amd64.iso.part* > neonix-1.0-amd64.iso
sha256sum -c SHA256SUMS.txt
```

Хеш текущей сборки: `1971d28e537f72fbda5b20d4a95425b7464be8554562d395c3eda0badf077258`.

Neonix — неофициальный ремикс Ubuntu, не связан с Canonical. Подробности — в `LICENSE`.


## Что где лежит

```
mydistro/                  <- этот проект (скрипты, документы, брендинг)
  scripts/
    01-download-iso.ps1    скачать ISO Ubuntu (с докачкой)
    02-verify-iso.ps1      проверить SHA256
    03-create-vm.ps1       создать ВМ для сборки
    04-start-vm.ps1        запустить ВМ
  docs/
    detailed-plan.md       полный план от ВМ до ISO (этот документ — основа)
    plan.md                краткий план по этапам
    remix-checklist.md     пошаговый чек-лист внутри Cubic
  branding/
    os-release.template    шаблон /etc/os-release
    packages-xfce.txt      набор пакетов XFCE
    neonix/                брендинг: Plymouth, GRUB, LightDM, XFCE, ассеты
```

Артефакты (вне проекта, путь без кириллицы — так надёжнее для VirtualBox):

```
C:\distro-work\
  iso\      исходный ISO Ubuntu
  vm\       виртуальная машина сборщика
  build\    общая папка хост <-> гость (сюда кладём брендинг, оттуда забираем результат)
  out\      готовые ISO
```

## Быстрый старт

```powershell
cd "C:\Users\Дух из чайника\Documents\Проект по умолчанию\mydistro"
powershell -ExecutionPolicy Bypass -File .\scripts\01-download-iso.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\02-verify-iso.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\03-create-vm.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\04-start-vm.ps1
```

Дальше — установка Ubuntu в ВМ и работа по `docs/remix-checklist.md`.

## Порядок работы

1. **Подготовка** — ISO скачан, ВМ создана. ✅ (скрипты)
2. **Установка Ubuntu** в ВМ (обычная установка на весь диск).
3. **Cubic** — ставим, открываем, выбираем ISO, попадаем в chroot.
4. **Кастомизация** — XFCE, софт, брендинг, очистка.
5. **Сборка ISO** — Cubic генерирует образ.
6. **Тест** — загрузка нового ISO в отдельной ВМ.
7. **Итерации** — правим, пересобираем.

## Важные правила

- Проект Cubic держите **на ext4 внутри ВМ** (`~/cubic-project`), не на общей папке — иначе сборка сломается.
- ISO и результат можно гонять через общую папку `/media/sf_work`.
- Не используйте товарные знаки Ubuntu в названии и оформлении.
- Каждую сборку проверяйте в чистой ВМ, а не только в сборщике.

## Публикация на GitHub

Всё готово к публикации: `.gitignore` не пускает в репозиторий ISO и образы ВМ,
`LICENSE` — MIT для наших файлов (пакеты Ubuntu остаются под своими лицензиями).

1. Исходники (скрипты, брендинг, документация) — один раз:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\publish-repo.ps1
   ```

   Скрипт поставит Git и GitHub CLI (если их нет), попросит войти в аккаунт,
   создаст репозиторий `neonix` и запушит `main`.

2. Готовый ISO — в Releases (файл больше 2 ГБ, поэтому режется на части):

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\publish-iso.ps1
   ```

   Создаст релиз `v1.0`, зальёт части ISO и `SHA256SUMS.txt`.
   Загрузка 6.3 ГБ зависит от скорости интернета — может идти часами.

Если GitHub-релизы кажутся неудобными для 6 ГБ, альтернатива —
archive.org (умеет торренты) или Яндекс.Диск; тогда в README просто
меняется ссылка на скачивание.

