// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'AI Alarm';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonDone => 'Bitti';

  @override
  String get commonClose => 'Kapat';

  @override
  String get timeAm => 'ÖÖ';

  @override
  String get timePm => 'ÖS';

  @override
  String get dayShortSun => 'Paz';

  @override
  String get dayShortMon => 'Pzt';

  @override
  String get dayShortTue => 'Sal';

  @override
  String get dayShortWed => 'Çar';

  @override
  String get dayShortThu => 'Per';

  @override
  String get dayShortFri => 'Cum';

  @override
  String get dayShortSat => 'Cmt';

  @override
  String get dayLetterSun => 'P';

  @override
  String get dayLetterMon => 'P';

  @override
  String get dayLetterTue => 'S';

  @override
  String get dayLetterWed => 'Ç';

  @override
  String get dayLetterThu => 'P';

  @override
  String get dayLetterFri => 'C';

  @override
  String get dayLetterSat => 'C';

  @override
  String get missionDifficultyEasy => 'Kolay';

  @override
  String get missionDifficultyMedium => 'Orta';

  @override
  String get missionDifficultyHard => 'Zor';

  @override
  String get alarmListTitle => 'Alarmlar';

  @override
  String get alarmNewTitle => 'Yeni alarm';

  @override
  String get alarmEditTitle => 'Alarmı düzenle';

  @override
  String get alarmListLoadError =>
      'Alarmların yüklenirken bir şeyler ters gitti.';

  @override
  String get alarmActionFailed => 'İşlem başarısız oldu. Tekrar deneyin.';

  @override
  String alarmListEmpty(String buttonLabel) {
    return 'Henüz alarm yok. Eklemek için \"$buttonLabel\" düğmesine dokunun.';
  }

  @override
  String get alarmDeleteTitle => 'Alarmı sil?';

  @override
  String alarmDeleteConfirm(String label) {
    return '\"$label\" kalıcı olarak silinecek.';
  }

  @override
  String get alarmDefaultLabel => 'Alarm';

  @override
  String get alarmLabelField => 'Etiket';

  @override
  String get alarmRepeatLabel => 'Tekrar';

  @override
  String get alarmSoundHapticsLabel => 'Ses ve titreşim';

  @override
  String get alarmSoundField => 'Ses';

  @override
  String get alarmVibration => 'Titreşim';

  @override
  String get alarmSnoozeLabel => 'Erteleme';

  @override
  String get alarmAllowSnooze => 'Ertelemeye izin ver';

  @override
  String get alarmSnoozeInterval => 'Aralık';

  @override
  String get alarmSnoozeIntervalSuffix => 'dk';

  @override
  String get alarmMaxSnoozes => 'En fazla erteleme';

  @override
  String get alarmMaxSnoozesSuffix => 'kez';

  @override
  String get alarmActive => 'Aktif';

  @override
  String get alarmSoundDefault => 'Varsayılan';

  @override
  String get alarmSoundGentleChimes => 'Yumuşak çanlar';

  @override
  String get alarmSoundMorningBirds => 'Sabah kuşları';

  @override
  String get alarmSoundClassicBell => 'Klasik zil';

  @override
  String get alarmSoundRooster => 'Horoz';

  @override
  String get alarmUpgradeTitle => 'Yükseltme gerekli';

  @override
  String alarmUpgradeBody(String message) {
    return '$message\n\nÜcretsiz hesaplar yalnızca birkaç alarmla sınırlıdır. Sınırsız alarm ve AI görevleri için Premium\'a yükseltin.';
  }

  @override
  String get alarmUpgradeNotNow => 'Şimdi değil';

  @override
  String get alarmUpgradeSeePlans => 'Planları gör';

  @override
  String get alarmRepeatOnce => 'Bir kez';

  @override
  String get alarmRepeatEveryDay => 'Her gün';

  @override
  String alarmBadgeMath(String difficulty) {
    return 'Matematik · $difficulty';
  }

  @override
  String alarmBadgeShake(String difficulty) {
    return 'Salla · $difficulty';
  }

  @override
  String alarmBadgePhoto(String difficulty) {
    return 'Fotoğraf · $difficulty';
  }

  @override
  String alarmBadgePhotoTarget(String target) {
    return 'Fotoğraf: $target';
  }

  @override
  String get alarmBadgeUnknown => 'Bilinmiyor';

  @override
  String get alarmMissionsTitle => 'Görevler';

  @override
  String get alarmMissionAdd => 'Ekle';

  @override
  String get alarmMissionsEmpty =>
      'Görev yok. Alarm tek dokunuşla kapatılabilir.';

  @override
  String get alarmMissionAddSheetTitle => 'Görev ekle';

  @override
  String get alarmMissionMathTitle => 'Matematik problemi';

  @override
  String get alarmMissionShakeTitle => 'Salla';

  @override
  String get alarmMissionPhotoTitle => 'Bir nesnenin fotoğrafını çek';

  @override
  String get alarmMissionMathDesc => 'Kapatmak için denklemleri çöz';

  @override
  String get alarmMissionShakeDesc => 'Kapatmak için telefonu salla';

  @override
  String get alarmMissionPhotoDesc => 'Gerçek bir nesnenin fotoğrafını çek';

  @override
  String get alarmMissionRemove => 'Görevi kaldır';

  @override
  String get alarmMissionTargetObject => 'Hedef nesne';

  @override
  String get dashGoodMorning => 'Günaydın';

  @override
  String get dashAllAlarms => 'Tüm alarmlar';

  @override
  String get dashTryChallengeTitle => 'Uyanma testini dene';

  @override
  String get dashTryChallengeSubtitle =>
      '10 sn salla → matematik → kamera. Hemen deneyimle.';

  @override
  String get dashNextAlarm => 'Sıradaki alarm';

  @override
  String get dashNoActiveAlarms => 'Aktif alarm yok';

  @override
  String dashAlarmMissionCount(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görev',
      one: '1 görev',
    );
    return '$label · $_temp0';
  }

  @override
  String get dashAiMissionUnavailable => 'Bugünün AI görevi kullanılamıyor.';

  @override
  String get dashAiMissionTitle => 'Bugünün AI görevi';

  @override
  String get dashAiMissionUnlock =>
      'Premium ile günlük AI görevlerinin kilidini aç.';

  @override
  String get dashGoPremium => 'Premium\'a geç';

  @override
  String get dashAiMissionNone =>
      'Bugün için henüz görev yok. Daha sonra tekrar kontrol et.';

  @override
  String get dashThisWeek => 'Bu hafta';

  @override
  String get dashStatsUnavailable => 'İstatistik yok';

  @override
  String get dashStatAvgSleep => 'Ort. uyku';

  @override
  String get dashStatConsistency => 'Tutarlılık';

  @override
  String get dashStatMissions => 'Görevler';

  @override
  String dashDurationHm(int h, int m) {
    return '${h}sa ${m}dk';
  }

  @override
  String get dashNavAlarmsTitle => 'Alarmlar';

  @override
  String get dashNavAlarmsSubtitle => 'Alarmlarını görüntüle ve yönet';

  @override
  String get authWelcomeBackTitle => 'Tekrar hoş geldin';

  @override
  String get authWelcomeBackSubtitle =>
      'Sabahlarını yolunda tutmak için giriş yap.';

  @override
  String get authEmailLabel => 'E-posta';

  @override
  String get authPasswordLabel => 'Şifre';

  @override
  String get authPasswordRequired => 'Şifre gerekli';

  @override
  String get authSignInButton => 'Giriş yap';

  @override
  String get authNoAccountPrompt => 'Hesabın yok mu?';

  @override
  String get authCreateOneButton => 'Hesap oluştur';

  @override
  String get authLoginFailed => 'Giriş başarısız. Lütfen tekrar dene.';

  @override
  String get authRegisterTitle => 'Hesap oluştur';

  @override
  String get authRegisterSubtitle => 'Daha akıllı uyanmaya başla.';

  @override
  String get authDisplayNameLabel => 'Görünen ad';

  @override
  String get authConfirmPasswordLabel => 'Şifreyi onayla';

  @override
  String get authCreateAccountButton => 'Hesap oluştur';

  @override
  String get authHaveAccountPrompt => 'Zaten hesabın var mı?';

  @override
  String get authRegistrationFailed => 'Kayıt başarısız. Lütfen tekrar dene.';

  @override
  String get authGenericError => 'Bir şeyler ters gitti. Lütfen tekrar dene.';

  @override
  String get authShowPassword => 'Şifreyi göster';

  @override
  String get authHidePassword => 'Şifreyi gizle';

  @override
  String get authEmailRequired => 'E-posta gerekli';

  @override
  String get authEmailInvalid => 'Geçerli bir e-posta adresi gir';

  @override
  String authPasswordMinLength(int n) {
    return 'Şifre en az $n karakter olmalı';
  }

  @override
  String get authPasswordComplexity => 'En az bir harf ve bir rakam kullan';

  @override
  String get authConfirmPasswordRequired => 'Lütfen şifreni onayla';

  @override
  String get authPasswordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get authDisplayNameRequired => 'Görünen ad gerekli';

  @override
  String get authDisplayNameTooShort => 'Görünen ad çok kısa';

  @override
  String get authDisplayNameTooLong => 'Görünen ad çok uzun';

  @override
  String get ringWakeUpExclaim => 'Kalk!';

  @override
  String missionStepOfTotal(int step, int total, String kind) {
    return 'Görev $step/$total  ·  $kind';
  }

  @override
  String get missionKindShake => 'Salla';

  @override
  String get missionKindMath => 'Matematik';

  @override
  String get missionKindCamera => 'Kamera';

  @override
  String get missionAlarmDismissed => 'Alarm kapatıldı';

  @override
  String get missionHaveAGreatDay => 'Harika bir gün geçir! ☀️';

  @override
  String get missionRetry => 'Tekrar dene';

  @override
  String get missionSolveToDismiss => 'Kapatmak için çöz';

  @override
  String get missionAnswerHint => 'Cevap';

  @override
  String get missionSubmit => 'Gönder';

  @override
  String get missionEnterANumber => 'Bir sayı gir.';

  @override
  String get missionWrongAnswer => 'Yanlış cevap. İşte yeni bir soru.';

  @override
  String get missionFailedToLoadProblem => 'Soru yüklenemedi.';

  @override
  String get missionShakeStart => 'SALLA!';

  @override
  String get missionShakeNice => 'HARİKA!';

  @override
  String get missionTapAsFast => 'Sallamak için olabildiğince hızlı dokun';

  @override
  String get missionKeepShaking => 'Telefonu sallamaya devam et';

  @override
  String get missionShakeDone => 'Bitti!';

  @override
  String missionShakeRemaining(int remaining) {
    return '$remaining sn';
  }

  @override
  String missionShakeCount(int count) {
    return 'sallama: $count';
  }

  @override
  String get missionKeepGoing => 'Devam et!';

  @override
  String get missionShakeToRun => 'Zamanlayıcıyı başlatmak için salla…';

  @override
  String get missionPointCameraAt => 'Kamerayı şuna doğrult:';

  @override
  String get missionTakePhotoOfYour => 'Şunun fotoğrafını çek:';

  @override
  String get missionAnyObject => 'HERHANGİ BİR NESNE';

  @override
  String get objToothbrush => 'Diş Fırçası';

  @override
  String get objSink => 'Lavabo';

  @override
  String get objCoffeeMug => 'Kupa';

  @override
  String get objKeys => 'Anahtar';

  @override
  String get objShoes => 'Ayakkabı';

  @override
  String get objLaptop => 'Dizüstü Bilgisayar';

  @override
  String get missionCameraOpenError => 'Kamera açılamadı. İzinleri kontrol et.';

  @override
  String missionDoesNotLookLike(String target) {
    return 'Bu bir $target gibi görünmüyor. Tekrar dene.';
  }

  @override
  String get missionOpeningCamera => 'Kamera açılıyor…';

  @override
  String get missionAnalyzing => 'Analiz ediliyor…';

  @override
  String get missionTryAgain => 'Tekrar dene';

  @override
  String get missionVerified => 'Doğrulandı';

  @override
  String get missionOpenCamera => 'Kamerayı aç';

  @override
  String get missionAnalyzingYourPhoto => 'Fotoğrafın analiz ediliyor…';

  @override
  String get missionUploadingAndChecking => 'Yükleniyor ve kontrol ediliyor…';

  @override
  String get missionObjectDetected => 'Nesne algılandı! ✓';

  @override
  String missionConfirmedSure(int percent) {
    return 'Onaylandı! (%$percent emin)';
  }

  @override
  String missionNotDetectedConfidence(int percent) {
    return 'Algılanmadı (%$percent güven)';
  }

  @override
  String missionSaw(String objects) {
    return 'Görülen: $objects';
  }

  @override
  String get missionAnyObjectHint =>
      'Yataktan kalk ve gördüğün herhangi bir şeyin fotoğrafını çek.';

  @override
  String get missionSpecificObjectHint => 'Kamerayı nesneye doğrult ve çek.';

  @override
  String get ringWakeUp => 'Kalk!';

  @override
  String get ringAlarm => 'Alarm';

  @override
  String get ringSnoozeLimitReached => 'Erteleme sınırına ulaşıldı';

  @override
  String get ringCouldNotLoadAlarm =>
      'Alarm yüklenemedi. Yine de erteleyebilir veya durdurabilirsin.';

  @override
  String get ringCompleteMissionToStop =>
      'Alarmı durdurmak için görevini tamamla';

  @override
  String get ringStartMission => 'Göreve başla';

  @override
  String ringSnoozeWithDetails(int minutes, int remaining) {
    return 'Ertele (${minutes}dk · $remaining kaldı)';
  }

  @override
  String get ringWakeUpLoud => 'KALK!';

  @override
  String get ringCompleteEveryMission =>
      'Alarmı durdurmak için tüm görevleri tamamla';

  @override
  String get ringImAwakeStartMissions => 'Uyandım — görevlere başla';

  @override
  String get ringExitDemo => 'Demoyu kapat';

  @override
  String get ringChipShake => 'Salla';

  @override
  String get ringChipMath => 'Matematik';

  @override
  String get ringChipCamera => 'Kamera';

  @override
  String get ringChipUnknown => '?';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsDisplayName => 'Görünen ad';

  @override
  String get settingsDisplayNameHint => 'Adınız';

  @override
  String get settingsEmail => 'E-posta';

  @override
  String get settingsTimezone => 'Saat dilimi';

  @override
  String get settingsTimezoneNotSet => 'Ayarlanmadı';

  @override
  String get settingsSelectTimezone => 'Saat dilimi seçin';

  @override
  String get settingsCancel => 'İptal';

  @override
  String get settingsSave => 'Kaydet';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsAlarmNotifications => 'Alarm bildirimleri';

  @override
  String get settingsAlarmNotificationsSubtitle =>
      'Alarmlar çaldığında bildirim göster';

  @override
  String get settingsDailyMissionReminders => 'Günlük görev hatırlatıcıları';

  @override
  String get settingsDailyMissionRemindersSubtitle =>
      'AI görevim hazır olduğunda bana hatırlat';

  @override
  String get settingsProductAnnouncements => 'Ürün duyuruları';

  @override
  String get settingsProductAnnouncementsSubtitle =>
      'Ara sıra haberler ve ipuçları';

  @override
  String get settingsSubscription => 'Abonelik';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsFreePlan => 'Ücretsiz plan';

  @override
  String get settingsPremiumSubtitle =>
      'Tüm premium özelliklere erişiminiz var';

  @override
  String get settingsFreePlanSubtitle =>
      'AI görevleri ve uyku içgörüleri için yükseltin';

  @override
  String get settingsManage => 'Yönet';

  @override
  String get settingsUpgrade => 'Yükselt';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsLogOut => 'Çıkış yap';

  @override
  String get settingsLogOutConfirmTitle => 'Çıkış yapılsın mı?';

  @override
  String get settingsLogOutConfirmBody =>
      'Uygulamayı kullanmak için tekrar giriş yapmanız gerekecek.';

  @override
  String get statsTitle => 'İstatistikler';

  @override
  String get statsUpsellMessage =>
      'Premium ile ayrıntılı uyku ve görev analizlerinin kilidini açın.';

  @override
  String get statsLoadError => 'İstatistikler yüklenemedi.';

  @override
  String get statsSleepDuration => 'Uyku süresi';

  @override
  String get statsSleepDurationSubtitle => 'Gece başına saat';

  @override
  String get statsMissionSuccessRate => 'Görev başarı oranı';

  @override
  String get statsMissionSuccessRateSubtitle => 'Tamamlanan görevlerin yüzdesi';

  @override
  String get statsConsistency => 'Tutarlılık';

  @override
  String get statsConsistencySubtitle =>
      'Programınızın ne kadar düzenli olduğu';

  @override
  String get statsAvgSleep => 'Ort. uyku';

  @override
  String get statsMissions => 'Görevler';

  @override
  String statsPercentValue(int percent) {
    return '%$percent';
  }

  @override
  String statsHoursAxis(int hours) {
    return '${hours}sa';
  }

  @override
  String get statsConsistencyBlurbExcellent =>
      'Mükemmel — programınız çok düzenli.';

  @override
  String get statsConsistencyBlurbDecent =>
      'İdare eder — uyanma saatlerini sabit tutmaya çalışın.';

  @override
  String get statsConsistencyBlurbIrregular =>
      'Düzensiz — tutarlı uyku ve uyanma saatleri hedefleyin.';

  @override
  String get statsNoDataTitle => 'Henüz veri yok';

  @override
  String get statsNoDataBody =>
      'Birkaç alarm kullanın; uyku içgörüleriniz burada görünecek.';

  @override
  String get statsUpsellTitle => 'Uyku içgörülerinizin kilidini açın';

  @override
  String get statsGoPremium => 'Premium\'a geç';

  @override
  String get statsRetry => 'Tekrar dene';

  @override
  String get paywallGoPremium => 'Premium\'a geç';

  @override
  String get paywallLoadError => 'Planlar yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get paywallChoosePlan => 'Planınızı seçin';

  @override
  String get paywallHeaderTitle => 'Premium ile daha akıllı uyanın';

  @override
  String get paywallHeaderSubtitle =>
      'AI görevlerinin, gelişmiş istatistiklerin ve sınırsız alarmın kilidini açın.';

  @override
  String get paywallFeatureAiMissionsTitle => 'AI uyanma görevleri';

  @override
  String get paywallFeatureAiMissionsSubtitle =>
      'Sizi gerçekten uyandırmak için her gün taze, AI tarafından oluşturulan bir görev.';

  @override
  String get paywallFeatureStatsTitle => 'Gelişmiş uyku istatistikleri';

  @override
  String get paywallFeatureStatsSubtitle =>
      'Zaman içinde eğilimler, tutarlılık puanı ve görev başarısı.';

  @override
  String get paywallFeatureUnlimitedAlarmsTitle => 'Sınırsız alarm';

  @override
  String get paywallFeatureUnlimitedAlarmsSubtitle =>
      'İhtiyacınız kadar alarm oluşturun — ücretsiz sürüm sınırı yok.';

  @override
  String get paywallFeatureAllMissionTypesTitle => 'Tüm görev türleri';

  @override
  String get paywallFeatureAllMissionTypesSubtitle =>
      'Nesne algılama görevleri dahil her görevin kilidini açın.';

  @override
  String get paywallBestValue => 'EN İYİ DEĞER';

  @override
  String paywallFreeTrial(int days) {
    return '$days günlük ücretsiz deneme';
  }

  @override
  String get paywallContinue => 'Devam et';

  @override
  String paywallContinueWithPrice(String price) {
    return 'Devam et • $price';
  }

  @override
  String get paywallPlansUnavailable => 'Planlar kullanılamıyor';

  @override
  String get paywallRestoring => 'Geri yükleniyor…';

  @override
  String get paywallRestorePurchases => 'Satın alımları geri yükle';

  @override
  String get paywallLegalDisclaimer =>
      'Abonelikler otomatik yenilenir. İstediğiniz zaman iptal edin.';

  @override
  String get paywallTerms => 'Şartlar';

  @override
  String get paywallPrivacy => 'Gizlilik';

  @override
  String get paywallAlreadyPremiumTitle => 'Premium üyesiniz';

  @override
  String get paywallAlreadyPremiumBody =>
      'Tüm premium özellikler açık. Desteğiniz için teşekkürler!';

  @override
  String get paywallDone => 'Tamam';

  @override
  String get paywallRetry => 'Tekrar dene';
}
