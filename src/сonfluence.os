///////////////////////////////////////////////////////////////////
//
// Модуль интеграции с Confluence (https://ru.atlassian.com/software/confluence)
//
// (с) BIA Technologies, LLC	
//
///////////////////////////////////////////////////////////////////

#Использовать json

///////////////////////////////////////////////////////////////////

Перем ФорматыСодержимого Экспорт;

// ОписаниеПодключения
//	Создает структуру с набором параметров подключения.
//	Созданная структура в дальнейшем используется для всех операций
// 
// Параметры:
//  АдресСервера  	- Строка - Адрес (URL) сервера confluence. Например "https://conflunece.mydomain.ru"
//  Пользователь	- Строка - Имя пользователя для подключения
//  Пароль			- Строка - Пароль пользователя для подключения
//
// Возвращаемое значение:
//   Структура	- описание подключения
//	{
//		Пользователь,
//		Пароль,
//		АдресСервера
//	} 
//
Функция ОписаниеПодключения(АдресСервера = "", Пользователь = "", Пароль = "") Экспорт
	
	ПараметрыПодключения = Новый Структура;
	ПараметрыПодключения.Вставить("Пользователь", Пользователь);
	ПараметрыПодключения.Вставить("Пароль", Пароль);
	ПараметрыПодключения.Вставить("АдресСервера", АдресСервера);
	
	Возврат ПараметрыПодключения;
	
КонецФункции // ОписаниеПодключения()

///////////////////////////////////////////////////////////////////
// СТРАНИЦЫ
///////////////////////////////////////////////////////////////////

// НайтиСтраницуПоИмени
//	Ищет страницу в указанном пространстве по имени
// 
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Имя искомой страницы в указанном пространстве
//
// Возвращаемое значение:
//   Строка   - Идентификатор найденной страницы. Если страница не найдена, то будет возвращена пустая строка
//
Функция НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы) Экспорт
	
	Идентификатор = "";
	
	URL = ПолучитьURLОперации(КодПространства, ИмяСтраницы);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если УспешныйЗапрос(РезультатЗапроса) Тогда
		
		ПарсерJSON = Новый ПарсерJSON;
		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("results");
		Если Результат <> Неопределено И Результат.Количество() Тогда
			
			Результат0 = Результат[0];
			Идентификатор = Результат0.Получить("id");
			
		КонецЕсли; 
		
	Иначе
		
		ВызватьИсключение "Ошибка поиска страницы: " + КодПространства + "." + ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL, "GET");

	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // НайтиСтраницуПоИмени() 

// ВерсияСтраницыПоИдентификатору
//	По идентификатору страницы получает ее версию
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор  			- Строка - Идентификатор страницы
//
// Возвращаемое значение:
//   Строка   - Версия страницы, если версии нет (как??), то вернется пустая строка
//
Функция ВерсияСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор) Экспорт
	
	Версия = "";
	URL = ПолучитьURLОперации(,, Идентификатор);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если УспешныйЗапрос(РезультатЗапроса) Тогда
		
		ПарсерJSON = Новый ПарсерJSON;

		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("version");
		Если Результат <> Неопределено Тогда
			
			Версия = Результат.Получить("number");               			
			
		КонецЕсли; 
		
	Иначе
		
		ВызватьИсключение "Ошибка получения версии страницы:" + Идентификатор + ТекстОшибки(РезультатЗапроса, URL, "GET");
		
	КонецЕсли;
	
	Возврат Версия;
	
КонецФункции // ВерсияСтраницыПоИдентификатору()

// СодержимоеСтраницыПоИдентификатору
//	По идентификатору страницы получает ее содержимое
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор  			- Строка - Идентификатор страницы
//
// Возвращаемое значение:
//   Строка   - Тело страницы
//
Функция СодержимоеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор) Экспорт

	Тело = "";
	URL = ПолучитьURLОперации(,, Идентификатор) + "&expand=body.storage";
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если УспешныйЗапрос(РезультатЗапроса) Тогда
		
		Данные = ДесериализоватьJSON(РезультатЗапроса.Ответ);

		Возврат Данные.body.storage.value;
		
	Иначе
		
		ВызватьИсключение "Ошибка получения версии страницы:" + Идентификатор + ТекстОшибки(РезультатЗапроса, URL, "GET");
		
	КонецЕсли;
	
	Возврат Тело;

