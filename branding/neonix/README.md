# Neonix — брендинг

Название: **Neonix**
Слоган: **CODE // NEON // CONTROL**
Версия: 1.0 (Noble)

## Состав

```
neonix/
  assets/                 сгенерированные PNG (background, wallpaper, logo, элементы)
  plymouth/neonix/        загрузочный экран: «код», логотип, прогресс
  grub/theme.txt          тема меню GRUB
  lightdm/                конфиг экрана входа
  xfce/                   дефолты XFCE для новых пользователей
  skel/.dmrc              сессия XFCE по умолчанию
  apply-branding.sh       установщик брендинга (запускать в chroot Cubic)
```

## Как применить

В терминале Cubic (chroot, root):

```bash
bash /media/sf_work/build/neonix/apply-branding.sh
```

Скрипт ставит тему Plymouth, обои, os-release, LightDM, дефолты XFCE и тему GRUB.

## Перегенерация графики

На Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\06-generate-branding.ps1
```

Скрипт рисует ассеты через System.Drawing. Правьте тексты и цвета в нём.

## Идея оформления

- Фон: почти чёрный `#05070A`, сетка, неоновый «код» слева.
- Акценты: циан `#00E5FF`, зелёный `#39FF88`, маджента `#FF2E88`.
- Загрузка: строки кода + логотип + тонкая полоса прогресса + мигающий курсор.
- Вход: тёмный LightDM с обоями Neonix.
- Терминал: чёрный фон, неоновая палитра.

## Позже

- Вайфу-маскот: положить PNG в `assets/`, добавить `Image("waifu.png")` в `neonix.script`.
- Свои иконки и курсоры.
- Анимация «код печатается» — можно заменить статичный фон на последовательность кадров.
