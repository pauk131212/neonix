# Чек-лист работы в Cubic (Neonix)

Всё ниже выполняется **внутри Cubic**, в терминале chroot, если не сказано иное.
`$` — обычный shell, `#` — root (в Cubic вы уже root).

---

## 1. Подготовка проекта

- Проект: `~/cubic-project` — **на ext4**, не на `/media/sf_work`.
- ISO: `/media/sf_work/iso/ubuntu-24.04.5.1-desktop-amd64.iso`.
- Перед стартом закройте лишние приложения в ВМ: Cubic копирует и распаковывает ISO.

---

## 2. Первый проход: XFCE рядом с GNOME

```bash
apt update
apt install -y --no-install-recommends \
  xfce4 xfce4-goodies \
  lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
```

Если появится вопрос о display manager — выбрать **lightdm**.

Проверить, что сессия появилась:

```bash
ls /usr/share/xsessions/
# ожидаем xfce.desktop и, возможно, ubuntu.desktop
```

### Сделать XFCE сессией по умолчанию

```bash
# системный DM
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager

# live-пользователь Ubuntu в casper называется ubuntu
mkdir -p /home/ubuntu
printf '[Desktop]\nSession=xfce\n' > /home/ubuntu/.dmrc
chown -R ubuntu:ubuntu /home/ubuntu/.dmrc

# для новых пользователей
printf '[Desktop]\nSession=xfce\n' > /etc/skel/.dmrc
```

Примечание: если в вашей версии Cubic live-пользователь другой — проверьте
`/etc/casper.conf` или `grep -r ubuntu /etc/casper*`.

---

## 3. Софт

```bash
# список уже лежит в общей папке:
apt install -y --no-install-recommends $(grep -v '^#' /media/sf_work/build/packages-xfce.txt | xargs)
```

Минимально проверьте: браузер, файловый менеджер, терминал, скриншоты, архивы.

---

## 4. Русская локаль

```bash
apt install -y language-pack-ru language-pack-gnome-ru fonts-noto fonts-noto-color-emoji
locale-gen ru_RU.UTF-8
update-locale LANG=ru_RU.UTF-8
```

Проверка: `locale` должен показать `ru_RU.UTF-8`.

---

## 5. Брендинг (Neonix)

Всё оформление уже подготовлено в `mydistro/branding/neonix` и скопировано
в общую папку: на хосте `C:\distro-work\build\neonix`, в госте
`/media/sf_work/build/neonix`.

### 5.1. Применить одной командой

```bash
bash /media/sf_work/build/neonix/apply-branding.sh
```

Скрипт ставит:

- Plymouth-тему `neonix` (код + логотип + полоса прогресса) и обновляет initramfs;
- обои `/usr/share/backgrounds/neonix/wallpaper.png`;
- `/etc/os-release`, `/etc/lsb-release`, `/etc/issue`;
- конфиг LightDM с тёмными обоями;
- дефолты XFCE в `/etc/skel` и live-пользователю `ubuntu`;
- автозапуск `neonix-session` (обои, тёмная тема, панель, переименование
  иконки установщика в «Установить Neonix»);
- тему GRUB `/usr/share/grub/themes/neonix`.

> В Plymouth 24.004.60 у картинок **нет** `SetWidth`/`SetHeight` — от таких
> вызовов скрипт молча обрывается, и заставка остаётся чёрной. Масштаб —
> только `img.Scale(w, h)` (возвращает новую картинку), а расстановка —
> спрайтами `Sprite(img)` с `SetX/SetY/SetZ/SetOpacity`. Подробности —
> в [`rebuild-iso.md`](rebuild-iso.md).

### 5.2. Проверить

```bash
cat /etc/os-release
ls -l /usr/share/plymouth/themes/neonix
plymouth-set-default-theme --list | grep neonix
```

### 5.3. Загрузочное меню ISO

Меню GRUB/isolinux — это файлы самого ISO, а не chroot. Их можно править
напрямую в `~/cubic-project/custom-disk/boot/grub/grub.cfg` и
`loopback.cfg` (заменить `Try or Install Ubuntu` на `Try or Install Neonix`,
`Ubuntu (safe graphics)` на `Neonix (safe graphics)`). Раздел «Boot» в
Cubic делает то же самое, но ручная правка быстрее.

---

## 6. Очистка перед сборкой

```bash
apt autoremove -y
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* /var/tmp/*
find /var/log -type f -exec truncate -s 0 {} \;
```

Не удаляйте `/etc/machine-id` вручную — Cubic сбрасывает его сам.

---

## 7. Сборка ISO

**Кнопкой Generate пользоваться нельзя** — на Ubuntu 24.04.5 Cubic
запускает xorriso раньше, чем допишется `minimal.standard.live.squashfs`,
и сборка падает на 99.7 % с обрезанным слоем. Сборка выполняется вручную
по шагам из [`rebuild-iso.md`](rebuild-iso.md):

```bash
sudo bash /media/sf_work/build/fix-root.sh       # правки rootfs + меню
sudo bash /media/sf_work/build/patch-initrd.sh   # тема Plymouth в initrd
bash /media/sf_work/build/run-compress.sh        # mksquashfs (12–15 мин)
bash /media/sf_work/build/xorriso-rebuild.sh     # xorriso (около 2 мин)
```

Результат: `~/cubic-project/neonix-1.0-amd64.iso`, около 6.29 ГБ.

---

## 8. Тест

1. Создайте **отдельную** тестовую ВМ (не сборщик).
2. Подключите новый ISO, загрузитесь.
3. Проверьте:
   - [ ] загрузка без ошибок, меню с названием Neonix
   - [ ] экран загрузки: код, логотип, прогресс
   - [ ] рабочий стол XFCE
   - [ ] сеть (браузер открывает сайт)
   - [ ] звук
   - [ ] русская раскладка и локаль
   - [ ] `cat /etc/os-release` показывает Neonix
   - [ ] установка на диск проходит
   - [ ] после установки — XFCE и брендинг
   - [ ] `sudo apt update` работает

---

## 9. Частые проблемы

| Симптом | Причина | Решение |
|---|---|---|
| Cubic не стартует / падает при распаковке | проект на vboxsf или NTFS | перенести в `~/cubic-project` |
| `No space left on device` | мало места в ВМ | увеличить диск ВМ, удалить старые проекты |
| Нет `/media/sf_work` | нет Guest Additions / нет группы | `usermod -aG vboxsf $USER`, перезагрузка |
| После сборки грузится GNOME | не выставлена сессия | проверить `.dmrc`, `AccountsService`, `/etc/X11/default-display-manager` |
| Загрузка показывает стандартный логотип Ubuntu | тема не попала в initrd (в chroot Cubic нет ядра и модулей) | пропатчить `casper/initrd.gz`, см. `rebuild-iso.md` |
| Нет звука в live | конфликт PulseAudio/PipeWire | проверить `pactl info`, при необходимости `apt install pipewire-audio` |
| ISO больше 4 ГБ | сжатие/размер | использовать xz, уменьшить набор пакетов |
| Ошибка подписи репозитория | устаревший ключ | `apt update` в chroot, обновить ключи |

---

## 10. Правила гигиены

- Одна сборка = одно изменение. Так проще понять, что сломалось.
- Перед удалением GNOME сделайте рабочую сборку с XFCE и сохраните ISO.
- Держите `docs/` в актуальном состоянии.
- Не публикуйте ISO без проверки на чистой машине.