КонецФункции // СодержимоеСтраницыПоИдентификатору()

// ПодчиненныеСтраницыПоИдентификатору
//	Возвращает таблицу с подчиненными страницами
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор  			- Строка - Идентификатор страницы
//
// Возвращаемое значение:
//   ТаблицаЗначений   - Таблица с подчиненными страницами
//	{
//		Наименование 	- Строка - Наименование страницы
//		Идентификатор 	- Строка - Идентификатор страницы
//	}
//
Функция ПодчиненныеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор) Экспорт
	
	ДочерниеСтраницы = Новый ТаблицаЗначений;
	ДочерниеСтраницы.Колонки.Добавить("Наименование");
	ДочерниеСтраницы.Колонки.Добавить("Идентификатор");
	
	URL = ПолучитьURLОперации(,, Идентификатор, "child/page");
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если УспешныйЗапрос(РезультатЗапроса) Тогда
		
		ПарсерJSON = Новый ПарсерJSON;
		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("results");
		Если Результат <> Неопределено Тогда			
			
			Для Каждого Запись Из Результат Цикл
				
				Дочка = ДочерниеСтраницы.Добавить();
				Дочка.Наименование = Запись.Получить("title");
				Дочка.Идентификатор = Запись.Получить("id");
				
			КонецЦикла
			
		КонецЕсли;
		
	Иначе
		
		ВызватьИсключение "Ошибка получения подчиненных страниц: " + Идентификатор + ТекстОшибки(РезультатЗапроса, URL, "GET");
		
	КонецЕсли;
	
	Возврат ДочерниеСтраницы;
	
КонецФункции // ПодчиненныеСтраницыПоИдентификатору()

// СоздатьСтраницу
//	Создает новую страницу в указанном пространстве
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Наименование страницы (заголовок)
//  Содержимое  			- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//  ИдентификаторРодителя	- Строка - идентификатор родительской страницы
//
// Возвращаемое значение:
//   Строка   - Идентификатор созданной страницы
//
Функция СоздатьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя = "") Экспорт
	
	ИдентификаторСтраницы = "";
	
	URL = ПолучитьURLОперации();
	ТелоЗапроса = "
	|{
	|""type"": ""page"",
	|""title"": """ + ИмяСтраницы + """,
	|""space"": {""key"":""" + КодПространства + """},";
	
	Если Не ПустаяСтрока(ИдентификаторРодителя) Тогда
		
		ТелоЗапроса = ТелоЗапроса + "
		|""ancestors"":[{""id"":" + ИдентификаторРодителя + "}],";
		
	КонецЕсли;
	
	ТелоЗапроса = ТелоЗапроса + "
	|""body"": {""storage"":
	|	{
	|		""value"":""" + Содержимое + """
	|	,""representation"":""storage""
	|	}}
	|}";
	
	ИдентификаторСтраницы = "";
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "POST", URL, ТелоЗапроса);
	
	Если УспешныйЗапрос(РезультатЗапроса) Тогда
		
		ИдентификаторСтраницы = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
	Иначе
		
		ВызватьИсключение "Ошибка создания страницы:" + КодПространства + "." + ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL, "POST");
		
	КонецЕсли;
	
	Возврат ИдентификаторСтраницы;
	
КонецФункции // СоздатьСтраницу() 

