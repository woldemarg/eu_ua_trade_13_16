library(rvest)

urls <-
  c(
    "http://www.ukrstat.gov.ua/operativ/operativ2016/zd/in_fiz/in_fiz_u/in_fiz_1316_u.htm",
    "http://www.ukrstat.gov.ua/operativ/operativ2015/zd/in_fiz/in_fiz_u/in_fiz_1315_u.htm",
    "http://www.ukrstat.gov.ua/operativ/operativ2014/zd/in_fiz/in_fiz_u/in_fiz_1314_u.htm"
  )


df_list <- list()


#собираем все таблицы в один список
for (i in seq_along(urls)) {
  html_page <-
    read_html(urls[i])

  table_raw <- html_page %>%
    html_nodes("table") %>%
    .[[2]] %>%
    html_table(fill = TRUE)


  df_flat <- table_raw %>% select(1, 4:5) %>%
    tail(-4)

  colnames(df_flat) <- c("code_name", "export", "import")


  df_long <-
    df_flat %>% gather("export", "import", key = "trade", value = "index") %>%
    mutate(index = as.numeric(str_replace(index, ",", ".")) / 100,
           #четыре цифры года содержатся в ссылке
           year = str_extract(urls[i], "\\d{4}"))


  df_list[[i]] <- df_long
}


#преобразуем поле year в колонки для последующего
#удобного перемножения цепных индексов
out <- as_tibble(bind_rows(df_list)) %>%
  separate(code_name, into = c("code", "name"), sep = 2) %>%
  select(-name) %>%
  spread(key = year, value = index)


#получаем базовый индекс для кадой группы товаров
#путем последовательного перемножения цепных индексов
index <-
  out %>% mutate(i_2013_to_2016 = `2014` * `2015` * `2016`) %>%
  select(-3:-5)


#преобразуем поля для обеспечения совместимости
#с данными из comtrade.un.org
index$code <- as.integer(index$code)
str_sub(index$trade, 1, 1) <-
  str_to_upper(str_sub(index$trade, 1, 1))
