# Главы 13, 14, 15: визуализации R
# Запуск в RStudio: Source (или source("three_chapters.R"))
# Один раз: install.packages(c("tidyverse", "plotly", "htmlwidgets"))

library(tidyverse)
library(plotly)
library(htmlwidgets)

heroes <- read_csv(
  "https://raw.githubusercontent.com/Pozdniakov/tidy_stats/master/data/heroes_information.csv",
  na = c("-", "-99", "NA")
)

# 13.1 plot()
plot(heroes$Height, heroes$Weight)
head(iris)
head(iris[, -5])
plot(iris[, -5])

# 13.2 hist()
weight <- heroes %>% drop_na(Weight) %>% pull(Weight)
hist(weight)
hist(weight, breaks = 4)
hist(weight, breaks = 30)
hist(weight, breaks = 100)
1 + floor(log(length(weight), base = 2))
hist(weight, breaks = "FD")
hist(weight, breaks = "Scott")

# 13.3 boxplot()
boxplot(Weight ~ Gender, heroes)

# 14.3 Грамматика графики: от столбцов к круговой диаграмме
ggplot(data = heroes)
almost_empty_ggplot <- ggplot(data = heroes)
almost_empty_ggplot
ggplot(data = heroes) + geom_bar(aes(x = Gender, fill = Gender))
ggplot(data = heroes) + geom_bar(aes(x = "", fill = Gender))
ggplot(data = heroes) + geom_bar(aes(x = "", fill = Gender), width = .2)
ggplot(data = heroes) +
  geom_bar(aes(x = "", fill = Gender)) +
  coord_polar(theta = "y")
ggplot(data = heroes) +
  geom_bar(aes(x = "", fill = Gender)) +
  coord_polar(theta = "y") +
  theme_void() +
  labs(title = "Gender distributions for superheroes")

# 14.4 Мета-анализ образования и интеллекта
meta <- read_tsv(
  "https://raw.githubusercontent.com/Pozdniakov/tidy_stats/master/data/meta_dataset.txt"
)
cpiq <- subset(meta, Design == "Control Prior IQ")
poli <- subset(meta, Design == "Policy Change")
ggplot(data = poli)
ggplot(aes(x = Outcome_age, y = Effect_size), data = poli)
ggplot(aes(x = Outcome_age, y = Effect_size), data = poli) + geom_point()
ggplot(aes(x = Outcome_age, y = Effect_size, size = 1/(SE^2)), data = poli) + geom_point()
ggplot(aes(x = Outcome_age, y = Effect_size, size = 1/(SE^2)), data = poli) + geom_point(alpha = .55)
ggplot(aes(x = Outcome_age, y = Effect_size, size = 1/(SE^2)), data = poli) +
  geom_point(alpha = .55, colour = "#BA1825")
ggplot(aes(x = Outcome_age, y = Effect_size, size = 1/(SE^2)), data = poli) +
  geom_point(alpha = .55, colour = "#BA1825") + geom_smooth()
ggplot(aes(x = Outcome_age, y = Effect_size, size = 1/(SE^2)), data = poli) +
  geom_point(alpha = .55, colour = "#BA1825") + geom_smooth(method = "lm")

ggplot(aes(x = Outcome_age, y = Effect_size, size = 1/(SE^2)), data = poli) +
  geom_point(alpha = .55, colour = "#BA1825") +
  geom_hline(yintercept = 0, linetype = "dotted") +
  geom_smooth(method = "lm", colour = "#BA1825", fill = "#BA1825", linewidth = .5, alpha = .25) +
  theme_bw()

meta_2_gg <- ggplot(
  aes(x = Outcome_age, y = Effect_size, size = 1/(SE^2),
      colour = Design, fill = Design),
  data = filter(meta, Design != "School Age Cutoff")
) +
  geom_point(alpha = .55) +
  geom_hline(yintercept = 0, linetype = "dotted") +
  theme_bw() +
  scale_x_continuous(breaks = c(20, 30, 40, 50, 60, 70, 80)) +
  xlab("Age at outcome test (years)") +
  ylab("Gain for 1 year of education\n(IQ points)") +
  guides(size = "none", colour = "none", fill = "none") +
  geom_smooth(method = "lm", linewidth = .5, alpha = .25) +
  ggtitle("Effect of education as a function of age at the outcome test") +
  theme(plot.title = element_text(hjust = .5)) +
  facet_grid(Design ~ .) +
  scale_colour_brewer(palette = "Set1") +
  scale_fill_brewer(palette = "Set1")
meta_2_gg

# 14.5 Расширение ggplot2: выполнить при наличии пакета
# install.packages("hrbrthemes")
if (requireNamespace("hrbrthemes", quietly = TRUE)) {
  print(meta_2_gg + hrbrthemes::theme_ipsum())
}

# 15.1–15.2 htmlwidgets и plotly
interactive_gg <- ggplotly(meta_2_gg)
interactive_gg

interactive_plot <- plot_ly(
  heroes, x = ~Height, y = ~Weight, color = ~Gender,
  type = "scatter", mode = "markers"
)
interactive_plot

# 15.3 Пример ещё одного HTML-виджета: интерактивная таблица
if (requireNamespace("DT", quietly = TRUE)) {
  DT::datatable(heroes)
}

# При необходимости сохранить виджет в файл:
# htmlwidgets::saveWidget(interactive_plot, "interactive_plot.html", selfcontained = FALSE)