// ОбновитьСтраницу
//	Выполняет обновление существующей страницы
//
// Параметры:
//  ПараметрыПодключения  			- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  				- Строка - Код пространства confluence
//  ИмяСтраницы  					- Строка - Наименование страницы (заголовок)
//  Идентификатор					- Строка - идентификатор страницы. Если идентификатор указан, 
//										то при обновлении страницы наименование будет установлено из параметра ИмяСтраницы
//  Содержимое  					- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//	ОбновитьПриИзмененииСодержимого - Булево - обновлять страницу, только если содержимое изменилось, иначе всегда обновлять
//
// Возвращаемое значение:
//   Строка   - Идентификатор обновленной страницы
//
Функция ОбновитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы = "", Знач Идентификатор = "", Содержимое = "", ОбновитьПриИзмененииСодержимого = ЛОЖЬ) Экспорт
	
	Если ПустаяСтрока(ИмяСтраницы) И ПустаяСтрока(Идентификатор) Тогда
		
		ВызватьИсключение "Ошибка обновления страницы: " + КодПространства + "." + ИмяСтраницы +
		"Ответ: не указаны имя страницы и идентификатор";
		
	КонецЕсли;
	
	Если ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
		Если ПустаяСтрока(Идентификатор) Тогда
			
			ВызватьИсключение "Ошибка обновления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: не найдена страница";
			
		КонецЕсли;
		
	КонецЕсли;
	
	Если ОбновитьПриИзмененииСодержимого Тогда

		ТекущееСодержимое = СодержимоеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор);
		Регексп = Новый РегулярноеВыражение("id=\\""([a-z0-9-]{36})\\""\ ac\:name"); // идентификаторы плагинов меняются
		Регексп.Многострочный = ИСТИНА;
		ТекущееСодержимое = Регексп.Заменить(ТекущееСодержимое, "NONE");
		ВрСодержимое = Регексп.Заменить(Содержимое, "NONE");
		Если СтрСравнить(СокрЛП(ТекущееСодержимое), СокрЛП(ВрСодержимое)) = 0 Тогда

			Возврат Идентификатор;

		КонецЕсли;
		
	КонецЕсли;

	URL = ПолучитьURLОперации(,, Идентификатор);
	Версия = ВерсияСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор);	
	Версия = Формат(Число(Версия) + 1, "ЧГ=");
	
	ТелоЗапроса = "
	|{
	|""type"": ""page"",
	|""title"": """ + ИмяСтраницы + """,";
	
	Если НЕ ПустаяСтрока(Содержимое) Тогда
		
		ТелоЗапроса = ТелоЗапроса + "
		|""body"": {""storage"":
		|	{
		|		""value"":""" + Содержимое + """
		|	,""representation"":""storage""
		|	}},";
		
	КонецЕсли;
	
	ТелоЗапроса = ТелоЗапроса + "
	|""version"":{""number"":" + Версия + "}
	|}";
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "PUT", URL, ТелоЗапроса);
	
	Если НЕ УспешныйЗапрос(РезультатЗапроса) Тогда
		
		ВызватьИсключение "Ошибка обновления страницы:" + КодПространства + "." + ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL, "PUT");
		
	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // ОбновитьСтраницу()

// СоздатьСтраницуИлиОбновить
//	Создает страницу, если же страница существует, то обновляет
//
// Параметры:
//  ПараметрыПодключения  			- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  				- Строка - Код пространства confluence
//  ИмяСтраницы  					- Строка - Наименование страницы (заголовок)
//  Содержимое  					- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//  ИдентификаторРодителя			- Строка - идентификатор родительской страницы
//	ОбновитьПриИзмененииСодержимого - Булево - обновлять страницу, только если содержимое изменилось, иначе всегда обновлять
//
// Возвращаемое значение:
//   Строка   - Идентификатор созданной / обновленной страницы
//
Функция СоздатьСтраницуИлиОбновить(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя = "", ОбновитьПриИзмененииСодержимого = ЛОЖЬ)Экспорт
	
	Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
	
	Если Не ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = ОбновитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Идентификатор, Содержимое, ОбновитьПриИзмененииСодержимого);

	Иначе

		Идентификатор = СоздатьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя);

	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // СоздатьСтраницуИлиОбновить()

