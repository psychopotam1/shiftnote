import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uk'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ShiftNote'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @defaultRates.
  ///
  /// In en, this message translates to:
  /// **'Default rates'**
  String get defaultRates;

  /// No description provided for @workingCurrency.
  ///
  /// In en, this message translates to:
  /// **'Working currency'**
  String get workingCurrency;

  /// No description provided for @showAmounts.
  ///
  /// In en, this message translates to:
  /// **'Show amounts on calendar'**
  String get showAmounts;

  /// No description provided for @ignoreFirst15.
  ///
  /// In en, this message translates to:
  /// **'Ignore first 15 min of first OT hour'**
  String get ignoreFirst15;

  /// No description provided for @use24h.
  ///
  /// In en, this message translates to:
  /// **'Use 24-hour format'**
  String get use24h;

  /// No description provided for @defaultStart.
  ///
  /// In en, this message translates to:
  /// **'Default start'**
  String get defaultStart;

  /// No description provided for @defaultEnd.
  ///
  /// In en, this message translates to:
  /// **'Default end'**
  String get defaultEnd;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get dayOff;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment summary'**
  String get paymentSummary;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today;

  /// No description provided for @addShift.
  ///
  /// In en, this message translates to:
  /// **'Add shift'**
  String get addShift;

  /// No description provided for @editShift.
  ///
  /// In en, this message translates to:
  /// **'Edit shift'**
  String get editShift;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @productionName.
  ///
  /// In en, this message translates to:
  /// **'Production name'**
  String get productionName;

  /// No description provided for @shiftDuration.
  ///
  /// In en, this message translates to:
  /// **'Shift duration'**
  String get shiftDuration;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get dateAndTime;

  /// No description provided for @projectInfo.
  ///
  /// In en, this message translates to:
  /// **'Project info'**
  String get projectInfo;

  /// No description provided for @shiftDetails.
  ///
  /// In en, this message translates to:
  /// **'Shift details'**
  String get shiftDetails;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUkrainian.
  ///
  /// In en, this message translates to:
  /// **'Українська'**
  String get languageUkrainian;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Currency, time and defaults'**
  String get settingsSubtitle;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @defaultBaseRate.
  ///
  /// In en, this message translates to:
  /// **'Default base rate'**
  String get defaultBaseRate;

  /// No description provided for @defaultOvertimeRate.
  ///
  /// In en, this message translates to:
  /// **'Default overtime rate'**
  String get defaultOvertimeRate;

  /// No description provided for @defaultOvertimeHours.
  ///
  /// In en, this message translates to:
  /// **'Default overtime hours'**
  String get defaultOvertimeHours;

  /// No description provided for @addToDeviceCalendarByDefault.
  ///
  /// In en, this message translates to:
  /// **'Add to device calendar by default'**
  String get addToDeviceCalendarByDefault;

  /// No description provided for @examplePrefix.
  ///
  /// In en, this message translates to:
  /// **'e.g.'**
  String get examplePrefix;

  /// No description provided for @selection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get selection;

  /// No description provided for @daysSelected.
  ///
  /// In en, this message translates to:
  /// **'days selected'**
  String get daysSelected;

  /// No description provided for @nextTen.
  ///
  /// In en, this message translates to:
  /// **'Next 10'**
  String get nextTen;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// No description provided for @markUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark unpaid'**
  String get markUnpaid;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get current;

  /// No description provided for @overtimeDaysThisMonth.
  ///
  /// In en, this message translates to:
  /// **'overtime days this month'**
  String get overtimeDaysThisMonth;

  /// No description provided for @selectOneSavedShiftFirst.
  ///
  /// In en, this message translates to:
  /// **'Select one saved shift first'**
  String get selectOneSavedShiftFirst;

  /// No description provided for @selectedShiftHasNoProjectName.
  ///
  /// In en, this message translates to:
  /// **'Selected shift has no project name'**
  String get selectedShiftHasNoProjectName;

  /// No description provided for @noUnpaidSentShiftsLeft.
  ///
  /// In en, this message translates to:
  /// **'No unpaid/sent shifts left for this project'**
  String get noUnpaidSentShiftsLeft;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// No description provided for @todayUppercase.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get todayUppercase;

  /// No description provided for @deviceTime.
  ///
  /// In en, this message translates to:
  /// **'Device time'**
  String get deviceTime;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowLabel;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @tapToAddShift.
  ///
  /// In en, this message translates to:
  /// **'Tap to add shift'**
  String get tapToAddShift;

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get tapToEdit;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @emptyDay.
  ///
  /// In en, this message translates to:
  /// **'Empty day'**
  String get emptyDay;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @projectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Feature Film / Music Video'**
  String get projectHint;

  /// No description provided for @productionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Moonlight Productions'**
  String get productionHint;

  /// No description provided for @baseRateAmount.
  ///
  /// In en, this message translates to:
  /// **'Base rate / amount'**
  String get baseRateAmount;

  /// No description provided for @transportExpense.
  ///
  /// In en, this message translates to:
  /// **'Transport expense'**
  String get transportExpense;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Studio, set, address...'**
  String get locationHint;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Call time, production notes, crew info...'**
  String get notesHint;

  /// No description provided for @overtimeRate.
  ///
  /// In en, this message translates to:
  /// **'Overtime rate'**
  String get overtimeRate;

  /// No description provided for @ignoreFirst15Min.
  ///
  /// In en, this message translates to:
  /// **'Ignore first 15 min of first OT hour'**
  String get ignoreFirst15Min;

  /// No description provided for @plannedEnd.
  ///
  /// In en, this message translates to:
  /// **'Planned end'**
  String get plannedEnd;

  /// No description provided for @calculatedOt.
  ///
  /// In en, this message translates to:
  /// **'Calculated OT'**
  String get calculatedOt;

  /// No description provided for @overtimeTotal.
  ///
  /// In en, this message translates to:
  /// **'Overtime total'**
  String get overtimeTotal;

  /// No description provided for @addToDeviceCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to device calendar'**
  String get addToDeviceCalendar;

  /// No description provided for @base.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get base;

  /// No description provided for @estimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get estimatedTotal;

  /// No description provided for @saveShift.
  ///
  /// In en, this message translates to:
  /// **'Save shift'**
  String get saveShift;

  /// No description provided for @selectStartTime.
  ///
  /// In en, this message translates to:
  /// **'Select start time'**
  String get selectStartTime;

  /// No description provided for @selectEndTime.
  ///
  /// In en, this message translates to:
  /// **'Select end time'**
  String get selectEndTime;

  /// No description provided for @addShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Add shift'**
  String get addShiftTitle;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @paymentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment summary'**
  String get paymentSummaryTitle;

  /// No description provided for @mixedProjects.
  ///
  /// In en, this message translates to:
  /// **'Mixed projects'**
  String get mixedProjects;

  /// No description provided for @mixedProductions.
  ///
  /// In en, this message translates to:
  /// **'Mixed productions'**
  String get mixedProductions;

  /// No description provided for @paymentStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get paymentStatusUnpaid;

  /// No description provided for @paymentStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get paymentStatusSent;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentStatusPaid;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get daysLabel;

  /// No description provided for @totalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get totalsLabel;

  /// No description provided for @baseTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Base total'**
  String get baseTotalLabel;

  /// No description provided for @overtimeTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Overtime total'**
  String get overtimeTotalLabel;

  /// No description provided for @transportTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Transport total'**
  String get transportTotalLabel;

  /// No description provided for @grandTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get grandTotalLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsLabel;

  /// No description provided for @otTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'OT total'**
  String get otTotalLabel;

  /// No description provided for @markSentButton.
  ///
  /// In en, this message translates to:
  /// **'Mark sent'**
  String get markSentButton;

  /// No description provided for @noSavedShiftsSelectedDays.
  ///
  /// In en, this message translates to:
  /// **'No saved shifts in selected days.'**
  String get noSavedShiftsSelectedDays;

  /// No description provided for @mixedProjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Mixed projects'**
  String get mixedProjectsLabel;

  /// No description provided for @mixedProductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Mixed productions'**
  String get mixedProductionsLabel;

  /// No description provided for @selectedDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'selected days'**
  String get selectedDaysLabel;

  /// No description provided for @markedAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Marked as'**
  String get markedAsLabel;

  /// No description provided for @overtimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtimeTitle;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// No description provided for @baseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get baseLabel;

  /// No description provided for @overtimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtimeLabel;

  /// No description provided for @transportLabel.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transportLabel;

  /// No description provided for @projectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectLabel;

  /// No description provided for @productionLabel.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get productionLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @hoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @overtimeShortLabel.
  ///
  /// In en, this message translates to:
  /// **'OT total'**
  String get overtimeShortLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @markPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaidLabel;

  /// No description provided for @markUnpaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark unpaid'**
  String get markUnpaidLabel;

  /// No description provided for @markSentLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark sent'**
  String get markSentLabel;

  /// No description provided for @noSavedShiftsLabel.
  ///
  /// In en, this message translates to:
  /// **'No saved shifts in selected days.'**
  String get noSavedShiftsLabel;

  /// No description provided for @batchTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch template'**
  String get batchTemplateTitle;

  /// No description provided for @selectedDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected days'**
  String selectedDaysCount(int count);

  /// No description provided for @projectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Project template'**
  String get projectTemplate;

  /// No description provided for @rates.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get rates;

  /// No description provided for @optionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional details'**
  String get optionalDetails;

  /// No description provided for @batchShiftDuration.
  ///
  /// In en, this message translates to:
  /// **'Shift duration'**
  String get batchShiftDuration;

  /// No description provided for @batchProjectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get batchProjectName;

  /// No description provided for @batchProductionName.
  ///
  /// In en, this message translates to:
  /// **'Production name'**
  String get batchProductionName;

  /// No description provided for @batchBaseRate.
  ///
  /// In en, this message translates to:
  /// **'Base rate'**
  String get batchBaseRate;

  /// No description provided for @batchOvertimeRate.
  ///
  /// In en, this message translates to:
  /// **'Overtime rate'**
  String get batchOvertimeRate;

  /// No description provided for @batchLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get batchLocation;

  /// No description provided for @batchNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get batchNotes;

  /// No description provided for @batchChooseShiftDurationFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose shift duration first'**
  String get batchChooseShiftDurationFirst;

  /// No description provided for @applyToSelectedDays.
  ///
  /// In en, this message translates to:
  /// **'Apply to selected days'**
  String get applyToSelectedDays;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
