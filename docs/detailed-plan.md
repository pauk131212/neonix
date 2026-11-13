# Neonix — подробный план работ

Документ описывает весь путь от пустой ВМ до готового ISO.
Каждый этап имеет цель, команды, результат и критерий готовности.

---

## 0. Текущее состояние

| Что | Статус |
|---|---|
| VirtualBox 7.2.22 | установлен |
| ВМ `Ubuntu2404-Builder` (6 ГБ RAM, 4 CPU, 40 ГБ) | создана, запущена |
| ISO Ubuntu 24.04.5.1 | скачан, SHA256 совпал |
| Общая папка `C:\distro-work` → `/media/sf_work` | настроена в ВМ |
| Брендинг Neonix | готов (`branding/neonix/`) |
| Ubuntu в ВМ | **устанавливается сейчас** |

---

## 1. Цель и критерии готовности

**Цель:** получить загрузочный ISO `neonix-1.0-amd64.iso`, который:

- грузится в VirtualBox и на реальном ПК с флешки;
- показывает кибер-экран загрузки Neonix с «кодом» и логотипом;
- запускает live-сессию XFCE с тёмным оформлением;
- корректно устанавливается на диск;
- после установки сохраняет XFCE, брендинг и рабочий `apt`.

**Не входит в версию 1.0:** свой репозиторий пакетов, вайфу-маскот, автообновление дистрибутива.

---

## 2. Этап 1 — Установка Ubuntu в ВМ

**Время:** 30–60 мин. **Где:** окно VirtualBox.

1. В окне ВМ выберите язык.
2. Нажмите **Install Ubuntu**.
3. Клавиатура: раскладка по вкусу (например, English US + Russian).
4. Тип установки: **Minimal installation** (лишний софт сборщику не нужен).
5. Установка: **Erase disk and install Ubuntu** — весь виртуальный диск.
6. Пользователь:
   - имя: `builder`
   - имя компьютера: `neonix-builder`
   - пароль: простой (ВМ локальная), например `builder`
   - вход: автоматический или по паролю — не важно.
7. Дождаться завершения → **Restart now**.

**Критерий готовности:** рабочий стол Ubuntu, вход выполнен.

> Если ВМ не грузится с ISO — проверьте, что в настройках ВМ оптический диск указывает на
> `C:\distro-work\iso\ubuntu-24.04.5.1-desktop-amd64.iso`, и в порядке загрузки DVD первый.

---

## 3. Этап 2 — Настройка сборщика

**Время:** 15–20 мин. **Где:** терминал внутри Ubuntu.

### 3.1. Обновление

```bash
sudo apt update && sudo apt full-upgrade -y
```

### 3.2. Гостевая поддержка VirtualBox и общая папка

```bash
sudo apt install -y virtualbox-guest-utils virtualbox-guest-x11
sudo usermod -aG vboxsf $USER
```

Перезагрузиться:

```bash
sudo reboot
```

После перезагрузки проверить:

```bash
ls /media/sf_work
# ожидается: build  iso  out  vm
```

### 3.3. Отключить сон и блокировку

Параметры → Power → **Screen Blank: Never**, **Automatic Suspend: Off**.
Параметры → Privacy → **Screen Lock: Off**.

### 3.4. Проверить ресурсы

```bash
free -h
df -h /
```

**Критерий готовности:** общая папка видна, обновления установлены, сон отключён,
на диске свободно больше 20 ГБ.

---

## 4. Этап 3 — Установка Cubic

**Время:** 10 мин.

```bash
sudo apt-add-repository ppa:cubic-workshop/ppa -y
sudo apt update
sudo apt install -y cubic
```

Запуск: меню приложений → **Cubic** (или `cubic`).

**Критерий готовности:** открывается окно Cubic с предложением выбрать проект.

---

## 5. Этап 4 — Первая сборка-репетиция

**Время:** 30–40 мин. **Цель:** убедиться, что весь конвейер работает, ничего не меняя.