// УдалитьСтраницу
//	Удаляет существующую страницу 
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Наименование страницы (заголовок)
//  Идентификатор			- Строка - Идентификатор страницы
//	УдалятьПодчиненные		- Булево - признак необходимости удаления подчиненных страниц.
//								Если данный параметр = ЛОЖЬ и есть подчиненные страницы, то удаление не будет выполнено
//								и будет вызвано исключение
//
Процедура УдалитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы = "", Знач Идентификатор = "", УдалятьПодчиненные = ЛОЖЬ) Экспорт
	
	Если ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
		Если ПустаяСтрока(Идентификатор) Тогда
			
			ВызватьИсключение "Ошибка удаления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: не найдена страница";
			
		КонецЕсли;
		
	КонецЕсли;

	ПодчиненныеСтраницы = ПодчиненныеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор);

	Если ПодчиненныеСтраницы.Количество() И НЕ УдалятьПодчиненные Тогда
		
		ВызватьИсключение "Ошибка удаления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: есть подчиненные страницы";

	КонецЕсли; 

	Для Каждого Страница Из ПодчиненныеСтраницы Цикл

		УдалитьСтраницу(ПараметрыПодключения, КодПространства, Страница.Наименование, Страница.Идентификатор, УдалятьПодчиненные); 

	КонецЦикла;
	
	URL = ПолучитьURLОперации(,, Идентификатор);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "DELETE", URL);
	Если НЕ (УспешныйЗапрос(РезультатЗапроса) ИЛИ РезультатЗапроса.КодСостояния = 204) Тогда
			
		ВызватьИсключение "Ошибка удаления страницы:" + КодПространства + "." + ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL, "DELETE");
		
	КонецЕсли;
	
КонецПроцедуры // УдалитьСтраницу()

