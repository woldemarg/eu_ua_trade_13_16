library(ggplot2)


#загружаем исходные данные
source("data_wrangl.R")


#задаем порядок отображения товарных групп на графике
#по убыванию индекса прироста экспорта для ЕС28
group_levels <-
  c(
    "ліс і деревина",
    "продукти АПК",
    "споживчі товари",
    "машини і обладнання",
    "руди і метали",
    "хімія і добрива"
  )


#подготовка данных к созданию графика по примеру
#http://textura.in.ua/post/162910213800/kyivweatherhistorybarcode
export_to_draw <- export_grouped_eu %>% mutate(
  group = factor(group, levels = group_levels, ordered = TRUE),
  group_numeric = as.numeric(group)
)

fake_group <- export_to_draw %>%
  filter(group ==  "хімія і добрива") %>%
  mutate(group = "", group_numeric = length(group_levels) + 1)

export_to_draw %<>% bind_rows(fake_group)


png(filename = "export_change.png", width = 800, height = 800)

#проект графики
ggplot(mapping = aes(x = group_numeric, y = growth, group = Partner)) +
  geom_step(
    data = export_to_draw %>% filter(Partner == "EU28"),
    color = "red",
    size = 0.75
  ) +
  geom_step(
    data = export_to_draw %>% filter(Partner != "EU28"),
    color = "#7F8590",
    alpha = 0.3,
    size = 0.75
  )

dev.off()
