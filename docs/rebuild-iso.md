# Neonix: пересборка ISO вручную

Так собирается финальный образ Neonix 1.0 на базе Ubuntu 24.04.5.1 Desktop
(внутри виртуальной машины `Ubuntu2404-Builder`, проект Cubic в
`/home/builder/cubic-project`).

## Почему не через кнопку Generate в Cubic

У Ubuntu 24.04.5 ISO состоит из трёх squashfs-слоёв:

| файл | содержимое |
| --- | --- |
| `casper/minimal.squashfs` | базовый root (его и правит Cubic) |
| `casper/minimal.standard.squashfs` | символическая ссылка на `minimal.squashfs` |
| `casper/minimal.standard.live.squashfs` | live-слой (casper, установщик, live-пользователь) |

Cubic запускает xorriso, не дожидаясь окончания записи
`minimal.standard.live.squashfs`, поэтому в ISO попадал обрезанный файл
(966 968 690 вместо 1 237 045 248 байт) и сборка падала на 99.7 %.
Поэтому образ собирается вручную теми же командами.

## Важно про initrd

В chroot Cubic нет ни ядра, ни модулей (`/boot` содержит только memtest,
`/usr/lib/modules` отсутствует), поэтому `update-initramfs` ничего не
собирает, а Cubic копирует в ISO **исходный** `casper/initrd.gz`. Тема
Plymouth в него не попадает — splash остаётся родной убунтовский.

`casper/initrd.gz` у этого ISO — конкатенация четырёх частей:

| смещение (байт) | содержимое |
| --- | --- |
| 0 | cpio: микрокод AuthenticAMD |
| 305 784 | cpio: микрокод GenuineIntel |
| 15 106 560 | cpio: прошивки (`/usr/lib/firmware`, ~53 МБ) |
| 65 747 456 | **zstd-сжатый основной initrd** (init, plymouth, casper) |

Поэтому тема добавляется прямо в последнюю часть, а первые три копируются
байт в байт.

## Порядок пересборки

Все команды выполняются в ВМ-сборщике, пароль sudo — `builder`.
Файлы проекта лежат в `/media/sf_work/build/` (общая папка с хостом).

1. **Правки root-файловой системы** (`custom-root`):

   ```bash
   sudo bash /media/sf_work/build/fix-root.sh
   sudo bash /media/sf_work/build/fix-release.sh
   ```

   `fix-root.sh` ставит `/usr/local/bin/neonix-session` и
   `/etc/xdg/autostart/neonix-session.desktop` (обои + тёмная тема для
   live-сессии) и меняет подписи меню GRUB на «Neonix».

   `fix-release.sh` возвращает в `/usr/lib/os-release` и `/etc/lsb-release`
   правильные строки: Cubic при сборке перезаписывает `PRETTY_NAME` и
   `DISTRIB_DESCRIPTION` на `Ubuntu 24.04.5 ... (Cubic ...)`.

2. **Патч initrd** (`custom-disk/casper/initrd.gz`):

   ```bash
   sudo bash /media/sf_work/build/patch-initrd.sh
   ```

   Скрипт распаковывает zstd-часть, добавляет
   `/usr/share/plymouth/themes/neonix`, плагин `script.so`,
   `/etc/plymouth/plymouthd.conf` (`Theme=neonix`) и собирает файл заново.
   Первые 65 747 456 байт остаются без изменений.

   Тема должна лежать и в `custom-root` (её забирает и шаг 2, и squashfs),
   поэтому скрипт берёт файлы оттуда.

## API скриптовой темы Plymouth (грабли)

В Plymouth 24.004.60 (`script.so`) у объекта-картинки **нет**
`SetWidth`/`SetHeight`. Если их вызвать, скрипт молча обрывается на первом
же таком вызове — Plymouth остаётся с чёрным экраном, в журнале ошибок нет.
Доступный API:

* `Image("file.png")` — загрузить картинку;
* `img.Scale(w, h)` — **возвращает новую** картинку (нужно присваивать);
* `Sprite(img)` — спрайт; у спрайта есть `SetX`, `SetY`, `SetZ`, `SetOpacity`,
  `SetImage`;
* `Window.GetWidth()/GetHeight()`, `Window.SetBackgroundTopColor/BottomColor`.

Поэтому `neonix.script` сначала масштабирует картинки через `.Scale()`,
а затем кладёт их на экран спрайтами. Проверить тему без пересборки ISO можно
на самом builder'е: положить тему в `/usr/share/plymouth/themes/neonix`,
поставить alternative `default.plymouth` на неё и выполнить
`update-initramfs -u` — при загрузке builder'а будет видна та же заставка.

3. **Сжатие root** (12–15 минут):

   ```bash
   bash /media/sf_work/build/run-compress.sh
   ```

   Внутри — ровно та команда `mksquashfs`, которую использует Cubic
   (`-comp zstd`, те же `-e` исключения). Результат:
   `custom-disk/casper/minimal.squashfs`.

4. **Сборка ISO** (около 2 минут):

   ```bash
   bash /media/sf_work/build/xorriso-rebuild.sh
   ```

   Точная копия команды Cubic, но с `-V 'Neonix 1.0'` и именем
   `neonix-1.0-amd64.iso`. Успех — строка `EXIT=0` и размер около
   6 290 745 344 байт.

5. **Перенос на хост.** Общая папка даёт всего ~4 МБ/с, поэтому быстрее
   по сети:

   ```bash
   # в госте
   cd /home/builder/cubic-project
   python3 -m http.server 8000
   ```

   ```powershell
   # на хосте
   VBoxManage controlvm Ubuntu2404-Builder natpf1 "web,tcp,,8000,,8000"
   curl.exe -o C:\distro-work\out\neonix-1.0-amd64.iso `
     http://127.0.0.1:8000/neonix-1.0-amd64.iso
   ```

6. **Проверка.** Подключить ISO к ВМ `Neonix-Test` и загрузиться:
   меню GRUB должно говорить «Try or Install Neonix», дальше — анимация
   Neonix (падающий код, затем логотип с глитчем), затем XFCE с тёмными
   обоями Neonix.

## Брендинг live-сессии

`/home/ubuntu` уже существует внутри squashfs, поэтому casper не копирует
`/etc/skel` в домашний каталог live-пользователя. Из-за этого настройки
XFCE из `skel` не применяются. Решение — autostart-скрипт
`neonix-session`, который при каждом входе:

* ставит обои `/usr/share/backgrounds/neonix/wallpaper.png` для всех
  мониторов и рабочих столов (имя монитора в VirtualBox — `monitorVGA-1`,
  поэтому конфиг с `monitor0` не работает);
* включает тёмную тему GTK `Adwaita-dark`, иконки `Adwaita`, тему окон
  `Daloa`;
* переводит панели XFCE на фон из темы;
* переименовывает иконку установщика на рабочем столе в «Установить Neonix».
  Файл `~/Desktop/ubuntu-desktop-bootstrap_ubuntu-desktop-bootstrap.desktop`
  создаётся при загрузке snap-пакетом `ubuntu-desktop-bootstrap`, поэтому
  правка делается в рантайме (в `neonix-session`), а не в squashfs.

Сами обои — тёмная сетка с уголками и логотипом NEONIX по центру, без
падающего кода: анимация кода осталась только на загрузочной заставке
Plymouth. Вариант обоев с кодом сохранён как
`assets/wallpaper-code.png`.

## Что ещё осталось косметикой

* Заголовок установщика берётся из `casper/install-sources.yaml`
  (уже заменён на «Neonix 1.0»).