// ПрикрепитьМеткуКСтранице
//	Заменяет метки страницы указанной
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор			- Строка - Идентификатор страницы
//	Метка					- Строка - Метка, которую необходимо прикрепить								
//
// Возвращаемое значение:
//   Булево   - Успех операции
//
Функция ПрикрепитьМеткуКСтранице(ПараметрыПодключения, Идентификатор, Метка) Экспорт
		
	URL = ПолучитьURLОперации(,, Идентификатор, "label");
	ТелоЗапроса = "[{""prefix"":""global"", ""name"":""" + Метка + """}]";
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "POST", URL, ТелоЗапроса);
	
	Если УспешныйЗапрос(РезультатЗапроса) Тогда
		
		Результат = Истина;
		
	Иначе
		
		ВызватьИсключение "Ошибка прикрепления метки:" + ТекстОшибки(РезультатЗапроса, URL, "POST");

	КонецЕсли;

	Возврат Результат;

КонецФункции

#Область НовоеAPI

// АдресСтраницы
//	Описание расположения страницы
//
// Параметры:
//   КодПространства - Строка - Код пространства confluence
//   ИмяСтраницы - Строка - имя страницы, должно быть уникально в пределах пространства
//   Идентификатор - Строка - Идентификатор страницы confluence, может быть получен только поиском
//   ИдентификаторРодителя - Строка - Идентификатор родителя страницы confluence, может быть получен только поиском
//
//  Возвращаемое значение:
//   Структура - Описание расположения страницы
//
Функция АдресСтраницы(КодПространства, ИмяСтраницы = "", Идентификатор = "", ИдентификаторРодителя = "") Экспорт
	
	Адрес = Новый Структура;
	
	Адрес.Вставить("КодПространства", 		КодПространства);
	Адрес.Вставить("ИмяСтраницы", 			ИмяСтраницы);
	Адрес.Вставить("Идентификатор", 		Идентификатор);
	Адрес.Вставить("ИдентификаторРодителя", ИдентификаторРодителя);
	
	Возврат Адрес;
	
КонецФункции

// Создать
//	Создает новую страницу в confluence и возвращает идентификатор новой страницы, также установив его в "АдресСтраницы"
//
// Параметры:
//   ПараметрыПодключения - Структура - Описание подключения, см. confluence.ОписаниеПодключения
//   АдресСтраницы - Структура - Описание расположения страницы, см. confluence.АдресСтраницы
//   Содержимое - Строка, Структура - Содержимое новой страницы.
//										либо строка содержимого в формате confluence
//										либо структура с ключами Значение и Формат (Confluence, Markdown, HTML)
//
//  Возвращаемое значение:
//   Строка - Идентификатор созданной страницы
//
Функция Создать(ПараметрыПодключения, АдресСтраницы, Содержимое = Неопределено) Экспорт
	
	HTTPМетод = "POST";

	ОписаниеСодержимого = ПодготовитьСодержимое(ПараметрыПодключения, Содержимое);
	ПараметрыКоманды = ПараметрыСозданияОбновления(АдресСтраницы, ОписаниеСодержимого);
	
	URL = ПолучитьURLОперации();
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, HTTPМетод, URL, СериализоватьJSON(ПараметрыКоманды));
	
	Если УспешныйЗапрос(РезультатЗапроса) Тогда
		
		АдресСтраницы.Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, АдресСтраницы.КодПространства, АдресСтраницы.ИмяСтраницы);
		
	Иначе
		
		ВызватьИсключение СтрШаблон("Ошибка создания страницы: %1.%2%3",
			АдресСтраницы.КодПространства, 
			АдресСтраницы.ИмяСтраницы, 
			ТекстОшибки(РезультатЗапроса, URL, HTTPМетод));
		
	КонецЕсли;
	
	Возврат АдресСтраницы.Идентификатор;

КонецФункции

// Обновить
//	Выполняет обновление существующей страницы
//
// Параметры:
//   ПараметрыПодключения - Структура - Описание подключения, см. confluence.ОписаниеПодключения
//   АдресСтраницы - Структура - Описание расположения страницы, см. confluence.АдресСтраницы
//   Содержимое - Строка, Структура - Содержимое новой страницы.
//										либо строка содержимого в формате confluence
//										либо структура с ключами Значение и Формат (Confluence, Markdown, HTML)
//
//   ОбновитьПриИзмененииСодержимого - Булево - Выполнять только если содержимое изменено, 
//		Если установлено в Истина, но меняется только родитель или имя страницы - изменения не будут применены
//
//  Возвращаемое значение:
//   Неопределено, Строка - Когда обновление не требуется будет возвращено Неопределено, 
//								в других случаях - идентификатор страницы
//
Функция Обновить(ПараметрыПодключения, АдресСтраницы, Содержимое = Неопределено, ОбновитьПриИзмененииСодержимого = Ложь) Экспорт
	
	Если ПустаяСтрока(АдресСтраницы.ИмяСтраницы) И ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
		
		ВызватьИсключение "Ошибка обновления страницы: " + АдресСтраницы.КодПространства + "." + АдресСтраницы.ИмяСтраницы +
		"Ответ: не указаны имя страницы и идентификатор";
		
	КонецЕсли;
	
	Если ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
		
		АдресСтраницы.Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, АдресСтраницы.КодПространства, АдресСтраницы.ИмяСтраницы);
		
		Если ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
			
			ВызватьИсключение "Ошибка обновления страницы: " + АдресСтраницы.КодПространства + "." + АдресСтраницы.ИмяСтраницы +
			"Ответ: не найдена страница";
			
		КонецЕсли;
		
	КонецЕсли;
	
	ОписаниеСодержимого = ПодготовитьСодержимое(ПараметрыПодключения, Содержимое);

	Если ОбновитьПриИзмененииСодержимого Тогда

		СодержимоеConfluence = СодержимоеСтраницыПоИдентификатору(ПараметрыПодключения, АдресСтраницы.Идентификатор);
		Регексп = Новый РегулярноеВыражение("ac\:macro-id=""[a-z0-9-]{36}"""); // идентификаторы плагинов меняются
		Регексп.Многострочный = Истина;
		СодержимоеConfluence = Регексп.Заменить(СодержимоеConfluence, "NONE");
		ВрСодержимое = Регексп.Заменить(ОписаниеСодержимого.Значение, "NONE");
		
		Если ОписаниеСодержимого.Формат = ФорматыСодержимого.MarkDown Тогда
			
			// TODO: Известные проблемы при сравнении MarkDown
			//			1. Если в исходном файле есть "/", то для публикации его необходимо экранировать
			//				но до сравнения, тк от confluence он приходит в норм виде
			//			2. Картинки (img) при конвертации тэк не закрытый, в confluence - закрытый
			СодержимоеConfluence = СтрЗаменить(СодержимоеConfluence, "</li>", ""); // Особенность конвертера Markdown → Confluence
			
		КонецЕсли;


		Если СтрСравнить(СокрЛП(СодержимоеConfluence), СокрЛП(ВрСодержимое)) = 0 Тогда

			Возврат Неопределено;

		КонецЕсли;
		
	КонецЕсли;

	URL = ПолучитьURLОперации(, , АдресСтраницы.Идентификатор);
	Версия = ВерсияСтраницыПоИдентификатору(ПараметрыПодключения, АдресСтраницы.Идентификатор);	
	Версия = Формат(Число(Версия) + 1, "ЧГ=");
	
	HTTPМетод = "PUT";

	ПараметрыКоманды = ПараметрыСозданияОбновления(АдресСтраницы, ОписаниеСодержимого, Версия);
	
	ТелоЗапроса = СериализоватьJSON(ПараметрыКоманды);
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, HTTPМетод, URL, ТелоЗапроса);
	
	Если НЕ УспешныйЗапрос(РезультатЗапроса) Тогда
		
		ВызватьИсключение "Ошибка обновления страницы:" + АдресСтраницы.КодПространства + "." + АдресСтраницы.ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL, HTTPМетод);
		
	КонецЕсли;
	
	Возврат АдресСтраницы.Идентификатор;
	
