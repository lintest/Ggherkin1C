
Перем НаборТестов Экспорт;

Перем ИдентификаторКомпоненты;

Перем ЕстьПроблема, ЕстьОшибка, ЕстьОшибкиПроблемы, ОшибкиПроблемы;

#Область ЭкспортныеМетоды

&НаКлиенте
Процедура Добавить(Знач ИмяМетода, Знач Представление) Экспорт

    НаборТестов.Вставить(Представление, ИмяМетода);
// ОтправитьТест("POST", Представление, "Running");

КонецПроцедуры

&НаКлиенте
Функция ДобавитьШаг(ТекущаяГруппа, Представление) Экспорт

    Возврат Новый Структура("Наименование,Результат,Эталон", Представление);

КонецФункции

&НаКлиенте
Функция ЗаписатьПроблему(ТекущаяГруппа, ТекущаяСтрока, ТекстПроблемы) Экспорт

    ЕстьПроблема = Истина;
    ЕстьОшибкиПроблемы = Истина;

    Если ТекущаяСтрока = Неопределено Тогда
        Наименование = "Неизвестная проблема";
    Иначе
        Наименование = ТекущаяСтрока.Наименование;
    КонецЕсли;

// ОтправитьСообщение(Наименование, "Warning", ТекстПроблемы);
    Представление = ТекущаяСтрока.Наименование + " - " + Строка(ТекстПроблемы);
    ОшибкиПроблемы.Добавить(Новый Структура("Статус,Представление", "ПРОБЛЕМА", Представление));

    Возврат ЭтотОбъект;

КонецФункции

&НаКлиенте
Функция ПрерватьТест(ТекущаяГруппа, ТекущаяСтрока, Результат, Подробности) Экспорт

    ЕстьОшибка = Истина;
    ЕстьОшибкиПроблемы = Истина;

    Если ТекущаяСтрока = Неопределено Тогда
        Наименование = "Неизвестная проблема";
    Иначе
        Наименование = ТекущаяСтрока.Наименование;
    КонецЕсли;

// ОтправитьСообщение(ТекущаяСтрока.Наименование, "Error",
// Строка(Подробности) + Символы.ПС + Строка(Результат));

    Представление = ТекущаяСтрока.Наименование + " - " + Строка(Подробности);
    ОшибкиПроблемы.Добавить(Новый Структура("Статус,Представление", "ОШИБКА", Представление));

    Возврат ЭтотОбъект;

КонецФункции

#КонецОбласти

Процедура ВыполнитьТест(ТекущийТест)

    ЕстьОшибка = Ложь;
    ЕстьПроблема = Ложь;
    ОшибкиПроблемы = Новый Массив;

    xUnitBDD = Новый xUnitBDD;
    xUnitBDD.Инициализация(ЭтотОбъект, ИдентификаторКомпоненты, ТекущийТест);

    Автотесты = Новый Autotests;
    ВремяСтарта = ТекущаяУниверсальнаяДатаВМиллисекундах();

    Попытка
        Выполнить("Автотесты." + ТекущийТест.ИмяМетода + "(xUnitBDD)");
    Исключение
        Информация = ИнформацияОбОшибке();
        Результат = КраткоеПредставлениеОшибки(Информация);
        Подробности = ПодробноеПредставлениеОшибки(Информация);
        ПрерватьТест(ТекущийТест, Неопределено, Результат, Подробности);
    КонецПопытки;

    Статус = ?(ЕстьОшибка ИЛИ ЕстьПроблема, "Failed", "Passed");
    Длительность = ТекущаяУниверсальнаяДатаВМиллисекундах() - ВремяСтарта;
    Если ЕстьОшибка ИЛИ ЕстьПроблема Тогда
        Сообщить("ОШИБКА: " + ТекущийТест.Наименование, СтатусСообщения.Важное);
        Для каждого Стр Из ОшибкиПроблемы Цикл
            Сообщить(" " + Стр.Статус + ": " + Стр.Представление, СтатусСообщения.Важное);
        КонецЦикла;
    Иначе
        Сообщить("УСПЕШНО: " + ТекущийТест.Наименование, СтатусСообщения.Информация);
    КонецЕсли;

// ОтправитьТест("PUT", ТекущийТест.Наименование, Статус, Длительность);

КонецПроцедуры

Процедура ПодключитьМодульФормы(ИмяФормы)

    ИмяФайла = ТекущийСценарий().Каталог 
        + "./../Example/Forms/" 
        + ИмяФормы 
        + "/Ext/Form/Module.bsl";
        
    ПодключитьСценарий(ИмяФайла, ИмяФормы);

КонецПроцедуры    

Процедура ВыполнитьТесты(ИмяБиблиотеки)

    НаборТестов = Новый Соответствие;
    ПодключитьМодульФормы("Autotests");
    ПодключитьМодульФормы("xUnitBDD");

    Автотесты = Новый Autotests;
    Автотесты.ЗаполнитьНаборТестов(ЭтотОбъект);

    ИдентификаторКомпоненты = ИмяБиблиотеки;

    МестоположениеКомпоненты = ТекущийСценарий().Каталог
        + "/../Example/Templates/"
        + ИдентификаторКомпоненты
        + "/Ext/Template.bin";

    ПодключитьВнешнююКомпоненту(МестоположениеКомпоненты, ИдентификаторКомпоненты, ТипВнешнейКомпоненты.Native);

    ЕстьОшибкиПроблемы = Ложь;
    Для каждого ЭлементСписка Из НаборТестов Цикл
        ТекущийТест = Новый Структура;
        ТекущийТест.Вставить("Наименование", ЭлементСписка.Ключ);
        ТекущийТест.Вставить("ИмяМетода", ЭлементСписка.Значение);
        ВыполнитьТест(ТекущийТест);
    КонецЦикла;

КонецПроцедуры

ВыполнитьТесты("VanessaExt");
