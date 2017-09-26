#загружаем исходную БД
source("get_data.R")


#определяем долю стран в товарообороте за 2016,
#чтобы исключить из анализа "миноритарных" партнеров
turnover_2016 <- bind_data %>%
  group_by_at(vars(1:3)) %>%
  summarize(total = sum(`Trade Value (US$)`)) %>%
  spread(key = `Trade Flow`, value = total) %>%
  filter(Period == "2016") %>%
  mutate(share = (Export + Import) / sum(Export + Import))

#страны с доле менее 0,5% в обороте значительно увеличивают
#разброс индексов изменения экспорта по товарным группам
minor_partners <-
  turnover_2016$Partner[turnover_2016$share <= 0.006]


export <- bind_data %>% filter(`Trade Flow` == "Export") %>%
  spread(key = Period, value = `Trade Value (US$)`)

#после изменения формата данных для позиций,
#по которым #отсутствовали поставки в 2013,
#но появились в 2016, #в БД появляются NA.
#заменяем на 0 для последующих операций суммирования
export[is.na(export)] <- 0


#список товарных групп
grouped_codes <-
  read_csv("codes.csv", col_types = cols("code" = col_integer()))


export_grouped <-
  export %>% left_join(grouped_codes, by = c("Commodity Code" = "code")) %>%
  select(-`Trade Flow`) %>%
  group_by(Partner, group) %>%
  summarise(y2013 = sum(`2013`), y2016 = sum(`2016`)) %>%
  mutate(growth = y2016 / y2013 - 1)

#расчитываем среднюю для ЕС по всем 28 странам,
#потом исключаем из выборки "миноритариев"
export_grouped_eu <- export_grouped %>%
  group_by(group) %>%
  summarize(
    Partner = "EU28",
    y2013 = sum(y2013),
    y2016 = sum(y2016),
    growth = y2016 / y2013 - 1
  ) %>%
  bind_rows(export_grouped, .) %>%
  filter(!(Partner %in% minor_partners))


#экспорт/импорт в абсолютных цифрах
#за исключением стран - "миноритариев"
exim_data  <- bind_data %>%
  group_by_at(vars(1:3)) %>%
  summarize(total = sum(`Trade Value (US$)`) / 1e+09) %>%
  spread(key = `Trade Flow`, value = total) %>%
  filter(!(Partner %in% minor_partners))


#запись файлов для создания графики
write_csv(export_grouped_eu, "export_growth.csv")
write_csv(exim_data, "exim_absolute.csv")
