import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Alarm'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @timeAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get timeAm;

  /// No description provided for @timePm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get timePm;

  /// No description provided for @dayShortSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get dayShortSun;

  /// No description provided for @dayShortMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayShortMon;

  /// No description provided for @dayShortTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayShortTue;

  /// No description provided for @dayShortWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayShortWed;

  /// No description provided for @dayShortThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayShortThu;

  /// No description provided for @dayShortFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayShortFri;

  /// No description provided for @dayShortSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get dayShortSat;

  /// No description provided for @dayLetterSun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dayLetterSun;

  /// No description provided for @dayLetterMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get dayLetterMon;

  /// No description provided for @dayLetterTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dayLetterTue;

  /// No description provided for @dayLetterWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dayLetterWed;

  /// No description provided for @dayLetterThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dayLetterThu;

  /// No description provided for @dayLetterFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get dayLetterFri;

  /// No description provided for @dayLetterSat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dayLetterSat;

  /// No description provided for @missionDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get missionDifficultyEasy;

  /// No description provided for @missionDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get missionDifficultyMedium;

  /// No description provided for @missionDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get missionDifficultyHard;

  /// No description provided for @alarmListTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmListTitle;

  /// No description provided for @alarmNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New alarm'**
  String get alarmNewTitle;

  /// No description provided for @alarmEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit alarm'**
  String get alarmEditTitle;

  /// No description provided for @alarmListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your alarms.'**
  String get alarmListLoadError;

  /// No description provided for @alarmActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Try again.'**
  String get alarmActionFailed;

  /// No description provided for @alarmListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet. Tap \"{buttonLabel}\" to add one.'**
  String alarmListEmpty(String buttonLabel);

  /// No description provided for @alarmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete alarm?'**
  String get alarmDeleteTitle;

  /// No description provided for @alarmDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" will be permanently removed.'**
  String alarmDeleteConfirm(String label);

  /// No description provided for @alarmDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarmDefaultLabel;

  /// No description provided for @alarmLabelField.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get alarmLabelField;

  /// No description provided for @alarmRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get alarmRepeatLabel;

  /// No description provided for @alarmSoundHapticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound & haptics'**
  String get alarmSoundHapticsLabel;

  /// No description provided for @alarmSoundField.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get alarmSoundField;

  /// No description provided for @alarmVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get alarmVibration;

  /// No description provided for @alarmSnoozeLabel.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get alarmSnoozeLabel;

  /// No description provided for @alarmAllowSnooze.
  ///
  /// In en, this message translates to:
  /// **'Allow snooze'**
  String get alarmAllowSnooze;

  /// No description provided for @alarmSnoozeInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get alarmSnoozeInterval;

  /// No description provided for @alarmSnoozeIntervalSuffix.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get alarmSnoozeIntervalSuffix;

  /// No description provided for @alarmMaxSnoozes.
  ///
  /// In en, this message translates to:
  /// **'Max snoozes'**
  String get alarmMaxSnoozes;

  /// No description provided for @alarmMaxSnoozesSuffix.
  ///
  /// In en, this message translates to:
  /// **'x'**
  String get alarmMaxSnoozesSuffix;

  /// No description provided for @alarmActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get alarmActive;

  /// No description provided for @alarmSoundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get alarmSoundDefault;

  /// No description provided for @alarmSoundGentleChimes.
  ///
  /// In en, this message translates to:
  /// **'Gentle chimes'**
  String get alarmSoundGentleChimes;

  /// No description provided for @alarmSoundMorningBirds.
  ///
  /// In en, this message translates to:
  /// **'Morning birds'**
  String get alarmSoundMorningBirds;

  /// No description provided for @alarmSoundClassicBell.
  ///
  /// In en, this message translates to:
  /// **'Classic bell'**
  String get alarmSoundClassicBell;

  /// No description provided for @alarmSoundRooster.
  ///
  /// In en, this message translates to:
  /// **'Rooster'**
  String get alarmSoundRooster;

  /// No description provided for @alarmUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade required'**
  String get alarmUpgradeTitle;

  /// No description provided for @alarmUpgradeBody.
  ///
  /// In en, this message translates to:
  /// **'{message}\n\nFree accounts are limited to a few alarms. Upgrade to Premium for unlimited alarms and AI missions.'**
  String alarmUpgradeBody(String message);

  /// No description provided for @alarmUpgradeNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get alarmUpgradeNotNow;

  /// No description provided for @alarmUpgradeSeePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get alarmUpgradeSeePlans;

  /// No description provided for @alarmRepeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get alarmRepeatOnce;

  /// No description provided for @alarmRepeatEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get alarmRepeatEveryDay;

  /// No description provided for @alarmBadgeMath.
  ///
  /// In en, this message translates to:
  /// **'Math · {difficulty}'**
  String alarmBadgeMath(String difficulty);

  /// No description provided for @alarmBadgeShake.
  ///
  /// In en, this message translates to:
  /// **'Shake · {difficulty}'**
  String alarmBadgeShake(String difficulty);

  /// No description provided for @alarmBadgePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo · {difficulty}'**
  String alarmBadgePhoto(String difficulty);

  /// No description provided for @alarmBadgePhotoTarget.
  ///
  /// In en, this message translates to:
  /// **'Photo: {target}'**
  String alarmBadgePhotoTarget(String target);

  /// No description provided for @alarmBadgeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get alarmBadgeUnknown;

  /// No description provided for @alarmMissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get alarmMissionsTitle;

  /// No description provided for @alarmMissionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get alarmMissionAdd;

  /// No description provided for @alarmMissionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No missions. The alarm can be dismissed with one tap.'**
  String get alarmMissionsEmpty;

  /// No description provided for @alarmMissionAddSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add mission'**
  String get alarmMissionAddSheetTitle;

  /// No description provided for @alarmMissionMathTitle.
  ///
  /// In en, this message translates to:
  /// **'Math problem'**
  String get alarmMissionMathTitle;

  /// No description provided for @alarmMissionShakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Shake'**
  String get alarmMissionShakeTitle;

  /// No description provided for @alarmMissionPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photograph an object'**
  String get alarmMissionPhotoTitle;

  /// No description provided for @alarmMissionMathDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve equations to dismiss'**
  String get alarmMissionMathDesc;

  /// No description provided for @alarmMissionShakeDesc.
  ///
  /// In en, this message translates to:
  /// **'Shake the phone to dismiss'**
  String get alarmMissionShakeDesc;

  /// No description provided for @alarmMissionPhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of a real-world object'**
  String get alarmMissionPhotoDesc;

  /// No description provided for @alarmMissionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove mission'**
  String get alarmMissionRemove;

  /// No description provided for @alarmMissionTargetObject.
  ///
  /// In en, this message translates to:
  /// **'Target object'**
  String get alarmMissionTargetObject;

  /// No description provided for @dashGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashGoodMorning;

  /// No description provided for @dashAllAlarms.
  ///
  /// In en, this message translates to:
  /// **'All alarms'**
  String get dashAllAlarms;

  /// No description provided for @dashTryChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Try the wake-up challenge'**
  String get dashTryChallengeTitle;

  /// No description provided for @dashTryChallengeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shake 10s → math → camera. Experience it now.'**
  String get dashTryChallengeSubtitle;

  /// No description provided for @dashNextAlarm.
  ///
  /// In en, this message translates to:
  /// **'Next alarm'**
  String get dashNextAlarm;

  /// No description provided for @dashNoActiveAlarms.
  ///
  /// In en, this message translates to:
  /// **'No active alarms'**
  String get dashNoActiveAlarms;

  /// No description provided for @dashAlarmMissionCount.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count, plural, =1{1 mission} other{{count} missions}}'**
  String dashAlarmMissionCount(String label, int count);

  /// No description provided for @dashAiMissionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Today\'s AI mission is unavailable.'**
  String get dashAiMissionUnavailable;

  /// No description provided for @dashAiMissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s AI mission'**
  String get dashAiMissionTitle;

  /// No description provided for @dashAiMissionUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock daily AI missions with Premium.'**
  String get dashAiMissionUnlock;

  /// No description provided for @dashGoPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get dashGoPremium;

  /// No description provided for @dashAiMissionNone.
  ///
  /// In en, this message translates to:
  /// **'No mission for today yet. Check back later.'**
  String get dashAiMissionNone;

  /// No description provided for @dashThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dashThisWeek;

  /// No description provided for @dashStatsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stats unavailable'**
  String get dashStatsUnavailable;

  /// No description provided for @dashStatAvgSleep.
  ///
  /// In en, this message translates to:
  /// **'Avg sleep'**
  String get dashStatAvgSleep;

  /// No description provided for @dashStatConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get dashStatConsistency;

  /// No description provided for @dashStatMissions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get dashStatMissions;

  /// No description provided for @dashDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String dashDurationHm(int h, int m);

  /// No description provided for @dashNavAlarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get dashNavAlarmsTitle;

  /// No description provided for @dashNavAlarmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage your alarms'**
  String get dashNavAlarmsSubtitle;

  /// No description provided for @authWelcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBackTitle;

  /// No description provided for @authWelcomeBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your mornings on track.'**
  String get authWelcomeBackSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInButton;

  /// No description provided for @authNoAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccountPrompt;

  /// No description provided for @authCreateOneButton.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get authCreateOneButton;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get authLoginFailed;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start waking up smarter.'**
  String get authRegisterSubtitle;

  /// No description provided for @authDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authDisplayNameLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountButton;

  /// No description provided for @authHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccountPrompt;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get authRegistrationFailed;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericError;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {n} characters'**
  String authPasswordMinLength(int n);

  /// No description provided for @authPasswordComplexity.
  ///
  /// In en, this message translates to:
  /// **'Use at least one letter and one number'**
  String get authPasswordComplexity;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authDisplayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get authDisplayNameRequired;

  /// No description provided for @authDisplayNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Display name is too short'**
  String get authDisplayNameTooShort;

  /// No description provided for @authDisplayNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Display name is too long'**
  String get authDisplayNameTooLong;

  /// No description provided for @ringWakeUpExclaim.
  ///
  /// In en, this message translates to:
  /// **'Wake up!'**
  String get ringWakeUpExclaim;

  /// No description provided for @missionStepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Mission {step} of {total}  ·  {kind}'**
  String missionStepOfTotal(int step, int total, String kind);

  /// No description provided for @missionKindShake.
  ///
  /// In en, this message translates to:
  /// **'Shake'**
  String get missionKindShake;

  /// No description provided for @missionKindMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get missionKindMath;

  /// No description provided for @missionKindCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get missionKindCamera;

  /// No description provided for @missionAlarmDismissed.
  ///
  /// In en, this message translates to:
  /// **'Alarm dismissed'**
  String get missionAlarmDismissed;

  /// No description provided for @missionHaveAGreatDay.
  ///
  /// In en, this message translates to:
  /// **'Have a great day! ☀️'**
  String get missionHaveAGreatDay;

  /// No description provided for @missionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get missionRetry;

  /// No description provided for @missionSolveToDismiss.
  ///
  /// In en, this message translates to:
  /// **'Solve to dismiss'**
  String get missionSolveToDismiss;

  /// No description provided for @missionAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get missionAnswerHint;

  /// No description provided for @missionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get missionSubmit;

  /// No description provided for @missionEnterANumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number.'**
  String get missionEnterANumber;

  /// No description provided for @missionWrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Wrong answer. Here is a new problem.'**
  String get missionWrongAnswer;

  /// No description provided for @missionFailedToLoadProblem.
  ///
  /// In en, this message translates to:
  /// **'Failed to load problem.'**
  String get missionFailedToLoadProblem;

  /// No description provided for @missionShakeStart.
  ///
  /// In en, this message translates to:
  /// **'SHAKE!'**
  String get missionShakeStart;

  /// No description provided for @missionShakeNice.
  ///
  /// In en, this message translates to:
  /// **'NICE!'**
  String get missionShakeNice;

  /// No description provided for @missionTapAsFast.
  ///
  /// In en, this message translates to:
  /// **'Tap as fast as you can to shake'**
  String get missionTapAsFast;

  /// No description provided for @missionKeepShaking.
  ///
  /// In en, this message translates to:
  /// **'Keep shaking your phone'**
  String get missionKeepShaking;

  /// No description provided for @missionShakeDone.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get missionShakeDone;

  /// No description provided for @missionShakeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} s'**
  String missionShakeRemaining(int remaining);

  /// No description provided for @missionShakeCount.
  ///
  /// In en, this message translates to:
  /// **'shakes: {count}'**
  String missionShakeCount(int count);

  /// No description provided for @missionKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going!'**
  String get missionKeepGoing;

  /// No description provided for @missionShakeToRun.
  ///
  /// In en, this message translates to:
  /// **'Shake to run the timer…'**
  String get missionShakeToRun;

  /// No description provided for @missionPointCameraAt.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at'**
  String get missionPointCameraAt;

  /// No description provided for @missionTakePhotoOfYour.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your'**
  String get missionTakePhotoOfYour;

  /// No description provided for @missionAnyObject.
  ///
  /// In en, this message translates to:
  /// **'ANY OBJECT'**
  String get missionAnyObject;

  /// No description provided for @objToothbrush.
  ///
  /// In en, this message translates to:
  /// **'Toothbrush'**
  String get objToothbrush;

  /// No description provided for @objSink.
  ///
  /// In en, this message translates to:
  /// **'Sink'**
  String get objSink;

  /// No description provided for @objCoffeeMug.
  ///
  /// In en, this message translates to:
  /// **'Coffee Mug'**
  String get objCoffeeMug;

  /// No description provided for @objKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get objKeys;

  /// No description provided for @objShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get objShoes;

  /// No description provided for @objLaptop.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get objLaptop;

  /// No description provided for @missionCameraOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera. Check permissions.'**
  String get missionCameraOpenError;

  /// No description provided for @missionDoesNotLookLike.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a {target}. Try again.'**
  String missionDoesNotLookLike(String target);

  /// No description provided for @missionOpeningCamera.
  ///
  /// In en, this message translates to:
  /// **'Opening camera…'**
  String get missionOpeningCamera;

  /// No description provided for @missionAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get missionAnalyzing;

  /// No description provided for @missionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get missionTryAgain;

  /// No description provided for @missionVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get missionVerified;

  /// No description provided for @missionOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Open camera'**
  String get missionOpenCamera;

  /// No description provided for @missionAnalyzingYourPhoto.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your photo…'**
  String get missionAnalyzingYourPhoto;

  /// No description provided for @missionUploadingAndChecking.
  ///
  /// In en, this message translates to:
  /// **'Uploading and checking…'**
  String get missionUploadingAndChecking;

  /// No description provided for @missionObjectDetected.
  ///
  /// In en, this message translates to:
  /// **'Object detected! ✓'**
  String get missionObjectDetected;

  /// No description provided for @missionConfirmedSure.
  ///
  /// In en, this message translates to:
  /// **'Confirmed! ({percent}% sure)'**
  String missionConfirmedSure(int percent);

  /// No description provided for @missionNotDetectedConfidence.
  ///
  /// In en, this message translates to:
  /// **'Not detected ({percent}% confidence)'**
  String missionNotDetectedConfidence(int percent);

  /// No description provided for @missionSaw.
  ///
  /// In en, this message translates to:
  /// **'Saw: {objects}'**
  String missionSaw(String objects);

  /// No description provided for @missionAnyObjectHint.
  ///
  /// In en, this message translates to:
  /// **'Get out of bed and snap anything you see.'**
  String get missionAnyObjectHint;

  /// No description provided for @missionSpecificObjectHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the object and capture.'**
  String get missionSpecificObjectHint;

  /// No description provided for @ringWakeUp.
  ///
  /// In en, this message translates to:
  /// **'Wake up!'**
  String get ringWakeUp;

  /// No description provided for @ringAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get ringAlarm;

  /// No description provided for @ringSnoozeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Snooze limit reached'**
  String get ringSnoozeLimitReached;

  /// No description provided for @ringCouldNotLoadAlarm.
  ///
  /// In en, this message translates to:
  /// **'Could not load alarm. You can still snooze or stop.'**
  String get ringCouldNotLoadAlarm;

  /// No description provided for @ringCompleteMissionToStop.
  ///
  /// In en, this message translates to:
  /// **'Complete your mission to stop the alarm'**
  String get ringCompleteMissionToStop;

  /// No description provided for @ringStartMission.
  ///
  /// In en, this message translates to:
  /// **'Start mission'**
  String get ringStartMission;

  /// No description provided for @ringSnoozeWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Snooze ({minutes}m · {remaining} left)'**
  String ringSnoozeWithDetails(int minutes, int remaining);

  /// No description provided for @ringWakeUpLoud.
  ///
  /// In en, this message translates to:
  /// **'WAKE UP!'**
  String get ringWakeUpLoud;

  /// No description provided for @ringCompleteEveryMission.
  ///
  /// In en, this message translates to:
  /// **'Complete every mission to stop the alarm'**
  String get ringCompleteEveryMission;

  /// No description provided for @ringImAwakeStartMissions.
  ///
  /// In en, this message translates to:
  /// **'I\'m awake — start missions'**
  String get ringImAwakeStartMissions;

  /// No description provided for @ringExitDemo.
  ///
  /// In en, this message translates to:
  /// **'Exit demo'**
  String get ringExitDemo;

  /// No description provided for @ringChipShake.
  ///
  /// In en, this message translates to:
  /// **'Shake'**
  String get ringChipShake;

  /// No description provided for @ringChipMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get ringChipMath;

  /// No description provided for @ringChipCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get ringChipCamera;

  /// No description provided for @ringChipUnknown.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get ringChipUnknown;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get settingsDisplayName;

  /// No description provided for @settingsDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsDisplayNameHint;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @settingsTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get settingsTimezone;

  /// No description provided for @settingsTimezoneNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsTimezoneNotSet;

  /// No description provided for @settingsSelectTimezone.
  ///
  /// In en, this message translates to:
  /// **'Select timezone'**
  String get settingsSelectTimezone;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAlarmNotifications.
  ///
  /// In en, this message translates to:
  /// **'Alarm notifications'**
  String get settingsAlarmNotifications;

  /// No description provided for @settingsAlarmNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show notifications when alarms fire'**
  String get settingsAlarmNotificationsSubtitle;

  /// No description provided for @settingsDailyMissionReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily mission reminders'**
  String get settingsDailyMissionReminders;

  /// No description provided for @settingsDailyMissionRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me when my AI mission is ready'**
  String get settingsDailyMissionRemindersSubtitle;

  /// No description provided for @settingsProductAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Product announcements'**
  String get settingsProductAnnouncements;

  /// No description provided for @settingsProductAnnouncementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Occasional news and tips'**
  String get settingsProductAnnouncementsSubtitle;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get settingsPremium;

  /// No description provided for @settingsFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get settingsFreePlan;

  /// No description provided for @settingsPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have access to all premium features'**
  String get settingsPremiumSubtitle;

  /// No description provided for @settingsFreePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for AI missions and sleep insights'**
  String get settingsFreePlanSubtitle;

  /// No description provided for @settingsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get settingsManage;

  /// No description provided for @settingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsUpgrade;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogOut;

  /// No description provided for @settingsLogOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogOutConfirmTitle;

  /// No description provided for @settingsLogOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use the app.'**
  String get settingsLogOutConfirmBody;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsUpsellMessage.
  ///
  /// In en, this message translates to:
  /// **'Unlock detailed sleep and mission analytics with Premium.'**
  String get statsUpsellMessage;

  /// No description provided for @statsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics.'**
  String get statsLoadError;

  /// No description provided for @statsSleepDuration.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration'**
  String get statsSleepDuration;

  /// No description provided for @statsSleepDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hours per night'**
  String get statsSleepDurationSubtitle;

  /// No description provided for @statsMissionSuccessRate.
  ///
  /// In en, this message translates to:
  /// **'Mission success rate'**
  String get statsMissionSuccessRate;

  /// No description provided for @statsMissionSuccessRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Percent of missions cleared'**
  String get statsMissionSuccessRateSubtitle;

  /// No description provided for @statsConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get statsConsistency;

  /// No description provided for @statsConsistencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How regular your schedule is'**
  String get statsConsistencySubtitle;

  /// No description provided for @statsAvgSleep.
  ///
  /// In en, this message translates to:
  /// **'Avg sleep'**
  String get statsAvgSleep;

  /// No description provided for @statsMissions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get statsMissions;

  /// No description provided for @statsPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String statsPercentValue(int percent);

  /// No description provided for @statsHoursAxis.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String statsHoursAxis(int hours);

  /// No description provided for @statsConsistencyBlurbExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent — your schedule is very regular.'**
  String get statsConsistencyBlurbExcellent;

  /// No description provided for @statsConsistencyBlurbDecent.
  ///
  /// In en, this message translates to:
  /// **'Decent — try to keep wake times steady.'**
  String get statsConsistencyBlurbDecent;

  /// No description provided for @statsConsistencyBlurbIrregular.
  ///
  /// In en, this message translates to:
  /// **'Irregular — aim for consistent sleep and wake times.'**
  String get statsConsistencyBlurbIrregular;

  /// No description provided for @statsNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get statsNoDataTitle;

  /// No description provided for @statsNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Use a few alarms and your sleep insights will appear here.'**
  String get statsNoDataBody;

  /// No description provided for @statsUpsellTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your sleep insights'**
  String get statsUpsellTitle;

  /// No description provided for @statsGoPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get statsGoPremium;

  /// No description provided for @statsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get statsRetry;

  /// No description provided for @paywallGoPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get paywallGoPremium;

  /// No description provided for @paywallLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load plans. Please try again.'**
  String get paywallLoadError;

  /// No description provided for @paywallChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get paywallChoosePlan;

  /// No description provided for @paywallHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Wake up smarter with Premium'**
  String get paywallHeaderTitle;

  /// No description provided for @paywallHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock AI missions, advanced statistics, and unlimited alarms.'**
  String get paywallHeaderSubtitle;

  /// No description provided for @paywallFeatureAiMissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI wake-up missions'**
  String get paywallFeatureAiMissionsTitle;

  /// No description provided for @paywallFeatureAiMissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A fresh, AI-generated mission every day to truly wake you up.'**
  String get paywallFeatureAiMissionsSubtitle;

  /// No description provided for @paywallFeatureStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced sleep statistics'**
  String get paywallFeatureStatsTitle;

  /// No description provided for @paywallFeatureStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trends, consistency score, and mission success over time.'**
  String get paywallFeatureStatsSubtitle;

  /// No description provided for @paywallFeatureUnlimitedAlarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited alarms'**
  String get paywallFeatureUnlimitedAlarmsTitle;

  /// No description provided for @paywallFeatureUnlimitedAlarmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create as many alarms as you need — no free-tier cap.'**
  String get paywallFeatureUnlimitedAlarmsSubtitle;

  /// No description provided for @paywallFeatureAllMissionTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'All mission types'**
  String get paywallFeatureAllMissionTypesTitle;

  /// No description provided for @paywallFeatureAllMissionTypesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock every mission, including object-detection challenges.'**
  String get paywallFeatureAllMissionTypesSubtitle;

  /// No description provided for @paywallBestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get paywallBestValue;

  /// No description provided for @paywallFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial'**
  String paywallFreeTrial(int days);

  /// No description provided for @paywallContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// No description provided for @paywallContinueWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Continue • {price}'**
  String paywallContinueWithPrice(String price);

  /// No description provided for @paywallPlansUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Plans unavailable'**
  String get paywallPlansUnavailable;

  /// No description provided for @paywallRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get paywallRestoring;

  /// No description provided for @paywallRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestorePurchases;

  /// No description provided for @paywallLegalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions auto-renew. Cancel anytime.'**
  String get paywallLegalDisclaimer;

  /// No description provided for @paywallTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get paywallTerms;

  /// No description provided for @paywallPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get paywallPrivacy;

  /// No description provided for @paywallAlreadyPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'You are Premium'**
  String get paywallAlreadyPremiumTitle;

  /// No description provided for @paywallAlreadyPremiumBody.
  ///
  /// In en, this message translates to:
  /// **'All premium features are unlocked. Thank you for your support!'**
  String get paywallAlreadyPremiumBody;

  /// No description provided for @paywallDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get paywallDone;

  /// No description provided for @paywallRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get paywallRetry;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
