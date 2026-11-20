# R Visual Lab: generate GitHub Pages site from real R plots.
# Usage: Rscript build.R
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(DT)

heroes_url <- "https://raw.githubusercontent.com/Pozdniakov/tidy_stats/master/data/heroes_information.csv"
meta_url <- "https://raw.githubusercontent.com/Pozdniakov/tidy_stats/master/data/meta_dataset.txt"
if (!file.exists("heroes.csv")) download.file(heroes_url, "heroes.csv", mode = "wb")
if (!file.exists("meta_dataset.txt")) download.file(meta_url, "meta_dataset.txt", mode = "wb")
heroes <- read.csv("heroes.csv", na.strings = c("-", "-99", "NA", ""), check.names = TRUE)
meta <- read.delim("meta_dataset.txt", check.names = TRUE)
stopifnot(all(c("Height", "Weight", "Gender") %in% names(heroes)))
stopifnot(all(c("Design", "Effect_size", "Outcome_age", "SE") %in% names(meta)))
weight <- na.omit(heroes$Weight)
poli <- subset(meta, Design == "Policy Change")

if (!dir.exists("r-assets")) dir.create("r-assets")
sections <- list(`13` = character(), `14` = character(), `15` = character())
esc <- function(s) {
  s <- gsub("&", "&amp;", s, fixed = TRUE)
  s <- gsub("<", "&lt;", s, fixed = TRUE)
  s <- gsub(">", "&gt;", s, fixed = TRUE)
  s <- gsub('"', "&quot;", s, fixed = TRUE)
  s
}
add_plot <- function(chapter, id, title, code, kind = "base") {
  message("Building: ", id)
  path <- paste0("r-assets/", id, if (kind == "widget") ".html" else ".png")
  # Evaluate the same source code that is presented on the page.
  expr <- parse(text = code)
  if (kind == "widget") {
    widget <- eval(expr, envir = .GlobalEnv)
    htmlwidgets::saveWidget(widget, path, selfcontained = FALSE)
    visual <- sprintf('<iframe src="%s" loading="lazy" title="%s"></iframe>', path, esc(title))
  } else {
    grDevices::png(path, width = 1000, height = 650, res = 120)
    tryCatch(eval(expr, envir = .GlobalEnv), finally = grDevices::dev.off())
    visual <- sprintf('<img src="%s" alt="%s">', path, esc(title))
  }
  # Only base R and ggplot2 plots are live-editable. HTML widgets stay as built widgets.
  editor <- if (kind == "widget") {
    sprintf('<details><summary>R-код (просмотр)</summary><pre>%s</pre></details>', esc(code))
  } else {
    sprintf(paste0('<details class="edit-box"><summary>Изменить R-код</summary>',
      '<textarea class="r-code" spellcheck="false" aria-label="R-код для %s">%s</textarea>',
      '<div class="actions"><button type="button" class="run-code" data-kind="%s">Выполнить R</button>',
      '<button type="button" class="reset-code">Вернуть исходный</button></div>',
      '<div class="run-status" role="status">webR запустится при первом выполнении кода.</div>',
      '<pre class="console-output" hidden></pre></details>'), esc(title), esc(code), kind)
  }
  html <- sprintf('<section class="plot" id="%s"><h2>%s</h2><div class="visual">%s<canvas class="live-canvas" hidden></canvas></div>%s</section>',
                  id, esc(title), visual, editor)
  sections[[as.character(chapter)]] <<- c(sections[[as.character(chapter)]], html)
}

# 13. Base R — examples from chapter 13.
add_plot(13, "base-scatter", "13.1 · Диаграмма рассеяния", 'plot(heroes$Height, heroes$Weight)')
add_plot(13, "iris-pairs", "13.1 · Матрица диаграмм iris", 'plot(iris[, -5])')
add_plot(13, "hist-default", "13.2 · Гистограмма", 'hist(weight)')
for (n in c(4, 30, 100)) {
  add_plot(13, paste0("hist-", n), paste0("13.2 · Гистограмма, breaks = ", n),
           sprintf('hist(weight, breaks = %d)', n))
}
add_plot(13, "base-box", "13.3 · Ящик с усами", 'boxplot(Weight ~ Gender, data = heroes)')

