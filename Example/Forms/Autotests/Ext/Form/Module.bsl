﻿#Область НаборТестов

&НаКлиенте
Процедура ЗаполнитьНаборТестов(ЮнитТест, Интерактивно = Ложь) Экспорт
	
	ЮнитТест.Добавить("Тест_ИнициализацияБиблиотеки", "Инициализация библиотеки");
	ЮнитТест.Добавить("Тест_ПарсингЗаголовковФичи", "Парсинг заголовков фичи");
	ЮнитТест.Добавить("Тест_ПарсингПримитивногоСценария", "Парсинг примитивного сценария");
	ЮнитТест.Добавить("Тест_СценарийНаАнглийскомЯзыке", "Сценарий на английском языке");
	ЮнитТест.Добавить("Тест_СоставныеКлючевыеСлова", "Составные ключевые слова");
	ЮнитТест.Добавить("Тест_НесколькоСценариев", "Несколько сценариев");
	ЮнитТест.Добавить("Тест_РаботаСТаблицами", "Работа с таблицами");
	ЮнитТест.Добавить("Тест_СканированиеПапки", "Сканирование папки");
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_ИнициализацияБиблиотеки(Ожидается) Экспорт
	
	ИмяКомпоненты = "AddIn." + Ожидается.ИдентификаторКомпоненты + ".GherkinParser";
	ВК = Ожидается.Тест().Компонента("GherkinParser").ИмеетТип(ИмяКомпоненты).Вернуть();
	Ожидается.Тест().Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_ПарсингЗаголовковФичи(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	
	ТекстСценария =
	"# language: ru
	|# encoding: utf-8
	|# Пример комментария
	|# Второй комментарий
	|@tree
	|@TagValue
	|Функциональность: Автотест
	|  Описание функционала
	|  простого сценария
	|";
	
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	
	Ожидается.Тест("Язык сценария").Что(ДанныеФайла).Получить("language").Равно("ru");
	ДанныеФичи = Ожидается.Тест("Данные фичи").Что(ДанныеФайла).Получить("feature").Вернуть();
	Ожидается.Тест("Заголовок фичи").Что(ДанныеФичи).Получить("name").Равно("Автотест");
	
	Ожидается.Тест("Пример комментария").Что(ДанныеФичи).Получить("comments", 0).Равно("Пример комментария");
	Ожидается.Тест("Второй комментарий").Что(ДанныеФичи).Получить("comments", 1).Равно("Второй комментарий");
	
	Ожидается.Тест("Первый тег @tree").Что(ДанныеФичи).Получить("tags", 0).Равно("tree");
	Ожидается.Тест("Второй тег @TagValue").Что(ДанныеФичи).Получить("tags", 1).Равно("TagValue");
	
	Ожидается.Тест("Первая строка описания").Что(ДанныеФичи).Получить("description", 0).Равно("Описание функционала");
	Ожидается.Тест("Вторая строка описания").Что(ДанныеФичи).Получить("description", 1).Равно("простого сценария");
	
	ВременныйФайл = ПолучитьИмяВременногоФайла();
	ЗаписьТекста = Новый ЗаписьТекста(ВременныйФайл, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	Ожидается.Тест("Парсинг файла сценария").Что(ВК).Функц("ПрочитатьФайл", ВременныйФайл).Получить("feature").Получить("name").Равно("Автотест");
	УдалитьФайлы(ВременныйФайл);
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_ПарсингПримитивногоСценария(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	Ожидается.Тест().Что(ВК).Получить("ПримитивноеЭкранирование").Равно(Ложь);
	
	ТекстСценария =
	"@ТегФичи
	|Функциональность: Параметры шага
	|@ТегКонтекста
	|Контекст: 
	|	И здесь 'Параметр\' кавычки' текст 'Значение'
	|	И здесь ""Параметр\"" кавычки"" текст ""Значение""
	|	И здесь <Параметр\> скобка> текст <Значение>
	|	И здесь ""Перенос\nстроки"" текст <Параметр>
	|	И здесь ""Символ\tтабуляции"" текст ""Знак""
	|	И здесь ""Обратный \\ слэш""
	|	И здесь ""Прямой \/ слэш""
	|	И здесь 20.01.2021 дата
	|	И здесь 21/03/2020 дата
	|	И здесь 18743.5 число
	|	И здесь 854,54 число
	|@ОшибочныйТег
	|";
	
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	Ожидается.Тест("Количество тегов").Что(ДанныеФайла).Получить("feature", "tags").Функц("Количество").Равно(1);
	Ожидается.Тест("Тег фичи").Что(ДанныеФайла).Получить("feature", "tags", 0).Равно("ТегФичи");
	Ожидается.Тест("Тег контекста").Что(ДанныеФайла).Получить("background", "tags", 0).Равно("ТегКонтекста");
	
	СписокШагов = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("background", "items").Вернуть();
	Ожидается.Тест("Одинарные кавычки").Что(СписокШагов).Получить(0, "tokens", 2, "text").Равно("Параметр' кавычки");
	Ожидается.Тест("Двойные кавычки").Что(СписокШагов).Получить(1, "tokens", 2, "text").Равно("Параметр"" кавычки");
	Ожидается.Тест("Угловые скобки").Что(СписокШагов).Получить(2, "tokens", 2, "text").Равно("Параметр> скобка");
	Ожидается.Тест("Перенос строки").Что(СписокШагов).Получить(3, "tokens", 2, "text").Равно("Перенос" + Символы.ПС + "строки");
	Ожидается.Тест("Символ табуляции").Что(СписокШагов).Получить(4, "tokens", 2, "text").Равно("Символ" + Символы.Таб + "табуляции");
	Ожидается.Тест("Обратный слэш").Что(СписокШагов).Получить(5, "tokens", 2, "text").Равно("Обратный \ слэш");
	Ожидается.Тест("Прямой слэш").Что(СписокШагов).Получить(6, "tokens", 2, "text").Равно("Прямой / слэш");

	Ожидается.Тест("Символ: одинарные кавычки").Что(СписокШагов).Получить(0, "tokens", 2, "symbol").Равно("'");
	Ожидается.Тест("Символ: двойные кавычки").Что(СписокШагов).Получить(1, "tokens", 2, "symbol").Равно("""");
	Ожидается.Тест("Параметр дата").Что(СписокШагов).Получить(7, "tokens", 2, "text").Равно("20.01.2021");
	Ожидается.Тест("Параметр дата").Что(СписокШагов).Получить(8, "tokens", 2, "text").Равно("21/03/2020");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(9, "tokens", 2, "text").Равно("18743.5");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(10, "tokens", 2, "text").Равно("854,54");

	Ожидается.Тест().Что(ВК).Установить("ПримитивноеЭкранирование", Истина).Получить("ПримитивноеЭкранирование").Равно(Истина);
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	СписокШагов = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("background", "items").Вернуть();
	Ожидается.Тест("Одинарные кавычки").Что(СписокШагов).Получить(0, "tokens", 2, "text").Равно("Параметр' кавычки");
	Ожидается.Тест("Двойные кавычки").Что(СписокШагов).Получить(1, "tokens", 2, "text").Равно("Параметр"" кавычки");
	Ожидается.Тест("Перенос строки").Что(СписокШагов).Получить(3, "tokens", 2, "text").Равно("Перенос" + Символы.ПС + "строки");
	Ожидается.Тест("Символ табуляции").Что(СписокШагов).Получить(4, "tokens", 2, "text").Равно("Символ" + Символы.Таб + "табуляции");
	Ожидается.Тест("Обратный слэш").Что(СписокШагов).Получить(5, "tokens", 2, "text").Равно("Обратный \\ слэш");
	Ожидается.Тест("Прямой слэш").Что(СписокШагов).Получить(6, "tokens", 2, "text").Равно("Прямой \/ слэш");

	Ожидается.Тест().Что(ВК).Установить("ПримитивноеЭкранирование", Ложь).Получить("ПримитивноеЭкранирование").Равно(Ложь);

КонецПроцедуры

&НаКлиенте
Процедура Тест_СценарийНаАнглийскомЯзыке(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	
	ТекстСценария =
	"# language: en
	|@tree
	|
	|Feature: Purchase some staff
	|
	|	As a customer
	|	I want to purchase some goods
	|	To be happy with it
	|
	|Background:
	|	Given TestClient is connected
	|	И русские ключевые слова игнорируются
	|
	|Scenario: Create purchase order	
	|	When I start to make document
	|			When I create new purchase order	
	|			Then I choose vendor 'Norcal Distribution Company'
	|			
	|	And I add some goods		
	|			And I add new line in order
	|			And I choose item ""Coleman 600W Wind Turbine""
	|			And I choose quantity 1
	|			And I choose delivery date 30.10.2016
	|			
	|	And I finish my document		
	|			And I save the order
	|			And I print the order
	|";
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	Ожидается.Тест("Язык сценария").Что(ДанныеФайла).Получить("language").Равно("en");
	ДанныеФичи = Ожидается.Тест("Данные фичи").Что(ДанныеФайла).Получить("feature").Вернуть();
	Ожидается.Тест("Заголовок фичи").Что(ДанныеФичи).Получить("name").Равно("Purchase some staff");
	
	ШагиКонтекста = Ожидается.Тест("Шаги контекста").Что(ДанныеФайла).Получить("background", "items").Вернуть();
	Ожидается.Тест("Это ключевое слово").Что(ШагиКонтекста).Получить(0, "tokens", 0, "type").Равно("Keyword");
	Ожидается.Тест("Тип ключевого слова").Что(ШагиКонтекста).Получить(0, "keyword", "type").Равно("Given");
	Ожидается.Тест("Текст на русском").Что(ШагиКонтекста).Получить(1, "name").Равно("И русские ключевые слова игнорируются");
	
	ШагиСценария = Ожидается.Тест("Разбор сценария").Что(ДанныеФайла).Получить("scenarios", 0, "items").Вернуть();
	Ожидается.Тест("Шаги первого уровня").Что(ШагиСценария).Функц("Количество").Равно(3);
	Ожидается.Тест("Шаги второго уровня").Что(ШагиСценария).Получить(0, "Items").Функц("Количество").Равно(2);
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_СоставныеКлючевыеСлова(Ожидается) Экспорт
	
	МассивСлов = Новый Массив;
	МассивСлов.Добавить("И");
	МассивСлов.Добавить("И это");
	МассивСлов.Добавить("И здесь");
	МассивСлов.Добавить("И тогда");
	МассивСлов.Добавить("И это значит");
	МассивСлов.Добавить("Тогда получится");
	МассивСлов.Добавить("Тогда");
	МассивСлов.Добавить("Когда");
	МассивСлов.Добавить("Всегда");
	
	Функционал = Новый Массив;
	Функционал.Добавить("Тестируемый функционал");
	
	Контекст = Новый Массив;
	Контекст.Добавить("Контекст сценария");
	
	РусскиеСлова = Новый Структура("feature,background,and", Функционал, Контекст, МассивСлов);
	
	КлючевыеСлова = Новый Структура("ru", РусскиеСлова);
	КлючевыеСлова = ЗаписатьСтрокуJSON(КлючевыеСлова);
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", КлючевыеСлова).Вернуть();
	
	ТекстСценария =
	"Тестируемый функционал: Ключевые слова
	|
	|Контекст сценария:
	|	КОГДА я начинаю тест
	|	ТОГДА можно использовать свои слова
	|	И это значит я добавляю новые строки
	|	И это я решаю какими они должны быть
	|	И тогда можно их использовать всегда
	|	И здесь я вижу новые возможности
	|	тогДА полУчитСЯ понятный текст
	|";
	
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	СписокШагов = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("background", "items").Вернуть();
	
	Ожидается.Тест("Простое ключевое слово").Что(СписокШагов).Получить(0, "keyword", "text").Равно("Когда");
	Ожидается.Тест("Простое ключевое слово").Что(СписокШагов).Получить(1, "keyword", "text").Равно("Тогда");
	Ожидается.Тест("Слово внутри шага").Что(СписокШагов).Получить(0, "tokens", 1, "type").Равно("Operator");
	Ожидается.Тест("Составное ключевое слово").Что(СписокШагов).Получить(2, "keyword", "text").Равно("И это значит");
	Ожидается.Тест("Элемент ключевого слова").Что(СписокШагов).Получить(2, "tokens", 2, "type").Равно("Keyword");
	Ожидается.Тест("Элемент ключевого слова").Что(СписокШагов).Получить(2, "tokens", 2, "text").Равно("значит");
	Ожидается.Тест("После ключевого слова").Что(СписокШагов).Получить(2, "tokens", 3, "type").Равно("Operator");
	Ожидается.Тест("После ключевого слова").Что(СписокШагов).Получить(2, "tokens", 3, "text").Равно("я");
	Ожидается.Тест("Регистр не имеет значения").Что(СписокШагов).Получить(6, "keyword", "text").Равно("Тогда получится");
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_НесколькоСценариев(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	Ожидается.Тест().Что(ВК).Получить("ПримитивноеЭкранирование").Равно(Ложь);
	
	ТекстСценария =
	"Функционал: Сценарии
	|	Несколько сценариев
	|	в одном файле
	|
	|Контекст: 
	|	Допустим я стартую тесты
	|
	|@ТегСценария1
	|Сценарий: Один шаг
	|	Когда я начинаю движение
	|	Тогда я делаю один шаг
	|
	|@ТегСценария2
	|Сценарий: Наблюдатель
	|	Если я открываю окно
	|		Затем я смотрю вдаль
	|		Тогда я вижу цель
	|";
	
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	
	Сценарии = Ожидается.Тест("Список сценариев").Что(ДанныеФайла).Получить("scenarios").Вернуть();
	Ожидается.Тест("Список сценариев").Что(Сценарии).Функц("Количество").Равно(2);
	Ожидается.Тест("Первый сценарий: шаги").Что(Сценарии).Получить(0, "items").Функц("Количество").Равно(2);
	Ожидается.Тест("Первый сценарий: тэги").Что(Сценарии).Получить(0, "tags", 0).Равно("ТегСценария1");
	Ожидается.Тест("Второй сценарий: шаги").Что(Сценарии).Получить(1, "items").Функц("Количество").Равно(1);
	Ожидается.Тест("Второй сценарий: тэги").Что(Сценарии).Получить(1, "tags", 0).Равно("ТегСценария2");
	Ожидается.Тест("Следующий уровень").Что(Сценарии).Получить(1, "items", 0, "items").Функц("Количество").Равно(2);

КонецПроцедуры

&НаКлиенте
Процедура Тест_РаботаСТаблицами(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	
	ТекстСценария =
	"Функциональность: Таблицы
	|@ТегКонтекста
	|Контекст: 
	|	Когда в таблице ""Список"" я перехожу к строке:
	|		| Дата       | Наименование         | Кол-во | Цена  | Сумма | 
	|		| 23.01.2021 | 'Управляемая форма'  | 10     | 20.43 | 204.3 |
	|		| 25/01/2021 | 'Регистр накопления' | 5      | 18.20 |    91 |
	|		| 10.01.21   | 'Параметры\nсеанса'  | 2      | 15.37 | 30.74 |
	|
	|		||
	|
	|		| ПервоеСлагаемое | ВтороеСлагаемое  | Сумма |
	|		|       2.5       |      4.5         |   7   |
	|		|       2         |      3           |   5   |
	|		|       10        |      20          |  30   |
	|	
	|	Тогда в подвале документа появляются итоги:
	|		| Описание           | Пример значения   |
	|		| Одинарные кавычки  | 'Разде|литель'    |
	|		| Двойные кавычки    | ""Разде|литель""  |
	|		| Угловые скобки     | <Угловые|скобки>  |
	|		| Двойная кавычка    | ""                |
	|		| Одинарная кавычка  | '                 |
	|		| Символ             | $                 |
	|		| Спецсимволы        | \t\r\n            |
	|		| Табулятор          | \t                |
	|		| Перенос строки     | \n                |
	|		| Разделитель        | \|                |
	|		| Экранирование      | Текст\|Строки     |
	|";
	
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	СписокШагов = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("background", "items").ИмеетТип("Массив").Вернуть();
	
	Ожидается.Тест("Количество таблиц шага").Что(СписокШагов).Получить(0, "tables").Функц("Количество").Равно(3);
	Ожидается.Тест("Количество колонок в таблице").Что(СписокШагов).Получить(0, "tables", 0, "head").Функц("Количество").Равно(5);
	Ожидается.Тест("Шапка пустой таблицы").Что(СписокШагов).Получить(0, "tables", 1, "head").Функц("Количество").Равно(0);
	Ожидается.Тест("Тело пустой таблицы").Что(СписокШагов).Получить(0, "tables", 1, "body").Функц("Количество").Равно(0);
	
	СтрокиТаблицы = Ожидается.Тест("Таблица примеров").Что(СписокШагов).Получить(1, "tables", 0, "body").Вернуть();
	Ожидается.Тест("Одинарные кавычки").Что(СтрокиТаблицы).Получить(0, 1).Равно("Разде|литель");
	Ожидается.Тест("Двойные кавычки").Что(СтрокиТаблицы).Получить(1, 1).Равно("Разде|литель");
	Ожидается.Тест("Угловые скобки").Что(СтрокиТаблицы).Получить(2, 1).Равно("Угловые|скобки");
	Ожидается.Тест("Двойная кавычка").Что(СтрокиТаблицы).Получить(3, 1).Равно("""");
	Ожидается.Тест("Одинарная кавычка").Что(СтрокиТаблицы).Получить(4, 1).Равно("'");
	Ожидается.Тест("Одиночный символ").Что(СтрокиТаблицы).Получить(5, 1).Равно("$");
//	Ожидается.Тест("Спецсимволы").Что(СтрокиТаблицы).Получить(6, 1).Равно(Символы.Таб + Символы.ВК + Символы.ПС);
//	Ожидается.Тест("Символ табуляции").Что(СтрокиТаблицы).Получить(7, 1).Равно(Символы.Таб);
//	Ожидается.Тест("Перенос строки").Что(СтрокиТаблицы).Получить(8, 1).Равно(Символы.ПС);
//	Ожидается.Тест("Разделитель ячеек").Что(СтрокиТаблицы).Получить(9, 1).Равно("|");
//	Ожидается.Тест("Разделитель ячеек").Что(СтрокиТаблицы).Получить(10, 1).Равно("Текст|Строки");
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_СканированиеПапки(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	
	ВременнаяПапка = ПолучитьИмяВременногоФайла();
	УдалитьФайлы(ВременнаяПапка);
	СоздатьКаталог(ВременнаяПапка);
	
	ВременнаяПапка = ВременнаяПапка + ПолучитьРазделительПути();
	ВложеннаяПапка = ВременнаяПапка + "вложенная папка" + ПолучитьРазделительПути();
	СоздатьКаталог(ВложеннаяПапка);
	
	ТекстСценария =
	"# language: ru
	|Функционал: Русский язык
	|";
	
	ФайлНаРусском = ВременнаяПапка + "Русский язык.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлНаРусском, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	ТекстСценария =
	"# language: en
	|Feature: English
	|";
	
	ФайлНаАнглийском = ВложеннаяПапка + "Английский язык.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлНаАнглийском, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	ДанныеПапки = Ожидается.Тест("Сканирование папки").Что(ВК).Функц("ПрочитатьПапку", ВременнаяПапка).JSON().Вернуть();
	Ожидается.Тест("Файл на английском").Что(ДанныеПапки).Получить(0, "filepath").Равно(ФайлНаАнглийском);
	Ожидается.Тест("Файл на русском").Что(ДанныеПапки).Получить(1, "filepath").Равно(ФайлНаРусском);
	Ожидается.Тест("Английский язык").Что(ДанныеПапки).Получить(0, "feature", "name").Равно("English");
	Ожидается.Тест("Русский язык").Что(ДанныеПапки).Получить(1, "feature", "name").Равно("Русский язык");
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедуры

&НаСервере
Функция ПолучитьКлючевыеСлова()
	
	ИмяМакета = "Keywords";
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект");
	КлючевыеСлова = ОбработкаОбъект.ПолучитьМакет(ИмяМакета);
	Поток = КлючевыеСлова.ОткрытьПотокДляЧтения();
	ИмяВременногоФайла = ПолучитьИмяВременногоФайла();
	УдалитьФайлы(ИмяВременногоФайла);
	ИмяВременнойПапки = ИмяВременногоФайла + ПолучитьРазделительПути();
	ЧтениеZipФайла = Новый ЧтениеZipФайла(Поток);
	Для каждого ЭлементZip из ЧтениеZipФайла.Элементы Цикл
		ЧтениеZipФайла.Извлечь(ЭлементZip, ИмяВременнойПапки);
		ИмяВременногоФайла = ИмяВременнойПапки + ЭлементZip.ПолноеИмя;
		ДвоичныеДанные = Новый ДвоичныеДанные(ИмяВременногоФайла);
		Поток = ДвоичныеДанные.ОткрытьПотокДляЧтения();
		ЧтениеТекста = Новый ЧтениеТекста(Поток, КодировкаТекста.UTF8);
		ТекстМакета = ЧтениеТекста.Прочитать();
		ЧтениеТекста.Закрыть();
		УдалитьФайлы(ИмяВременногоФайла);
		УдалитьФайлы(ИмяВременнойПапки);
		Возврат ТекстМакета;
	КонецЦикла;
	
КонецФункции

&НаКлиенте
Функция ПрочитатьСтрокуJSON(ТекстJSON)
	
	Если ПустаяСтрока(ТекстJSON) Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	ПоляДаты = Новый Массив;
	ПоляДаты.Добавить("CreationDate");
	ПоляДаты.Добавить("date");
	
	ЧтениеJSON = Новый ЧтениеJSON();
	ЧтениеJSON.УстановитьСтроку(ТекстJSON);
	Возврат ПрочитатьJSON(ЧтениеJSON, , ПоляДаты);
	
КонецФункции

&НаКлиенте
Функция ЗаписатьСтрокуJSON(Данные)
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON, Данные);
	Возврат ЗаписьJSON.Закрыть();
	
КонецФункции

#КонецОбласти