1. В Cubic нажать **Create project**.
2. Папка проекта: `/home/builder/cubic-project` (на ext4, **не** на `/media/sf_work`).
3. Выбрать ISO: `/media/sf_work/iso/ubuntu-24.04.5.1-desktop-amd64.iso`.
4. Дождаться распаковки (5–15 мин).
5. Ничего не менять. Нажать **Generate**.
6. Имя: `neonix-1.0-test.iso`, сжатие **zstd**.
7. Дождаться сборки (5–15 мин).
8. Скопировать результат в общую папку:

```bash
cp ~/cubic-project/*.iso /media/sf_work/out/
```

9. На хосте (PowerShell) создать тестовую ВМ:

```powershell
cd "C:\Users\Дух из чайника\Documents\Проект по умолчанию\mydistro"
powershell -ExecutionPolicy Bypass -File .\scripts\05-create-test-vm.ps1 `
  -IsoPath "C:\distro-work\out\neonix-1.0-test.iso"
```

10. Запустить тестовую ВМ и проверить загрузку.

**Критерий готовности:** пересобранный ISO грузится и доходит до рабочего стола Ubuntu.

> Если этот этап пройден — дальше только кастомизация. Если нет — проблема в окружении,
> и её надо решить до любых изменений.

---

## 6. Этап 5 — XFCE и софт

**Время:** 60–90 мин. **Где:** терминал Cubic (chroot).

### 6.1. Установка XFCE рядом с GNOME

```bash
apt update
apt install -y --no-install-recommends \
  xfce4 xfce4-goodies \
  lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
```

На вопрос о display manager ответить **lightdm**.

### 6.2. Сессия по умолчанию

```bash
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
printf '[Desktop]\nSession=xfce\n' > /etc/skel/.dmrc
mkdir -p /home/ubuntu
printf '[Desktop]\nSession=xfce\n' > /home/ubuntu/.dmrc
chown -R ubuntu:ubuntu /home/ubuntu/.dmrc
```

### 6.3. Софт

```bash
apt install -y --no-install-recommends $(grep -v '^#' /media/sf_work/build/packages-xfce.txt | xargs)
```

### 6.4. Локаль

```bash
apt install -y language-pack-ru language-pack-gnome-ru fonts-noto fonts-noto-color-emoji
locale-gen ru_RU.UTF-8
update-locale LANG=ru_RU.UTF-8
```

### 6.5. Собрать и проверить

Сгенерировать ISO, скопировать в `out`, загрузить в тестовой ВМ.

**Критерий готовности:** live-сессия стартует в XFCE, браузер и терминал работают,
русская локаль доступна.

---

## 7. Этап 6 — Брендинг Neonix

**Время:** 20–30 мин.

### 7.1. Применить

В chroot Cubic:

```bash
bash /media/sf_work/build/neonix/apply-branding.sh
```

Скрипт ставит Plymouth-тему, обои, os-release, LightDM, дефолты XFCE, GRUB-тему.

### 7.2. Проверить внутри chroot

```bash
cat /etc/os-release
ls -l /usr/share/plymouth/themes/neonix
plymouth-set-default-theme --list | grep neonix
```

### 7.3. Загрузочное меню

В Cubic в разделе загрузки ISO заменить `Ubuntu` на `Neonix`
(строки меню GRUB и isolinux).

### 7.4. Собрать и проверить

**Критерий готовности:** при загрузке виден кибер-экран с кодом и логотипом,
в live-сессии `cat /etc/os-release` показывает Neonix, экран входа тёмный.

---

## 8. Этап 7 — Удаление GNOME (опционально)

**Время:** 30 мин. **Риск:** средний. Делать только после рабочей сборки с XFCE.

```bash
apt purge -y ubuntu-desktop ubuntu-desktop-minimal gnome-shell gnome-shell-common \
  gnome-session-bin gnome-terminal gnome-software
