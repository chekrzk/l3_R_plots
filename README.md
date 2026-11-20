# Визуализация данных в R — главы 13–15

## Содержимое

- `three_chapters.R` — отдельный обычный R-скрипт, последовательно воспроизводящий основные практические примеры по трём главам учебника (включая мета-анализ из 14.4).
- `build.R` — создаёт сайт с настоящими PNG и HTML-графиками на основе R.
- `index.html` — создаётся/перезаписывается скриптом `build.R`.
- `web-editor.js` — редактор R-кода на webR для **Base R и ggplot2**.
- `style.css` — простой CSS без фреймворков.
- `heroes.csv`, `meta_dataset.txt` — файлы загружаются скриптом `build.R` и нужны для webR на сайте.
- `r-assets/` — создаётся скриптом `build.R`, содержит изображения и HTML-виджеты.

## Установка

В RStudio один раз:

```r
install.packages(c("ggplot2", "plotly", "htmlwidgets", "DT", "tidyverse"))
```

`hrbrthemes` — необязательное расширение для последнего примера 14.5 (скрипт его пропускает, если пакет не установлен).

## Сборка сайта

В PowerShell, открытом в папке проекта:

```powershell
Rscript build.R
```

Или в консоли RStudio (при установленной рабочей папке проекта):

```r
source("build.R")
```

Сайт `index.html` **перегенерируется** при сборке. Не редактируйте его вручную — измените `build.R`, `style.css` или `web-editor.js`.

## Локальный просмотр

Для работы редактора **нужен HTTP**, а не открытие `file:///.../index.html` двойным щелчком. В папке проекта выполните:

```powershell
python -m http.server 8000
```

Откройте `http://localhost:8000/`.

На GitHub Pages редактор также работает по HTTPS. Для первого выполнения Base R webR загрузит движок R; для раздела ggplot2 дополнительно установит совместимый пакет ggplot2 прямо в среду WebAssembly браузера. Понадобится интернет. Запуск может занимать время, а некоторые функции и пакеты обычной R несовместимы с webR.

**Редактирование доступно только для PNG-графиков в главах 13 и 14.** Виджеты `ggplotly`, `plot_ly` и `DT` уже интерактивны (масштабирование, наведение, сортировка), но их код на сайте только просматривается: webR не конвертирует HTML-виджеты автоматически в canvas.

## GitHub Pages

Соберите проект локально и загрузите **все файлы**, включая `index.html`, `style.css`, `web-editor.js`, `.nojekyll`, `heroes.csv`, `meta_dataset.txt` и `r-assets/` со всеми вложенными каталогами. GitHub → Settings → Pages → Deploy from a branch → main / root.

## Материалы

- https://pozdniakov.github.io/tidy_stats/220-base_viz.html
- https://pozdniakov.github.io/tidy_stats/230-ggplot2.html
- https://pozdniakov.github.io/tidy_stats/240-dynamic_viz.html
- https://docs.r-wasm.org/webr/latest/examples.html