# 14. ggplot2 — step-by-step pie chart from chapter 14.
add_plot(14, "gg-bar", "14.3 · Столбчатая диаграмма", 'print(ggplot(heroes) + geom_bar(aes(x = Gender, fill = Gender)))', "ggplot")
add_plot(14, "gg-onebar", "14.3 · Один составной столбец", 'print(ggplot(heroes) + geom_bar(aes(x = "", fill = Gender)))', "ggplot")
add_plot(14, "gg-pie", "14.3 · Круговая диаграмма", paste0(
  'print(ggplot(heroes) +\n',
  '  geom_bar(aes(x = "", fill = Gender)) +\n',
  '  coord_polar(theta = "y") +\n',
  '  theme_void() +\n',
  '  labs(title = "Gender distributions for superheroes"))'), "ggplot")
# Meta-analysis plot: the actual dataset from the methodical chapter, not superheroes.
meta_code <- paste0(
  'print(ggplot(subset(meta, Design != "School Age Cutoff"),\n',
  '  aes(x = Outcome_age, y = Effect_size, size = 1/(SE^2),\n',
  '      colour = Design, fill = Design)) +\n',
  '  geom_point(alpha = .55) +\n',
  '  geom_hline(yintercept = 0, linetype = "dotted") +\n',
  '  geom_smooth(method = "lm", linewidth = .5, alpha = .25) +\n',
  '  scale_x_continuous(breaks = c(20,30,40,50,60,70,80)) +\n',
  '  scale_colour_brewer(palette = "Set1") +\n',
  '  scale_fill_brewer(palette = "Set1") +\n',
  '  guides(size = "none", colour = "none", fill = "none") +\n',
  '  labs(title = "Effect of education as a function of age",\n',
  '       x = "Age at outcome test (years)",\n',
  '       y = "Gain for 1 year of education (IQ points)") +\n',
  '  theme_bw() +\n',
  '  theme(plot.title = element_text(hjust = .5)) +\n',
  '  facet_grid(Design ~ .))')
add_plot(14, "gg-meta", "14.4 · Мета-анализ: слои, размеры, фасетки, палитра", meta_code, "ggplot")

# 15. Interactive HTML widgets saved by R, visible on GitHub Pages.
p <- ggplot(heroes, aes(x = Height, y = Weight, colour = Gender)) + geom_point(na.rm = TRUE) + theme_minimal()
add_plot(15, "ggplotly", "15.2 · ggplotly()", 'plotly::ggplotly(p)', "widget")
add_plot(15, "plotly", "15.2 · plot_ly()", 'plotly::plot_ly(heroes, x = ~Height, y = ~Weight, color = ~Gender, type = "scatter", mode = "markers")', "widget")
add_plot(15, "datatable", "15.3 · htmlwidgets: DT", 'DT::datatable(heroes, options = list(pageLength = 10, scrollX = TRUE))', "widget")

html <- c(
  '<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
  '<title>Визуализация данных в R</title><link rel="stylesheet" href="style.css"></head><body>',
  '<h1>Визуализация данных в R</h1>',
  '<p>Графики построены в R. В разделах 13 и 14 можно изменить код и выполнить его прямо в браузере.</p>',
  '<nav><button class="tab" data-tab="13" aria-selected="true">13. Base R</button>',
  '<button class="tab" data-tab="14" aria-selected="false">14. ggplot2</button>',
  '<button class="tab" data-tab="15" aria-selected="false">15. Динамические визуализации</button></nav>')
for (n in c(13, 14, 15)) {
  html <- c(html, sprintf('<div class="tab-panel" id="panel-%s" %s>', n, if(n == 13) '' else 'hidden'),
            sections[[as.character(n)]], '</div>')
}
html <- c(html, '<script type="module" src="web-editor.js"></script></body></html>')
writeLines(enc2utf8(html), "index.html", useBytes = TRUE)
message("Done: index.html and r-assets/. Serve from HTTP or upload to GitHub Pages.")
