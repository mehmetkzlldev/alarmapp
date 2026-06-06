// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Alarm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDone => 'Done';

  @override
  String get commonClose => 'Close';

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get dayShortSun => 'Sun';

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayLetterSun => 'S';

  @override
  String get dayLetterMon => 'M';

  @override
  String get dayLetterTue => 'T';

  @override
  String get dayLetterWed => 'W';

  @override
  String get dayLetterThu => 'T';

  @override
  String get dayLetterFri => 'F';

  @override
  String get dayLetterSat => 'S';

  @override
  String get missionDifficultyEasy => 'Easy';

  @override
  String get missionDifficultyMedium => 'Medium';

  @override
  String get missionDifficultyHard => 'Hard';

  @override
  String get alarmListTitle => 'Alarms';

  @override
  String get alarmNewTitle => 'New alarm';

  @override
  String get alarmEditTitle => 'Edit alarm';

  @override
  String get alarmListLoadError => 'Something went wrong loading your alarms.';

  @override
  String get alarmActionFailed => 'Action failed. Try again.';

  @override
  String alarmListEmpty(String buttonLabel) {
    return 'No alarms yet. Tap \"$buttonLabel\" to add one.';
  }

  @override
  String get alarmDeleteTitle => 'Delete alarm?';

  @override
  String alarmDeleteConfirm(String label) {
    return '\"$label\" will be permanently removed.';
  }

  @override
  String get alarmDefaultLabel => 'Alarm';

  @override
  String get alarmLabelField => 'Label';

  @override
  String get alarmRepeatLabel => 'Repeat';

  @override
  String get alarmSoundHapticsLabel => 'Sound & haptics';

  @override
  String get alarmSoundField => 'Sound';

  @override
  String get alarmVibration => 'Vibration';

  @override
  String get alarmSnoozeLabel => 'Snooze';

  @override
  String get alarmAllowSnooze => 'Allow snooze';

  @override
  String get alarmSnoozeInterval => 'Interval';

  @override
  String get alarmSnoozeIntervalSuffix => 'min';

  @override
  String get alarmMaxSnoozes => 'Max snoozes';

  @override
  String get alarmMaxSnoozesSuffix => 'x';

  @override
  String get alarmActive => 'Active';

  @override
  String get alarmSoundDefault => 'Default';

  @override
  String get alarmSoundGentleChimes => 'Gentle chimes';

  @override
  String get alarmSoundMorningBirds => 'Morning birds';

  @override
  String get alarmSoundClassicBell => 'Classic bell';

  @override
  String get alarmSoundRooster => 'Rooster';

  @override
  String get alarmUpgradeTitle => 'Upgrade required';

  @override
  String alarmUpgradeBody(String message) {
    return '$message\n\nFree accounts are limited to a few alarms. Upgrade to Premium for unlimited alarms and AI missions.';
  }

  @override
  String get alarmUpgradeNotNow => 'Not now';

  @override
  String get alarmUpgradeSeePlans => 'See plans';

  @override
  String get alarmRepeatOnce => 'Once';

  @override
  String get alarmRepeatEveryDay => 'Every day';

  @override
  String alarmBadgeMath(String difficulty) {
    return 'Math · $difficulty';
  }

  @override
  String alarmBadgeShake(String difficulty) {
    return 'Shake · $difficulty';
  }

  @override
  String alarmBadgePhoto(String difficulty) {
    return 'Photo · $difficulty';
  }

  @override
  String alarmBadgePhotoTarget(String target) {
    return 'Photo: $target';
  }

  @override
  String get alarmBadgeUnknown => 'Unknown';

  @override
  String get alarmMissionsTitle => 'Missions';

  @override
  String get alarmMissionAdd => 'Add';

  @override
  String get alarmMissionsEmpty =>
      'No missions. The alarm can be dismissed with one tap.';

  @override
  String get alarmMissionAddSheetTitle => 'Add mission';

  @override
  String get alarmMissionMathTitle => 'Math problem';

  @override
  String get alarmMissionShakeTitle => 'Shake';

  @override
  String get alarmMissionPhotoTitle => 'Photograph an object';

  @override
  String get alarmMissionMathDesc => 'Solve equations to dismiss';

  @override
  String get alarmMissionShakeDesc => 'Shake the phone to dismiss';

  @override
  String get alarmMissionPhotoDesc => 'Take a photo of a real-world object';

  @override
  String get alarmMissionRemove => 'Remove mission';

  @override
  String get alarmMissionTargetObject => 'Target object';

  @override
  String get dashGoodMorning => 'Good morning';

  @override
  String get dashAllAlarms => 'All alarms';

  @override
  String get dashTryChallengeTitle => 'Try the wake-up challenge';

  @override
  String get dashTryChallengeSubtitle =>
      'Shake 10s → math → camera. Experience it now.';

  @override
  String get dashNextAlarm => 'Next alarm';

  @override
  String get dashNoActiveAlarms => 'No active alarms';

  @override
  String dashAlarmMissionCount(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missions',
      one: '1 mission',
    );
    return '$label · $_temp0';
  }

  @override
  String get dashAiMissionUnavailable => 'Today\'s AI mission is unavailable.';

  @override
  String get dashAiMissionTitle => 'Today\'s AI mission';

  @override
  String get dashAiMissionUnlock => 'Unlock daily AI missions with Premium.';

  @override
  String get dashGoPremium => 'Go Premium';

  @override
  String get dashAiMissionNone => 'No mission for today yet. Check back later.';

  @override
  String get dashThisWeek => 'This week';

  @override
  String get dashStatsUnavailable => 'Stats unavailable';

  @override
  String get dashStatAvgSleep => 'Avg sleep';

  @override
  String get dashStatConsistency => 'Consistency';

  @override
  String get dashStatMissions => 'Missions';

  @override
  String dashDurationHm(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String get dashNavAlarmsTitle => 'Alarms';

  @override
  String get dashNavAlarmsSubtitle => 'View and manage your alarms';

  @override
  String get authWelcomeBackTitle => 'Welcome back';

  @override
  String get authWelcomeBackSubtitle =>
      'Sign in to keep your mornings on track.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authSignInButton => 'Sign in';

  @override
  String get authNoAccountPrompt => 'Don\'t have an account?';

  @override
  String get authCreateOneButton => 'Create one';

  @override
  String get authLoginFailed => 'Login failed. Please try again.';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle => 'Start waking up smarter.';

  @override
  String get authDisplayNameLabel => 'Display name';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authCreateAccountButton => 'Create account';

  @override
  String get authHaveAccountPrompt => 'Already have an account?';

  @override
  String get authRegistrationFailed => 'Registration failed. Please try again.';

  @override
  String get authGenericError => 'Something went wrong. Please try again.';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String authPasswordMinLength(int n) {
    return 'Password must be at least $n characters';
  }

  @override
  String get authPasswordComplexity => 'Use at least one letter and one number';

  @override
  String get authConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authDisplayNameRequired => 'Display name is required';

  @override
  String get authDisplayNameTooShort => 'Display name is too short';

  @override
  String get authDisplayNameTooLong => 'Display name is too long';

  @override
  String get ringWakeUpExclaim => 'Wake up!';

  @override
  String missionStepOfTotal(int step, int total, String kind) {
    return 'Mission $step of $total  ·  $kind';
  }

  @override
  String get missionKindShake => 'Shake';

  @override
  String get missionKindMath => 'Math';

  @override
  String get missionKindCamera => 'Camera';

  @override
  String get missionAlarmDismissed => 'Alarm dismissed';

  @override
  String get missionHaveAGreatDay => 'Have a great day! ☀️';

  @override
  String get missionRetry => 'Retry';

  @override
  String get missionSolveToDismiss => 'Solve to dismiss';

  @override
  String get missionAnswerHint => 'Answer';

  @override
  String get missionSubmit => 'Submit';

  @override
  String get missionEnterANumber => 'Enter a number.';

  @override
  String get missionWrongAnswer => 'Wrong answer. Here is a new problem.';

  @override
  String get missionFailedToLoadProblem => 'Failed to load problem.';

  @override
  String get missionShakeStart => 'SHAKE!';

  @override
  String get missionShakeNice => 'NICE!';

  @override
  String get missionTapAsFast => 'Tap as fast as you can to shake';

  @override
  String get missionKeepShaking => 'Keep shaking your phone';

  @override
  String get missionShakeDone => 'Done!';

  @override
  String missionShakeRemaining(int remaining) {
    return '$remaining s';
  }

  @override
  String missionShakeCount(int count) {
    return 'shakes: $count';
  }

  @override
  String get missionKeepGoing => 'Keep going!';

  @override
  String get missionShakeToRun => 'Shake to run the timer…';

  @override
  String get missionPointCameraAt => 'Point the camera at';

  @override
  String get missionTakePhotoOfYour => 'Take a photo of your';

  @override
  String get missionAnyObject => 'ANY OBJECT';

  @override
  String get objToothbrush => 'Toothbrush';

  @override
  String get objSink => 'Sink';

  @override
  String get objCoffeeMug => 'Coffee Mug';

  @override
  String get objKeys => 'Keys';

  @override
  String get objShoes => 'Shoes';

  @override
  String get objLaptop => 'Laptop';

  @override
  String get missionCameraOpenError =>
      'Could not open the camera. Check permissions.';

  @override
  String missionDoesNotLookLike(String target) {
    return 'That does not look like a $target. Try again.';
  }

  @override
  String get missionOpeningCamera => 'Opening camera…';

  @override
  String get missionAnalyzing => 'Analyzing…';

  @override
  String get missionTryAgain => 'Try again';

  @override
  String get missionVerified => 'Verified';

  @override
  String get missionOpenCamera => 'Open camera';

  @override
  String get missionAnalyzingYourPhoto => 'Analyzing your photo…';

  @override
  String get missionUploadingAndChecking => 'Uploading and checking…';

  @override
  String get missionObjectDetected => 'Object detected! ✓';

  @override
  String missionConfirmedSure(int percent) {
    return 'Confirmed! ($percent% sure)';
  }

  @override
  String missionNotDetectedConfidence(int percent) {
    return 'Not detected ($percent% confidence)';
  }

  @override
  String missionSaw(String objects) {
    return 'Saw: $objects';
  }

  @override
  String get missionAnyObjectHint =>
      'Get out of bed and snap anything you see.';

  @override
  String get missionSpecificObjectHint =>
      'Point your camera at the object and capture.';

  @override
  String get ringWakeUp => 'Wake up!';

  @override
  String get ringAlarm => 'Alarm';

  @override
  String get ringSnoozeLimitReached => 'Snooze limit reached';

  @override
  String get ringCouldNotLoadAlarm =>
      'Could not load alarm. You can still snooze or stop.';

  @override
  String get ringCompleteMissionToStop =>
      'Complete your mission to stop the alarm';

  @override
  String get ringStartMission => 'Start mission';

  @override
  String ringSnoozeWithDetails(int minutes, int remaining) {
    return 'Snooze (${minutes}m · $remaining left)';
  }

  @override
  String get ringWakeUpLoud => 'WAKE UP!';

  @override
  String get ringCompleteEveryMission =>
      'Complete every mission to stop the alarm';

  @override
  String get ringImAwakeStartMissions => 'I\'m awake — start missions';

  @override
  String get ringExitDemo => 'Exit demo';

  @override
  String get ringChipShake => 'Shake';

  @override
  String get ringChipMath => 'Math';

  @override
  String get ringChipCamera => 'Camera';

  @override
  String get ringChipUnknown => '?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsDisplayName => 'Display name';

  @override
  String get settingsDisplayNameHint => 'Your name';

  @override
  String get settingsEmail => 'Email';

  @override
  String get settingsTimezone => 'Timezone';

  @override
  String get settingsTimezoneNotSet => 'Not set';

  @override
  String get settingsSelectTimezone => 'Select timezone';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAlarmNotifications => 'Alarm notifications';

  @override
  String get settingsAlarmNotificationsSubtitle =>
      'Show notifications when alarms fire';

  @override
  String get settingsDailyMissionReminders => 'Daily mission reminders';

  @override
  String get settingsDailyMissionRemindersSubtitle =>
      'Remind me when my AI mission is ready';

  @override
  String get settingsProductAnnouncements => 'Product announcements';

  @override
  String get settingsProductAnnouncementsSubtitle => 'Occasional news and tips';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsFreePlan => 'Free plan';

  @override
  String get settingsPremiumSubtitle =>
      'You have access to all premium features';

  @override
  String get settingsFreePlanSubtitle =>
      'Upgrade for AI missions and sleep insights';

  @override
  String get settingsManage => 'Manage';

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLogOut => 'Log out';

  @override
  String get settingsLogOutConfirmTitle => 'Log out?';

  @override
  String get settingsLogOutConfirmBody =>
      'You will need to sign in again to use the app.';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsUpsellMessage =>
      'Unlock detailed sleep and mission analytics with Premium.';

  @override
  String get statsLoadError => 'Failed to load statistics.';

  @override
  String get statsSleepDuration => 'Sleep duration';

  @override
  String get statsSleepDurationSubtitle => 'Hours per night';

  @override
  String get statsMissionSuccessRate => 'Mission success rate';

  @override
  String get statsMissionSuccessRateSubtitle => 'Percent of missions cleared';

  @override
  String get statsConsistency => 'Consistency';

  @override
  String get statsConsistencySubtitle => 'How regular your schedule is';

  @override
  String get statsAvgSleep => 'Avg sleep';

  @override
  String get statsMissions => 'Missions';

  @override
  String statsPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String statsHoursAxis(int hours) {
    return '${hours}h';
  }

  @override
  String get statsConsistencyBlurbExcellent =>
      'Excellent — your schedule is very regular.';

  @override
  String get statsConsistencyBlurbDecent =>
      'Decent — try to keep wake times steady.';

  @override
  String get statsConsistencyBlurbIrregular =>
      'Irregular — aim for consistent sleep and wake times.';

  @override
  String get statsNoDataTitle => 'No data yet';

  @override
  String get statsNoDataBody =>
      'Use a few alarms and your sleep insights will appear here.';

  @override
  String get statsUpsellTitle => 'Unlock your sleep insights';

  @override
  String get statsGoPremium => 'Go Premium';

  @override
  String get statsRetry => 'Retry';

  @override
  String get paywallGoPremium => 'Go Premium';

  @override
  String get paywallLoadError => 'Could not load plans. Please try again.';

  @override
  String get paywallChoosePlan => 'Choose your plan';

  @override
  String get paywallHeaderTitle => 'Wake up smarter with Premium';

  @override
  String get paywallHeaderSubtitle =>
      'Unlock AI missions, advanced statistics, and unlimited alarms.';

  @override
  String get paywallFeatureAiMissionsTitle => 'AI wake-up missions';

  @override
  String get paywallFeatureAiMissionsSubtitle =>
      'A fresh, AI-generated mission every day to truly wake you up.';

  @override
  String get paywallFeatureStatsTitle => 'Advanced sleep statistics';

  @override
  String get paywallFeatureStatsSubtitle =>
      'Trends, consistency score, and mission success over time.';

  @override
  String get paywallFeatureUnlimitedAlarmsTitle => 'Unlimited alarms';

  @override
  String get paywallFeatureUnlimitedAlarmsSubtitle =>
      'Create as many alarms as you need — no free-tier cap.';

  @override
  String get paywallFeatureAllMissionTypesTitle => 'All mission types';

  @override
  String get paywallFeatureAllMissionTypesSubtitle =>
      'Unlock every mission, including object-detection challenges.';

  @override
  String get paywallBestValue => 'BEST VALUE';

  @override
  String paywallFreeTrial(int days) {
    return '$days-day free trial';
  }

  @override
  String get paywallContinue => 'Continue';

  @override
  String paywallContinueWithPrice(String price) {
    return 'Continue • $price';
  }

  @override
  String get paywallPlansUnavailable => 'Plans unavailable';

  @override
  String get paywallRestoring => 'Restoring…';

  @override
  String get paywallRestorePurchases => 'Restore purchases';

  @override
  String get paywallLegalDisclaimer =>
      'Subscriptions auto-renew. Cancel anytime.';

  @override
  String get paywallTerms => 'Terms';

  @override
  String get paywallPrivacy => 'Privacy';

  @override
  String get paywallAlreadyPremiumTitle => 'You are Premium';

  @override
  String get paywallAlreadyPremiumBody =>
      'All premium features are unlocked. Thank you for your support!';

  @override
  String get paywallDone => 'Done';

  @override
  String get paywallRetry => 'Retry';
}