КонецФункции

// СоздатьИлиОбновить
//	Создает новую страницу, либо обновление существующую
//
// Параметры:
//   ПараметрыПодключения - Структура - Описание подключения, см. confluence.ОписаниеПодключения
//   АдресСтраницы - Структура - Описание расположения страницы, см. confluence.АдресСтраницы
//   Содержимое - Строка, Структура - Содержимое новой страницы.
//										либо строка содержимого в формате confluence
//										либо структура с ключами Значение и Формат (Confluence, Markdown, HTML)
//   ОбновитьПриИзмененииСодержимого - Булево - Выполнять только если содержимое изменено, 
//		Если установлено в Истина, но меняется только родитель или имя страницы - изменения не будут применены
//
//  Возвращаемое значение:
//   Структура - Ключи:
//					Успешно - Булево - не было ошибок
//					Действие - Строка - "Создание", "Обновление", Неопределено
//
Функция СоздатьИлиОбновить(ПараметрыПодключения, АдресСтраницы, Содержимое, ОбновитьПриИзмененииСодержимого) Экспорт
	
	Результат = Новый Структура("Успешно, Действие");
	Если ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
		
		АдресСтраницы.Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, АдресСтраницы.КодПространства, АдресСтраницы.ИмяСтраницы);
		
	КонецЕсли;

	Если Не ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
		
		РезультатОбновления = Обновить(
			ПараметрыПодключения, 
			АдресСтраницы,
			Содержимое, 
			ОбновитьПриИзмененииСодержимого);

		Если РезультатОбновления <> Неопределено Тогда
			Результат.Действие = "Обновление";
		КонецЕсли;

	Иначе

		АдресСтраницы.Идентификатор = Создать(ПараметрыПодключения, АдресСтраницы, Содержимое);
		Результат.Действие = "Создание";
		
	КонецЕсли;

	Результат.Успешно = Истина;

	Возврат Результат;

КонецФункции

#КонецОбласти

///////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЙ ФУНКЦИОНАЛ
///////////////////////////////////////////////////////////////////

#Область СлужебныеМетоды

