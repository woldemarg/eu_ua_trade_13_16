Анализ изменений в торговле между Украиной и ЕС в 2013-2016гг.
1)	Сбор данных с помощью get_data.R
Данные загружаем чере API-интерфейс портала ЮНКТАД (https://comtrade.un.org/api/swagger/ui/index#!/Data/Data_GetData). Особенности загрузки – статистика за 2016 год собирается из помесячных данных
2)	Расчет на индекс цен в файле calc_index.R
Методика расчет индексов Гостстатом Украині – здесь https://ukrstat.org/uk/metod_polog/metod_doc/2005/419/metod.htm
Таблицу цепніх индексов зв исследуемій период – здесь http://www.ukrstat.gov.ua/operativ/operativ2016/zd/in_fiz/in_fiz_u/in_fiz_1316_u.htm
Переход к сопоставимым ценам – здесь http://www.aup.ru/books/m163/3_2_7.htm

3)	Обработка и форматирование данных в файле data_wrangl.R
Преобразование данных в форматы, пригодные для последующего создания графики. На этом этапе также отсееваем страны с минимальной долей в товарообороте по 2016 г., так как расчетные показатели торговли по ним слишком отклоняются от среднего значения. Расчеты изменения экспорта по группам товаров – из файла сodes.csv (http://www.ucentralasia.org/Content/downloads/UCA-IPPA-WP12-TradeCreationAndDiversion-Rus.pdf) стр. 20

4)	Создание графики по товарообороту scatterplot.R
Идея размещения стран в координатной сетке экспорт/импорт и использование log-осей - http://novyden.blogspot.com/2017/06/logarithmic-scale-explained-with-us.html?m=1
Особенность – для создания эффекта градиента  каждая линия на графике разбита на множество отрезков, каждый со своим alpha-уровнем. Прием описан здесь http://ms.mcmaster.ca/~bolker/misc/ggplot2-book.pdf стр 52-53

5)	Создание графики по экспорту step_chart.R
Идея и трюк работы с geom_step()http://textura.in.ua/post/162910213800/kyivweatherhistorybarcode
 
