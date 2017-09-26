library(jsonlite)
library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(magrittr)


#получаем список стран с кодами comtrade.un.org
#для подстановки в ссылку
json_url <- "https://comtrade.un.org/data/cache/partnerAreas.json"

json_raw <- fromJSON(json_url)

country_codes <- as_tibble(json_raw[[2]])

eu_countries <-
  c(
    "Austria",
    "Belgium",
    "Bulgaria",
    "Croatia",
    "Cyprus",
    "Czechia",
    "Denmark",
    "Estonia",
    "Finland",
    "France",
    "Germany",
    "Greece",
    "Hungary",
    "Ireland",
    "Italy",
    "Latvia",
    "Lithuania",
    "Luxembourg",
    "Malta",
    "Netherlands",
    "Poland",
    "Portugal",
    "Romania",
    "Slovakia",
    "Slovenia",
    "Spain",
    "Sweden",
    "United Kingdom"
  )

eu_codes <- country_codes$id[country_codes$text %in% eu_countries]


#ресурс comtrade.un.org имеет ограничение на сложность запроса,
#поэтому разбиваем запрос для 2016 на два полугодия
half_year <-
  c(
    "201601%2C201602%2C201603%2C201604%2C201605%2C201606",
    "201607%2C201608%2C201609%2C201610%2C201611%2C201612"
  )


df_list_2013 <- list()
df_list_2016 <- list()


#за один раз выгружаем данные по одной стране
#отдельно для каждых 6-ти месяцев
#создаем ссылку для загрузки на странице
#https://comtrade.un.org/api/swagger/ui/index#!/Data/Data_GetData
for (i in seq_along(eu_codes)) {
  for (j in seq_along(half_year)) {
    request_url_2016 <-
      paste(
        "https://comtrade.un.org/api/get?r=804&ps=",
        half_year[j],
        "&p=",
        eu_codes[i],
        "&rg=1%2C2&cc=AG2&fmt=csv&freq=monthly",
        sep = ""
      )

    df_monthly_2016 <-
      read_csv(
        request_url_2016,
        trim_ws = TRUE,
        col_types = cols(`Commodity Code` = col_integer())
      ) %>%
      select(3, 8, 13, 22, 32) %>%
      filter(`Commodity Code` <= 97)

    df_annual_2016 <- df_monthly_2016 %>%
      group_by_at(vars(2:4)) %>%
      summarise(`Trade Value (US$)` = sum(as.numeric(`Trade Value (US$)`))) %>%
      mutate(Period = "2016") %>%
      #для данных по 2013 годы в это поле вписаны значения
      #Export/Import, а не Exports/Imports, поєтому приводим
      #к единому формату
      within(`Trade Flow` <-
               str_sub(`Trade Flow`, 1, nchar(`Trade Flow`) - 1))


    Sys.sleep(3)


    #для каждой страны имеем в итоге две отдельных таблицы
    #для каждого полугодия
    df_list_2016[[length(df_list_2016) + 1]] <- df_annual_2016
  }
}


out_2016 <- as_tibble(bind_rows(df_list_2016)) %>%
  group_by(`Trade Flow`, Partner, `Commodity Code`, Period) %>%
  #т.к. для каждой страны имеем по одной записи для каждого
  #полугодия, итоговую таблицу еще раз суммируем
  summarise(`Trade Value (US$)` = sum(as.numeric(`Trade Value (US$)`)))


#название страны отличается в БД за 2013 и 2016
out_2016$Partner[out_2016$Partner == "Czech Rep."] <-
  "Czechia"

#повторяем операции для выборки данных за 2013
for (i in seq_along(eu_codes)) {
  request_url_2013 <-
    paste(
      "https://comtrade.un.org/api/get?r=804&ps=2013&p=",
      eu_codes[i],
      "&rg=1%2C2&cc=ag2&fmt=csv&freq=annual",
      sep = ""
    )

  df_annual_2013 <-
    read_csv(
      request_url_2013,
      trim_ws = TRUE,
      col_types = cols(Period = col_character(), `Commodity Code` = col_integer())
    ) %>%
    select(3, 8, 13, 22, 32) %>%
    filter(`Commodity Code` <= 97)


  Sys.sleep(3)


  df_list_2013[[i]] <- df_annual_2013
}


out_2013 <- as_tibble(bind_rows(df_list_2013))

out_2013$`Trade Value (US$)` <-
  as.numeric(out_2013$`Trade Value (US$)`)


#индекс цен Пааше
source("calc_index.R")


#приводин показатели для 2013 к ценам 2016
#путем умножения на индекс для каждой группы
#по соответствующим направлениям торговли
out_2013 %<>% left_join(index, by = c("Commodity Code" = "code", "Trade Flow" = "trade")) %>%
  mutate(`Trade Value (US$)` = `Trade Value (US$)` * i_2013_to_2016) %>%
  select(-i_2013_to_2016)


#итоговая БД
bind_data <- bind_rows(out_2013, out_2016)
