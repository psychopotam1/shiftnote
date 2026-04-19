// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ReelHours';

  @override
  String get settings => 'Настройки';

  @override
  String get currency => 'Валюта';

  @override
  String get calendar => 'Календарь';

  @override
  String get overtime => 'Переработка';

  @override
  String get time => 'Время';

  @override
  String get defaultRates => 'Стандартные ставки';

  @override
  String get workingCurrency => 'Рабочая валюта';

  @override
  String get showAmounts => 'Показывать суммы в календаре';

  @override
  String get ignoreFirst15 => 'Игнорировать первые 15 мин первого часа OT';

  @override
  String get use24h => '24-часовой формат';

  @override
  String get defaultStart => 'Начало по умолчанию';

  @override
  String get defaultEnd => 'Конец по умолчанию';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get done => 'Готово';

  @override
  String get dayOff => 'Выходной';

  @override
  String get shift => 'Смена';

  @override
  String get paymentSummary => 'Сводка оплаты';

  @override
  String get unpaid => 'Не оплачено';

  @override
  String get sent => 'Отправлено';

  @override
  String get paid => 'Оплачено';

  @override
  String get today => 'СЕГОДНЯ';

  @override
  String get addShift => 'Добавить смену';

  @override
  String get editShift => 'Редактировать смену';

  @override
  String get projectName => 'Название проекта';

  @override
  String get productionName => 'Название продакшна';

  @override
  String get shiftDuration => 'Длительность смены';

  @override
  String get dateAndTime => 'Дата и время';

  @override
  String get projectInfo => 'Информация о проекте';

  @override
  String get shiftDetails => 'Детали смены';

  @override
  String get selectTime => 'Выберите время';
}