apt autoremove -y
```

После удаления **обязательно** проверить:

- `lightdm` остался установленным;
- `xfce4` и `xfce4-goodies` на месте;
- `network-manager`, `pulseaudio`/`pipewire`, `xorg` не удалились.

Если `apt` предлагает удалить критичные пакеты — отменить (`n`) и оставить GNOME.

**Критерий готовности:** ISO меньше по размеру, live-сессия по-прежнему XFCE.

---

## 9. Этап 8 — Финальная сборка

**Время:** 20–40 мин.

1. Очистка в chroot:

```bash
apt autoremove -y
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* /var/tmp/*
find /var/log -type f -exec truncate -s 0 {} \;
```

2. **Generate**, имя `neonix-1.0-amd64.iso`, сжатие **xz** (меньше размер).
3. Скопировать в `out`.
4. Посчитать SHA256 на хосте:

```powershell
Get-FileHash C:\distro-work\out\neonix-1.0-amd64.iso -Algorithm SHA256
```

**Критерий готовности:** ISO собран без ошибок, хеш записан.

---

## 10. Этап 9 — Тестирование

**Время:** 60–90 мин.

### 10.1. Тест live-режима (чистая ВМ)

- [ ] загрузка без ошибок, меню Neonix
- [ ] экран загрузки: код, логотип, прогресс
- [ ] рабочий стол XFCE
- [ ] сеть: браузер открывает сайт
- [ ] звук
- [ ] русская раскладка и локаль
- [ ] `cat /etc/os-release` → Neonix
- [ ] терминал с неоновой палитрой

### 10.2. Тест установки

- [ ] установка на диск проходит
- [ ] после перезагрузки — XFCE и Neonix
- [ ] `sudo apt update` работает
- [ ] создание нового пользователя даёт XFCE и обои

### 10.3. Тест на реальном железе (по возможности)

- записать ISO на флешку (Rufus / balenaEtcher);
- загрузиться, проверить live-режим;
- проверить Wi-Fi/звук/видео.

**Критерий готовности:** все пункты отмечены, критичных дефектов нет.

---

## 11. Этап 10 — Итерации и выпуск

1. Исправить найденные дефекты, пересобрать.
2. Обновить `docs/` и `README.md`.
3. Подписать ISO GPG-ключом, опубликовать SHA256.
4. Подготовить страницу загрузки.
5. Дальше — свой репозиторий пакетов и вайфу-маскот.

---

## 12. Тайминг

| Этап | Время | Зависимость |
|---|---|---|
| 1. Установка Ubuntu | 30–60 мин | — |
| 2. Настройка сборщика | 15–20 мин | 1 |
| 3. Cubic | 10 мин | 2 |
| 4. Репетиция | 30–40 мин | 3 |
| 5. XFCE и софт | 60–90 мин | 4 |
| 6. Брендинг | 20–30 мин | 5 |
| 7. Удаление GNOME | 30 мин | 6 |
| 8. Финальная сборка | 20–40 мин | 6/7 |
| 9. Тестирование | 60–90 мин | 8 |
| **Итого** | **4–7 часов** | |

---

## 13. Правила и откаты

- Одна сборка = одно изменение.
- Перед рискованным шагом (удаление GNOME) сохранить рабочий ISO.
- Cubic хранит проект целиком: можно откатиться, пересоздав проект из исходного ISO.
- Не трогать `/etc/machine-id` вручную.
- Не держать проект Cubic на NTFS/vboxsf.
- Каждый ISO проверять в отдельной чистой ВМ.

---

## 14. Если что-то пошло не так

| Проблема | Что делать |
|---|---|
| ВМ не видит ISO | проверить IDE-контроллер и порядок загрузки |
| Чёрный экран / `soft lockup` при загрузке ISO | KVM-паравиртуализация | `VBoxManage modifyvm Ubuntu2404-Builder --paravirtprovider none` (уже применено) |
| Экран не просыпается, гость жив | графика | `--graphicscontroller vboxsvga --accelerate-3d off` (уже применено) |
| Нет `/media/sf_work` | `usermod -aG vboxsf $USER`, перезагрузка, Guest Additions |
| Cubic падает при распаковке | проект не на ext4 или мало места |
| После сборки GNOME вместо XFCE | проверить `.dmrc`, `/etc/X11/default-display-manager` |
| Нет экрана Neonix при загрузке | `plymouth-set-default-theme -R neonix`, `update-initramfs -u` |
| ISO не грузится в UEFI | проверить, что Cubic пересобрал EFI-раздел |
| Сломались зависимости после purge | вернуть GNOME-пакеты или пересоздать проект |