Функция ПараметрыСозданияОбновления(Адрес, ОписаниеСодержимого, Версия = Неопределено)

	ПараметрыКоманды = Новый Структура();
	ПараметрыКоманды.Вставить("type", "page");
	ПараметрыКоманды.Вставить("title", Адрес.ИмяСтраницы);
	ПараметрыКоманды.Вставить("space", Новый Структура("key", Адрес.КодПространства));
	
	Если Версия <> Неопределено Тогда
		
		ПараметрыКоманды.Вставить("version", Новый Структура("number", Версия));

	КонецЕсли;
	
	Если Не ПустаяСтрока(Адрес.ИдентификаторРодителя) Тогда
		Родители = Новый Массив();
		Родители.Добавить(Новый Структура("id", Адрес.ИдентификаторРодителя));
		ПараметрыКоманды.Вставить("ancestors", Родители);
	КонецЕсли;
	
	ФорматПоУмолчанию = confluence.ФорматыСодержимого.Confluence;
	Значение = "";
	Формат = ФорматПоУмолчанию;
	
	Если ТипЗнч(ОписаниеСодержимого) <> Тип("Структура") 
		ИЛИ НЕ ОписаниеСодержимого.Свойство("Формат")
		ИЛИ НЕ ОписаниеСодержимого.Свойство("Значение") Тогда

		ВызватьИсключение "Передано не корректное описание содержимого";

	КонецЕсли;

	Если ЗначениеЗаполнено(ОписаниеСодержимого.Значение) Тогда

		Если ОписаниеСодержимого.Формат = ФорматыСодержимого.MarkDown Тогда
			
			Значение = СтрЗаменить(ОписаниеСодержимого.Значение, "\", "\\");
		
			Хранение = Новый Структура("value, representation", Значение, "editor");
			ТелоСтраницы = Новый Структура("editor", Хранение);
		
		Иначе
			
			Хранение = Новый Структура("value, representation", ОписаниеСодержимого.Значение, "storage");
			ТелоСтраницы = Новый Структура("storage", Хранение);

		КонецЕсли;
		
		ПараметрыКоманды.Вставить("body", ТелоСтраницы);

	КонецЕсли;

	Возврат ПараметрыКоманды;

КонецФункции

Функция ПодготовитьСодержимое(ПараметрыПодключения, Содержимое)
	
	ОписаниеСодержимого = Новый Структура("Значение, Формат");
	
	ФорматПоУмолчанию = "confluence";
	Значение = "";
	Формат = ФорматПоУмолчанию;

	Если ТипЗнч(Содержимое) = Тип("Структура") Тогда
		
		Если Содержимое.Свойство("Значение") Тогда
			
			Значение = Содержимое.Значение;

		ИначеЕсли Содержимое.Свойство("ИмяФайла") Тогда
			
			Значение = ТекстФайла(Содержимое.ИмяФайла);

		КонецЕсли;

		Если Содержимое.Свойство("Формат") Тогда
			
			Формат = Содержимое.Формат;

		КонецЕсли;
		
	ИначеЕсли ЗначениеЗаполнено(Содержимое) Тогда
		
		Значение = Содержимое;

	КонецЕсли;
	
	Если ПустаяСтрока(Формат) Тогда
		
		Формат = ФорматПоУмолчанию;

	КонецЕсли;

	Если ЗначениеЗаполнено(Значение) И Формат = ФорматыСодержимого.MarkDown Тогда
		
		Значение = ПреобразоватьMarkdownToConfluence(ПараметрыПодключения, Значение);
		
	КонецЕсли;
	
	ОписаниеСодержимого.Формат = Формат;
	ОписаниеСодержимого.Значение = Значение;

	Возврат ОписаниеСодержимого;

КонецФункции

Функция ПреобразоватьMarkdownToConfluence(ПараметрыПодключения, СодержимоеMarkdown)

	Идентификатор = "";
	
	URLОперации = "rest/tinymce/1/markdownxhtmlconverter";
	
	ПараметрыОперации = Новый Структура();
	ПараметрыОперации.Вставить("wiki", СодержимоеMarkdown);

	Тело = СериализоватьJSON(ПараметрыОперации);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "POST", URLОперации, Тело, "text/html; charset=UTF-8");
	
	Если УспешныйЗапрос(РезультатЗапроса) Тогда
		
		Возврат РезультатЗапроса.Ответ;
		
	Иначе
		
		ВызватьИсключение "Ошибка преобразования markdown → html" + ТекстОшибки(РезультатЗапроса, URLОперации, "POST");
		
	КонецЕсли;
	
	Возврат Идентификатор;

КонецФункции

Функция ПолучитьURLОперации(КодПространства = "", ИмяСтраницы = "", Идентификатор = "", Операция = "")
	
	URLОперации = "rest/api/content/";
	КлючАвторизации = "?os_authType=basic";
	Если ПустаяСтрока(Идентификатор) Тогда
		
		URLОперации = URLОперации + КлючАвторизации;
		Если Не ПустаяСтрока(КодПространства) Тогда
			
			URLОперации = URLОперации + "&spaceKey=" + КодПространства;
			
		КонецЕсли;
		
		Если Не ПустаяСтрока(ИмяСтраницы) Тогда
			
			URLОперации = URLОперации + "&title=" + КодироватьСтроку(ИмяСтраницы, СпособКодированияСтроки.КодировкаURL);
			
		КонецЕсли;
		
	Иначе
		
		URLОперации = URLОперации + Идентификатор + ?(ПустаяСтрока(Операция), "", "/" + Операция) + "/" + КлючАвторизации;
		
	КонецЕсли;
	
	Возврат URLОперации;
	
