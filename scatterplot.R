library(ggplot2)
library(ggrepel)


#загружаем исходные данные
source("data_wrangl.R")


#диагональ из 0 под углом 45 нельзя отобразить
#в логарифмических координатах на графике, поэтому
#для расчета точек линии берем экстремумы из БД
ab_line <-
  data.frame(x = c(
    min(exim_data$Export, exim_data$Import),
    max(exim_data$Export, exim_data$Import)
  ),
  y = c(
    min(exim_data$Export, exim_data$Import),
    max(exim_data$Export, exim_data$Import)
  ))


#отобразим на графике полупрозрачный хвост
#от 2013 к 2016 году. Для этого каждую линию
#разбиваем на множество (50) сегментов,
#каждому из которых задаем свой уроыенб прозрачности
exim_alpha <-
  exim_data %>% arrange(Partner, Period) %>%
  bind_cols(al = rep(c(0.05, 0.95), nrow(exim_data) / 2))


exim_points <- data.frame(
  export = double(),
  import = double(),
  al = double(),
  country = character(),
  stringsAsFactors = FALSE
)

#расчет по примеру из кники (стр. 67)
#http://ms.mcmaster.ca/~bolker/misc/ggplot2-book.pdf
for (i in levels(factor(exim_alpha[[2]]))) {

  current_country <- exim_alpha[exim_alpha$Partner == i,]

  xgrid <-
    with(current_country, seq(min(Export), max(Export), length = 25))

  interp <- data.frame(
    export = xgrid,
    import = approx(current_country$Export, current_country$Import, xout = xgrid)$y,
    al = approx(current_country$Export, current_country$al, xout = xgrid)$y
  ) %>%
    mutate(country = i)

  #собираем пересчитанные сегменты для
  #каждой сраны в новую таблицу
  exim_points <- bind_rows(exim_points, interp)
}

png(filename = "turnover_change.png", width = 800, height = 800)

#проект графики
ggplot() +
  geom_path(
    data = exim_points,
    aes(
      x = export,
      y = import,
      alpha = al,
      group = country
    ),
    size = 1,
    colour = "#3A3F4A"
  ) +
  guides(alpha = FALSE) +
  geom_point(
    data = exim_data %>% filter(Period == "2016"),
    mapping = aes(x = Export, y = Import),
    size = 1,
    colour = "#3A3F4A"
  ) +
  geom_text_repel(
    data = exim_data %>% filter(Period == "2016"),
    mapping = aes(x = Export, y = Import, label = Partner),
    size = 3
  ) +
  geom_line(data = ab_line,
            aes(x = x, y = y),
            color = "#3A3F4A",
            alpha = 0.5) +
  coord_equal() +
  coord_trans(x = "log2", y = "log2") +
  theme_minimal()

dev.off()
