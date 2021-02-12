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
	ЮнитТест.Добавить("Тест_СтруктураСценария", "Структура сценария");
	ЮнитТест.Добавить("Тест_СканированиеПапки", "Сканирование папки");
	ЮнитТест.Добавить("Тест_ФильтрацияСценариев", "Фильтрация сценариев");
	ЮнитТест.Добавить("Тест_ЭкспортныеСценарии", "Экспортные сценарии");
	
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
	
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("ПрочитатьТекст", ТекстСценария).JSON().Вернуть();
	
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
	|	И здесь 24868 число
	|	И это `""1""` текст
	|Сценарий: Передать <Параметр> в сценарий
	|	И здесь <Параметр> и 20.01.2021, 3 параметра
	|@ОшибочныйТег
	|";
	
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("ПрочитатьТекст", ТекстСценария).JSON().Вернуть();
	Ожидается.Тест("Количество тегов").Что(ДанныеФайла).Получить("feature", "tags").Функц("Количество").Равно(1);
	Ожидается.Тест("Тег фичи").Что(ДанныеФайла).Получить("feature", "tags", 0).Равно("ТегФичи");
	Ожидается.Тест("Тег контекста").Что(ДанныеФайла).Получить("background", "tags", 0).Равно("ТегКонтекста");
	
	СписокШагов = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("background", "steps").Вернуть();
	Ожидается.Тест("Одинарные кавычки").Что(СписокШагов).Получить(0, "tokens", 2, "text").Равно("Параметр' кавычки");
	Ожидается.Тест("Двойные кавычки").Что(СписокШагов).Получить(1, "tokens", 2, "text").Равно("Параметр"" кавычки");
	Ожидается.Тест("Угловые скобки").Что(СписокШагов).Получить(2, "tokens", 2, "text").Равно("Параметр> скобка");
	Ожидается.Тест("Перенос строки").Что(СписокШагов).Получить(3, "tokens", 2, "text").Равно("Перенос" + Символы.ПС + "строки");
	Ожидается.Тест("Символ табуляции").Что(СписокШагов).Получить(4, "tokens", 2, "text").Равно("Символ" + Символы.Таб + "табуляции");
	Ожидается.Тест("Обратный слэш").Что(СписокШагов).Получить(5, "tokens", 2, "text").Равно("Обратный \ слэш");
	Ожидается.Тест("Прямой слэш").Что(СписокШагов).Получить(6, "tokens", 2, "text").Равно("Прямой / слэш");

	Ожидается.Тест("Символ: одинарные кавычки").Что(СписокШагов).Получить(0, "tokens", 2, "symbol").Равно("'");
	Ожидается.Тест("Символ: двойные кавычки").Что(СписокШагов).Получить(1, "tokens", 2, "symbol").Равно("""");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(7, "tokens", 2, "type").Равно("Date");
	Ожидается.Тест("Параметр дата").Что(СписокШагов).Получить(7, "tokens", 2, "text").Равно("20.01.2021");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(8, "tokens", 2, "type").Равно("Date");
	Ожидается.Тест("Параметр дата").Что(СписокШагов).Получить(8, "tokens", 2, "text").Равно("21/03/2020");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(9, "tokens", 2, "type").Равно("Number");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(9, "tokens", 2, "text").Равно("18743.5");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(10, "tokens", 2, "text").Равно("854,54");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(10, "tokens", 2, "type").Равно("Number");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(11, "tokens", 2, "text").Равно("24868");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(11, "tokens", 2, "type").Равно("Number");
	Ожидается.Тест("Параметр число").Что(СписокШагов).Получить(12, "tokens", 2, "text").Равно("""1""");

	Ожидается.Тест().Что(ВК).Установить("ПримитивноеЭкранирование", Истина).Получить("ПримитивноеЭкранирование").Равно(Истина);
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	СписокШагов = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("background", "steps").Вернуть();
	Ожидается.Тест("Одинарные кавычки").Что(СписокШагов).Получить(0, "tokens", 2, "text").Равно("Параметр' кавычки");
	Ожидается.Тест("Двойные кавычки").Что(СписокШагов).Получить(1, "tokens", 2, "text").Равно("Параметр"" кавычки");
	Ожидается.Тест("Перенос строки").Что(СписокШагов).Получить(3, "tokens", 2, "text").Равно("Перенос" + Символы.ПС + "строки");
	Ожидается.Тест("Символ табуляции").Что(СписокШагов).Получить(4, "tokens", 2, "text").Равно("Символ" + Символы.Таб + "табуляции");
	Ожидается.Тест("Обратный слэш").Что(СписокШагов).Получить(5, "tokens", 2, "text").Равно("Обратный \\ слэш");
	Ожидается.Тест("Прямой слэш").Что(СписокШагов).Получить(6, "tokens", 2, "text").Равно("Прямой \/ слэш");

	Ожидается.Тест().Что(ВК).Установить("ПримитивноеЭкранирование", Ложь).Получить("ПримитивноеЭкранирование").Равно(Ложь);
	
	Сценарий = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("scenarios", 0).Вернуть();
	Ожидается.Тест("Заголовок сценария").Что(Сценарий).Получить("name").Равно("Передать <Параметр> в сценарий");
	Ожидается.Тест("Параметр сценария").Что(Сценарий).Получить("params", 0, "text").Равно("Параметр");
	ШагСценария = Ожидается.Тест("Шаги сценария").Что(Сценарий).Получить("steps", 0).Вернуть();
	Ожидается.Тест("Параметры шага").Что(ШагСценария).Получить("params").Функц("Количество").Равно(3);
	Ожидается.Тест("Параметры 1").Что(ШагСценария).Получить("params", 0, "text").Равно("Параметр");
	Ожидается.Тест("Параметры 2").Что(ШагСценария).Получить("params", 1, "text").Равно("20.01.2021");
	Ожидается.Тест("Параметры 3").Что(ШагСценария).Получить("params", 2, "text").Равно("3");

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
	
	ШагиКонтекста = Ожидается.Тест("Шаги контекста").Что(ДанныеФайла).Получить("background", "steps").Вернуть();
	Ожидается.Тест("Это ключевое слово").Что(ШагиКонтекста).Получить(0, "tokens", 0, "type").Равно("Keyword");
	Ожидается.Тест("Тип ключевого слова").Что(ШагиКонтекста).Получить(0, "keyword", "type").Равно("Given");
	Ожидается.Тест("Текст на русском").Что(ШагиКонтекста).Получить(1, "name").Равно("И русские ключевые слова игнорируются");
	
	Ожидается.Тест("Заголовок сценария").Что(ДанныеФайла).Получить("scenarios", 0, "name").Равно("Create purchase order");
	ШагиСценария = Ожидается.Тест("Разбор сценария").Что(ДанныеФайла).Получить("scenarios", 0, "steps").Вернуть();
	Ожидается.Тест("Шаги первого уровня").Что(ШагиСценария).Функц("Количество").Равно(3);
	Ожидается.Тест("Шаги второго уровня").Что(ШагиСценария).Получить(0, "steps").Функц("Количество").Равно(2);
	
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
	СловаКомпоненты = Ожидается.Тест().Что(ВК).Получить("КлючевыеСлова").Получить("ru").Вернуть();
	Ожидается.Тест().Что(СловаКомпоненты).Получить("feature", 0).Равно(РусскиеСлова["feature"][0]);
	Ожидается.Тест().Что(СловаКомпоненты).Получить("background", 0).Равно(РусскиеСлова["background"][0]);
	Ожидается.Тест().Что(СловаКомпоненты).Получить("and").Функц("Количество").Равно(РусскиеСлова["and"].Количество());
	
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
	СписокШагов = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("background", "steps").Вернуть();
	
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
	|	Тогда я делаю 1 шаг
	|
	|@ТегСценария2
	|Сценарий: Наблюдатель
	|	Если я открываю окно
	|		Затем я смотрю вдаль
	|		Тогда я вижу цель
	|";
	
	
	ДанныеФайла = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).JSON().Вернуть();
	Ожидается.Тест("Сниппет первого шага контекста").Что(ДанныеФайла).Получить("background", "steps", 0, "snippet").Равно("ястартуютесты");
	
	Сценарии = Ожидается.Тест("Список сценариев").Что(ДанныеФайла).Получить("scenarios").Вернуть();
	Ожидается.Тест("Список сценариев").Что(Сценарии).Функц("Количество").Равно(2);
	
	Ожидается.Тест("Первый сценарий: заголовок").Что(Сценарии).Получить(0, "name").Равно("Один шаг");
	Ожидается.Тест("Первый сценарий: сниппет").Что(Сценарии).Получить(0, "snippet").Равно("одиншаг");
	Ожидается.Тест("Первый сценарий: тэги").Что(Сценарии).Получить(0, "tags", 0).Равно("ТегСценария1");
	Ожидается.Тест("Первый сценарий: шаги").Что(Сценарии).Получить(0, "steps").Функц("Количество").Равно(2);
	Ожидается.Тест("Сниппет шага 1").Что(Сценарии).Получить(0, "steps", 0, "snippet").Равно("яначинаюдвижение");
	Ожидается.Тест("Сниппет шага 2").Что(Сценарии).Получить(0, "steps", 1, "snippet").Равно("яделаюшаг");
	
	Ожидается.Тест("Второй сценарий: заголовок").Что(Сценарии).Получить(1, "name").Равно("Наблюдатель");
	Ожидается.Тест("Второй сценарий: сниппет").Что(Сценарии).Получить(1, "snippet").Равно("наблюдатель");
	Ожидается.Тест("Второй сценарий: тэги").Что(Сценарии).Получить(1, "tags", 0).Равно("ТегСценария2");
	Ожидается.Тест("Второй сценарий: шаги").Что(Сценарии).Получить(1, "steps").Функц("Количество").Равно(1);
	Ожидается.Тест("Следующий уровень").Что(Сценарии).Получить(1, "steps", 0, "steps").Функц("Количество").Равно(2);

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
	СписокШагов = Ожидается.Тест("Список шагов").Что(ДанныеФайла).Получить("background", "steps").ИмеетТип("Массив").Вернуть();
	
	Ожидается.Тест("Количество таблиц шага").Что(СписокШагов).Получить(0, "tables").Функц("Количество").Равно(3);
	Ожидается.Тест("Количество колонок в таблице").Что(СписокШагов).Получить(0, "tables", 0, "head").Функц("Количество").Равно(5);
	Ожидается.Тест("Шапка пустой таблицы").Что(СписокШагов).Получить(0, "tables", 1, "head").Функц("Количество").Равно(0);
	Ожидается.Тест("Тело пустой таблицы").Что(СписокШагов).Получить(0, "tables", 1, "body").Функц("Количество").Равно(0);
	
	СтрокиТаблицы = Ожидается.Тест("Таблица примеров").Что(СписокШагов).Получить(1, "tables", 0, "body").Вернуть();
	Ожидается.Тест("Одинарные кавычки").Что(СтрокиТаблицы).Получить(0, 1, "text").Равно("Разде|литель");
	Ожидается.Тест("Двойные кавычки").Что(СтрокиТаблицы).Получить(1, 1, "text").Равно("Разде|литель");
	Ожидается.Тест("Угловые скобки").Что(СтрокиТаблицы).Получить(2, 1, "text").Равно("Угловые|скобки");
	Ожидается.Тест("Двойная кавычка").Что(СтрокиТаблицы).Получить(3, 1, "text").Равно("""");
	Ожидается.Тест("Одинарная кавычка").Что(СтрокиТаблицы).Получить(4, 1, "text").Равно("'");
	Ожидается.Тест("Одиночный символ").Что(СтрокиТаблицы).Получить(5, 1, "text").Равно("$");
//	Ожидается.Тест("Спецсимволы").Что(СтрокиТаблицы).Получить(6, 1).Равно(Символы.Таб + Символы.ВК + Символы.ПС);
//	Ожидается.Тест("Символ табуляции").Что(СтрокиТаблицы).Получить(7, 1).Равно(Символы.Таб);
//	Ожидается.Тест("Перенос строки").Что(СтрокиТаблицы).Получить(8, 1).Равно(Символы.ПС);
//	Ожидается.Тест("Разделитель ячеек").Что(СтрокиТаблицы).Получить(9, 1).Равно("|");
//	Ожидается.Тест("Разделитель ячеек").Что(СтрокиТаблицы).Получить(10, 1).Равно("Текст|Строки");
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_СтруктураСценария(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	
	ТекстСценария =
	"Функционал: Структура сценария
	|
	|Контекст: 
	|	Допустим я стартую тесты
	|
	|@ПредметДействие
	|Структура сценария: Беру и делаю
	|	Когда у меня есть <Предмет>
	|	Тогда я могу <Действие>
	|
	|Примеры:
	|	| Предмет     | Действие     |
	|	| ""Книга""   | ""Чиать""    |
	|	| ""Ручка""   | ""Писать""   |
	|	| ""Кисть""   | ""Рисовать"" |
	|	| ""Телефон"" | ""Звонить""  |
	|
	|@СложениеЧисел
	|Структура сценария: Сложение чисел
	|	Когда Я передал первый параметр сложения <ПервоеСлагаемое>
	|	И Я передал второй параметр сложения <ВтороеСлагаемое>
	|	Тогда Я получу Сумму <Сумма>
    |
	|	Примеры:
	|		| ПервоеСлагаемое | ВтороеСлагаемое | Сумма |
	|		|       2.5       |      4.5        |   7   |
	|		|       2         |      3          |   5   |
	|		|       10        |      20         |  30   |
	|";
	
	НаборСтруктур = Ожидается.Тест("Парсинг строки").Что(ВК).Функц("Прочитать", ТекстСценария).Получить("scenarios").Вернуть();
	
	Ожидается.Тест("Количество шагов").Что(НаборСтруктур).Получить(0, "steps").Функц("Количество").Равно(2);
	ТаблицаПримеров = Ожидается.Тест("Первая структура").Что(НаборСтруктур).Получить(0, "examples", "tables", 0).Вернуть();
	Ожидается.Тест("Количество строк примера").Что(ТаблицаПримеров).Получить("body").Функц("Количество").Равно(4);
	Ожидается.Тест("Содержание строк").Что(ТаблицаПримеров).Получить("body", 0, 0, "text").Равно("""Книга""");
	
	Ожидается.Тест("Количество шагов").Что(НаборСтруктур).Получить(1, "steps").Функц("Количество").Равно(3);
	ТаблицаПримеров = Ожидается.Тест("Первая структура").Что(НаборСтруктур).Получить(1, "examples", "tables", 0).Вернуть();
	Ожидается.Тест("Количество строк примера").Что(ТаблицаПримеров).Получить("body").Функц("Количество").Равно(3);
	Ожидается.Тест("Содержание строк").Что(ТаблицаПримеров).Получить("body", 0, 0, "text").Равно("2.5");
	
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
	|@Русский
	|Функционал: Русский язык
	|";
	
	ФайлНаРусском = ВременнаяПапка + "Русский язык.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлНаРусском, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	ТекстСценария =
	"# language: en
	|@English
	|@Английский
	|Feature: English
	|";
	
	ФайлНаАнглийском = ВложеннаяПапка + "Английский язык.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлНаАнглийском, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	МассивПапок = Новый Массив;
	МассивПапок.Добавить(ВременнаяПапка);
	МассивПапок.Добавить(ВложеннаяПапка);
	Директории = ЗаписатьСтрокуJSON(МассивПапок);
	
	ДанныеПапки = Ожидается.Тест("Сканирование одной папки").Что(ВК).Функц("ПрочитатьПапку", ВременнаяПапка).JSON().Вернуть();
	Ожидается.Тест("Количество файлов").Что(ДанныеПапки).Функц("Количество").Равно(2);
	Ожидается.Тест("Файл на английском").Что(ДанныеПапки).Получить(0, "filename").Равно(ФайлНаАнглийском);
	Ожидается.Тест("Файл на русском").Что(ДанныеПапки).Получить(1, "filename").Равно(ФайлНаРусском);
	Ожидается.Тест("Английский язык").Что(ДанныеПапки).Получить(0, "feature", "name").Равно("English");
	Ожидается.Тест("Русский язык").Что(ДанныеПапки).Получить(1, "feature", "name").Равно("Русский язык");
	
	ДанныеПапки = Ожидается.Тест("Сканирование массива папок").Что(ВК).Функц("ПрочитатьПапку", Директории).JSON().Вернуть();
	Ожидается.Тест("Количество файлов").Что(ДанныеПапки).Функц("Количество").Равно(2);
	Ожидается.Тест("Файл на английском").Что(ДанныеПапки).Получить(0, "filename").Равно(ФайлНаАнглийском);
	Ожидается.Тест("Файл на русском").Что(ДанныеПапки).Получить(1, "filename").Равно(ФайлНаРусском);
	Ожидается.Тест("Английский язык").Что(ДанныеПапки).Получить(0, "feature", "name").Равно("English");
	Ожидается.Тест("Русский язык").Что(ДанныеПапки).Получить(1, "feature", "name").Равно("Русский язык");
	
	
	ТекстСценария =
	"# language: en
	|@English
	|Feature: English
	|";
	
	ФайлEnglish = ВременнаяПапка + "English.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлEnglish, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	ФильтрТегов = "{""include"":[""Русский""]}";
	ДанныеПапки = Ожидается.Тест(ФильтрТегов).Что(ВК).Функц("ПрочитатьПапку", Директории, , ФильтрТегов).JSON().Вернуть();
	Ожидается.Тест("Количество файлов").Что(ДанныеПапки).Функц("Количество").Равно(1);
	Ожидается.Тест("Найденный файл").Что(ДанныеПапки).Получить(0, "filename").Равно(ФайлНаРусском);
	
	ФильтрТегов = "{""include"":[""English""]}";
	ДанныеПапки = Ожидается.Тест(ФильтрТегов).Что(ВК).Функц("ПрочитатьПапку", Директории, , ФильтрТегов).JSON().Вернуть();
	Ожидается.Тест("Количество файлов").Что(ДанныеПапки).Функц("Количество").Равно(2);
	Ожидается.Тест("Найденный файл").Что(ДанныеПапки).Получить(1, "filename").Равно(ФайлНаАнглийском);
	Ожидается.Тест("Найденный файл").Что(ДанныеПапки).Получить(0, "filename").Равно(ФайлEnglish);
	
	ФильтрТегов = "{""include"":[""English""],""exclude"":[""Английский""]}";
	ДанныеПапки = Ожидается.Тест(ФильтрТегов).Что(ВК).Функц("ПрочитатьПапку", Директории, , ФильтрТегов).JSON().Вернуть();
	Ожидается.Тест("Количество файлов").Что(ДанныеПапки).Функц("Количество").Равно(1);
	Ожидается.Тест("Найденный файл").Что(ДанныеПапки).Получить(0, "filename").Равно(ФайлEnglish);
	
	ФильтрТегов = "{""exclude"":[""English"",""Английский""]}";
	ДанныеПапки = Ожидается.Тест(ФильтрТегов).Что(ВК).Функц("ПрочитатьПапку", Директории, , ФильтрТегов).JSON().Вернуть();
	Ожидается.Тест("Количество файлов").Что(ДанныеПапки).Функц("Количество").Равно(1);
	Ожидается.Тест("Найденный файл").Что(ДанныеПапки).Получить(0, "filename").Равно(ФайлНаРусском);
	
	УдалитьФайлы(ФайлEnglish);
	УдалитьФайлы(ФайлНаРусском);
	УдалитьФайлы(ФайлНаАнглийском);
	УдалитьФайлы(ВложеннаяПапка);
	УдалитьФайлы(ВременнаяПапка);
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_ФильтрацияСценариев(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	
	ВременнаяПапка = ПолучитьИмяВременногоФайла();
	УдалитьФайлы(ВременнаяПапка);
	СоздатьКаталог(ВременнаяПапка);
	
	ВременнаяПапка = ВременнаяПапка + ПолучитьРазделительПути();
	ВложеннаяПапка = ВременнаяПапка + "вложенная папка" + ПолучитьРазделительПути();
	СоздатьКаталог(ВложеннаяПапка);
	
	ТекстСценария =
	"# language: ru
	|@Русский
	|Функционал: Русский язык
	|@Видео
	|Сценарий: Видео
	|@Книга
	|Сценарий: Книга
	|@Фото
	|Сценарий: Фото
	|";
	
	ФайлНаРусском = ВременнаяПапка + "Русский язык.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлНаРусском, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	ТекстСценария =
	"# language: en
	|@English
	|@Английский
	|Feature: English
	|@Video
	|@Видео
	|Scenario: Video
	|@Book
	|@Книга
	|Scenario: Book
	|@Photo
	|Scenario: Photo
	|";
	
	ФайлНаАнглийском = ВложеннаяПапка + "Английский язык.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлНаАнглийском, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	ТекстСценария =
	"# language: en
	|@English
	|Feature: English
	|@Video
	|Scenario: Video
	|@Book
	|Scenario: Book
	|@Photo
	|Scenario: Photo
	|";
	
	ФайлEnglish = ВременнаяПапка + "English.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлEnglish, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстСценария);
	ЗаписьТекста.Закрыть();
	
	ФильтрТегов = "{""include"":[""English"",""Фото""],""exclude"":[""Видео""]}";
	ДанныеПапки = Ожидается.Тест(ФильтрТегов).Что(ВК).Функц("ПрочитатьПапку", ВременнаяПапка, , ФильтрТегов).JSON().Вернуть();
	Ожидается.Тест("Количество файлов").Что(ДанныеПапки).Функц("Количество").Равно(3);
	Ожидается.Тест("Количество сценариев").Что(ДанныеПапки).Получить(0, "scenarios").Функц("Количество").Равно(3);
	Ожидается.Тест("Количество сценариев").Что(ДанныеПапки).Получить(1, "scenarios").Функц("Количество").Равно(2);
	Ожидается.Тест("Количество сценариев").Что(ДанныеПапки).Получить(2, "scenarios").Функц("Количество").Равно(1);
	
	ФильтрТегов = "{""include"":[""Видео""],""exclude"":[""Video""]}";
	ДанныеПапки = Ожидается.Тест(ФильтрТегов).Что(ВК).Функц("ПрочитатьПапку", ВременнаяПапка, , ФильтрТегов).JSON().Вернуть();
	Ожидается.Тест("Количество файлов").Что(ДанныеПапки).Функц("Количество").Равно(1);
	Ожидается.Тест("Найденный файл").Что(ДанныеПапки).Получить(0, "filename").Равно(ФайлНаРусском);
	Ожидается.Тест("Количество сценариев").Что(ДанныеПапки).Получить(0, "scenarios").Функц("Количество").Равно(1);
	Ожидается.Тест("Сниппет сценария").Что(ДанныеПапки).Получить(0, "scenarios", 0, "snippet").Равно("видео");
	
	УдалитьФайлы(ФайлEnglish);
	УдалитьФайлы(ФайлНаРусском);
	УдалитьФайлы(ФайлНаАнглийском);
	УдалитьФайлы(ВложеннаяПапка);
	УдалитьФайлы(ВременнаяПапка);
	
КонецПроцедуры

&НаКлиенте
Процедура Тест_ЭкспортныеСценарии(Ожидается) Экспорт
	
	ВК = Ожидается.Тест().Компонента("GherkinParser").Установить("КлючевыеСлова", ПолучитьКлючевыеСлова()).Вернуть();
	
	ВременнаяПапка = ПолучитьИмяВременногоФайла();
	УдалитьФайлы(ВременнаяПапка);
	СоздатьКаталог(ВременнаяПапка);
	ВременнаяПапка = ВременнаяПапка + ПолучитьРазделительПути();
	
	ТекстФайла =
	"# language: ru
	|@ExportScenarios
	|Функционал: Подсценарии
	|Сценарий: Я читаю книгу
	|	Допустим я беру книгу
	|	Тогда я открываю страницу
	|	И я читаю всю ночь напролет
	|Сценарий: ""Вечером"" я слушаю радио ""FM""
	|	Допустим я ""Вечером"" включаю радио
	|	Если я нахожу волну ""FM""
	|	Тогда я делаю звук громче
	|";
	
	ФайлПодсценариев = ВременнаяПапка + "Экспортируемые подсценарии.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлПодсценариев, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстФайла);
	ЗаписьТекста.Закрыть();
	
	
	ТекстФайла =
	"# language: ru
	|@ExportScenarios
	|Функционал: Рекурсия
	|Сценарий: Я провожу свой досуг
	|	Пусть ""Днем"" я слушаю радио ""Юность""
	|	К тому же я читаю книгу ""Два капитана""
	|";
	
	ФайлРекурсии = ВременнаяПапка + "Рекурсивные подсценарии.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ФайлРекурсии, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстФайла);
	ЗаписьТекста.Закрыть();
	
	ТекстФайла =
	"# language: ru
	|@ГлавныйСценарий
	|Функционал: Досуг
	|Сценарий: 
	|	Пусть я читаю книгу
	|	Также ""Утром"" я слушаю радио ""Маяк""
	|	Иначе я провожу свой досуг
	|";
	
	ОсновнойФайл = ВременнаяПапка + "Вызов подсценариев.feature";
	ЗаписьТекста = Новый ЗаписьТекста(ОсновнойФайл, КодировкаТекста.UTF8);
	ЗаписьТекста.Записать(ТекстФайла);
	ЗаписьТекста.Закрыть();
	
	ДанныеФайла = Ожидается.Тест("Сканирование файла с библиотеками").Что(ВК).Функц("ПрочитатьФайл", ОсновнойФайл, ВременнаяПапка).JSON().Вернуть();
	Ожидается.Тест("Один сценарий из файла").Что(ДанныеФайла).Получить("filename").Равно(ОсновнойФайл);
	ШагиСценария = Ожидается.Тест("Шаги сценария").Что(ДанныеФайла).Получить("scenarios", 0, "steps").Вернуть();
	Ожидается.Тест("Шаги сценария").Что(ШагиСценария).Функц("Количество").Равно(3);
	Ожидается.Тест("Сниппет подсценария").Что(ШагиСценария).Получить(0, "snippet", "key").Равно("ячитаюкнигу");
	ШагиПодсценария = Ожидается.Тест("Подсценарий").Что(ШагиСценария).Получить(0, "snippet", "steps").Вернуть();
	Ожидается.Тест("Шаги подсценария").Что(ШагиПодсценария).Функц("Количество").Равно(3);
	Ожидается.Тест("Шаги подсценария").Что(ШагиПодсценария).Получить(0, "snippet").Равно("яберукнигу");
	Ожидается.Тест("Шаги подсценария").Что(ШагиПодсценария).Получить(1, "snippet").Равно("яоткрываюстраницу");
	Ожидается.Тест("Шаги подсценария").Что(ШагиПодсценария).Получить(2, "snippet").Равно("ячитаювсюночьнапролет");
	Ожидается.Тест("Очищаем кэш одного файла").Что(ВК).Проц("ОчиститьКэш", ФайлПодсценариев);
	
	ДанныеФайла = Ожидается.Тест("Сканирование файла с кэшем").Что(ВК).Функц("ПрочитатьФайл", ОсновнойФайл).JSON().Вернуть();
	Ожидается.Тест("Один сценарий из файла").Что(ДанныеФайла).Получить("filename").Равно(ОсновнойФайл);
	ШагиСценария = Ожидается.Тест("Шаги сценария").Что(ДанныеФайла).Получить("scenarios", 0, "steps").Вернуть();
	Ожидается.Тест("Сниппет не найден без кэша").Что(ШагиСценария).Получить(0, "snippet").Равно("ячитаюкнигу");
	Ожидается.Тест("Сниппет не найден без кэша").Что(ШагиСценария).Получить(1, "snippet").Равно("яслушаюрадио");
	Ожидается.Тест("Сниппет найден из кэша").Что(ШагиСценария).Получить(2, "snippet", "key").Равно("япровожусвойдосуг");
	Ожидается.Тест("Полностью очищаем кэш").Что(ВК).Проц("ОчиститьКэш");
	
	ДанныеФайла = Ожидается.Тест("Сканирование файла без кэша").Что(ВК).Функц("ПрочитатьФайл", ОсновнойФайл).JSON().Вернуть();
	Ожидается.Тест("Один сценарий из файла").Что(ДанныеФайла).Получить("filename").Равно(ОсновнойФайл);
	ШагиСценария = Ожидается.Тест("Шаги сценария").Что(ДанныеФайла).Получить("scenarios", 0, "steps").Вернуть();
	Ожидается.Тест("Без кэша нет сниппета").Что(ШагиСценария).Получить(0, "snippet").Равно("ячитаюкнигу");
	Ожидается.Тест("Без кэша нет сниппета").Что(ШагиСценария).Получить(1, "snippet").Равно("яслушаюрадио");
	Ожидается.Тест("Без кэша нет сниппета").Что(ШагиСценария).Получить(2, "snippet").Равно("япровожусвойдосуг");

	ФильтрТегов = "{""include"":[""ГлавныйСценарий""]}";
	ДанныеПапки = Ожидается.Тест("Сканирование папки").Что(ВК).Функц("ПрочитатьПапку", ВременнаяПапка, ВременнаяПапка, ФильтрТегов).JSON().Вернуть();
	Ожидается.Тест("Один сценарий по фильтру").Что(ДанныеПапки).Получить(0, "scenarios").Функц("Количество").Равно(1);
	ШагиСценария = Ожидается.Тест("Первый шаг сценария").Что(ДанныеПапки).Получить(0, "scenarios", 0, "steps").Вернуть();
	Ожидается.Тест("Шаги сценария").Что(ШагиСценария).Функц("Количество").Равно(3);
	
	Ожидается.Тест("Сниппет подсценария").Что(ШагиСценария).Получить(0, "snippet", "key").Равно("ячитаюкнигу");
	ШагиПодсценария = Ожидается.Тест("Подсценарий").Что(ШагиСценария).Получить(0, "snippet", "steps").Вернуть();
	Ожидается.Тест("Шаги подсценария").Что(ШагиПодсценария).Функц("Количество").Равно(3);
	Ожидается.Тест("Шаги подсценария").Что(ШагиПодсценария).Получить(0, "snippet").Равно("яберукнигу");
	Ожидается.Тест("Шаги подсценария").Что(ШагиПодсценария).Получить(1, "snippet").Равно("яоткрываюстраницу");
	Ожидается.Тест("Шаги подсценария").Что(ШагиПодсценария).Получить(2, "snippet").Равно("ячитаювсюночьнапролет");
	
	СниппетПодсценария = Ожидается.Тест("Сниппет подсценария").Что(ШагиСценария).Получить(1, "snippet").Вернуть();
	Ожидается.Тест("Ключ сниппета").Что(СниппетПодсценария).Получить("key").Равно("яслушаюрадио");
	Ожидается.Тест("Первый параметр").Что(СниппетПодсценария).Получить("params", "Вечером", "text").Равно("Утром");
	Ожидается.Тест("Второй параметр").Что(СниппетПодсценария).Получить("params", "fm", "text").Равно("Маяк");
	ШагиСниппета = Ожидается.Тест("Шаги подсценария").Что(СниппетПодсценария).Получить("steps").Вернуть();
	Ожидается.Тест("Первый шаг с параметром").Что(ШагиСниппета).Получить(0, "text").Равно("Допустим я ""Утром"" включаю радио");
	Ожидается.Тест("Второй шаг с параметром").Что(ШагиСниппета).Получить(1, "text").Равно("Если я нахожу волну ""Маяк""");
	Ожидается.Тест("Третий шаг").Что(ШагиСниппета).Получить(2, "text").Равно("Тогда я делаю звук громче");
	
	УдалитьФайлы(ОсновнойФайл);
	УдалитьФайлы(ФайлРекурсии);
	УдалитьФайлы(ФайлПодсценариев);
	УдалитьФайлы(ВременнаяПапка);
	
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