КонецФункции // ПолучитьURLОперации() 

Функция ВыполнитьHTTPЗапрос(ПараметрыПодключения, Метод, URL, ТелоЗапроса = "", Accept = "application/json; charset=UTF-8")
	
	HTTPЗапрос = Новый HTTPЗапрос;
	HTTPЗапрос.Заголовки.Вставить("Content-Type", "application/json; charset=UTF-8");
	HTTPЗапрос.Заголовки.Вставить("Accept", Accept);
	
	HTTPЗапрос.АдресРесурса = URL;

	Если Не ПустаяСтрока(ТелоЗапроса) Тогда
		
		HTTPЗапрос.УстановитьТелоИзСтроки(ТелоЗапроса, КодировкаТекста.UTF8);
		
	КонецЕсли;
	
	HTTP = Новый HTTPСоединение(ПараметрыПодключения.АдресСервера, , 
								ПараметрыПодключения.Пользователь,
								ПараметрыПодключения.Пароль);
								
	Если СтрСравнить(Метод, "GET") = 0 Тогда
		
		Ответ = HTTP.Получить(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "POST") = 0 Тогда
		
		Ответ = HTTP.ОтправитьДляОбработки(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "PUT") = 0 Тогда
		
		Ответ = HTTP.Записать(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "DELETE") = 0 Тогда
		
		Ответ = HTTP.Удалить(HTTPЗапрос);
		
	Иначе
		
		ВызватьИсключение СтрШаблон("Неизвестный метод: '%1'", Метод);
		
	КонецЕсли;
	
	Возврат Новый Структура("Ответ, КодСостояния", Ответ.ПолучитьТелоКакСтроку(КодировкаТекста.UTF8), Ответ.КодСостояния);
	
КонецФункции // ВыполнитьHTTPЗапрос()

Функция УспешныйЗапрос(РезультатЗапроса)
	
	КодОтветаУспешно = 200;
	Возврат РезультатЗапроса.КодСостояния = КодОтветаУспешно;

КонецФункции

Функция СериализоватьJSON(Значение)
	
	ПараметрыЗаписи = Новый ПараметрыЗаписиJSON(Ложь, , Истина, , , , , , Истина);
	Запись = Новый ЗаписьJSON(ПараметрыЗаписи);
	Запись.УстановитьСтроку();
	
	ЗаписатьJSON(Запись, Значение);
	
	Возврат Запись.Закрыть();

КонецФункции

Функция ДесериализоватьJSON(СтрокаJSON)
	Чтение = Новый ЧтениеJSON();
	Чтение.УстановитьСтроку(СтрокаJSON);
	Данные = ПрочитатьJSON(Чтение);
	Чтение.Закрыть();
	
	Возврат Данные;
	
КонецФункции

Функция ТекстОшибки(РезультатЗапроса, URL, HTTМетод)

	Возврат СтрШаблон(
	"
	|Запрос: [%4] %1
	|КодСостояния: %2
	|Ответ: %3", URL, РезультатЗапроса.КодСостояния, РезультатЗапроса.Ответ, HTTМетод);
	
КонецФункции

Функция ТекстФайла(ИмяФайла)
	
	Чтение = Новый ЧтениеТекста(ИмяФайла, КодировкаТекста.UTF8);
	Содержимое = Чтение.Прочитать();
	Чтение.Закрыть();

	Возврат Содержимое;
	
КонецФункции

#КонецОбласти

ФорматыСодержимого = Новый Структура();
ФорматыСодержимого.Вставить("Markdown", "markdown");
ФорматыСодержимого.Вставить("Confluence", "confluence");
ФорматыСодержимого.Вставить("HTML", "html");