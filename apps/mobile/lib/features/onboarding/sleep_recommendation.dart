import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_data.dart';

/// A bedtime recommendation + personalized tip derived from onboarding answers.
class SleepRecommendation {
  const SleepRecommendation({
    required this.bedStart,
    required this.bedEnd,
    required this.wakeLabel,
    required this.tipTr,
    required this.tipEn,
    required this.qualityWarning,
  });

  final TimeOfDay bedStart;
  final TimeOfDay bedEnd;
  final String wakeLabel; // e.g. "06:00 - 07:00"
  final String tipTr;
  final String tipEn;
  final bool qualityWarning;

  String tip(bool isTr) => isTr ? tipTr : tipEn;

  static String fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get windowLabel => '${fmt(bedStart)} – ${fmt(bedEnd)}';

  /// Compute a target bedtime window (~7–8h before the earliest wake hour) plus
  /// a single actionable tip based on the user's stated root cause + habits.
  static SleepRecommendation? fromAnswers(Map<String, String> a) {
    final wake = a['waketime'];
    if (wake == null) return null;

    final int wakeHour = switch (wake) {
      '05:00 - 06:00' => 5,
      '06:00 - 07:00' => 6,
      '07:00 - 08:00' => 7,
      _ => 8, // 'After 08:00'
    };

    // Target bedtime = ~8h before the earliest wake hour; window spans 1h
    // (so ~7–8h of sleep). Wrap into a 0..1440 minute range.
    final int startMins = (((wakeHour - 8) * 60) % 1440 + 1440) % 1440;
    final int endMins = (startMins + 60) % 1440;
    final bedStart = TimeOfDay(hour: startMins ~/ 60, minute: startMins % 60);
    final bedEnd = TimeOfDay(hour: endMins ~/ 60, minute: endMins % 60);

    String tipTr;
    String tipEn;
    switch (a['why']) {
      case 'Phone / screens':
        tipTr = '📱 Yatmadan 1 saat önce telefonu bırak — mavi ışık uykunu kaçırıyor.';
        tipEn = '📱 Put your phone down 1h before bed — blue light delays sleep.';
        break;
      case 'Caffeine / energy':
        tipTr = '☕ Öğleden sonra kafeini kes; akşam bitki çayına geç.';
        tipEn = '☕ No caffeine after 2pm — switch to herbal tea in the evening.';
        break;
      case 'Overthinking':
        tipTr = '🧠 Yatmadan 5 dakika nefes/günlük ile zihnini sustur.';
        tipEn = '🧠 A 5-min breathing or journaling wind-down quiets the mind.';
        break;
      case 'Stress / anxiety':
        tipTr = '😌 Sabit bir yatış saati bedenine "rahatla" sinyali verir.';
        tipEn = '😌 A consistent bedtime tells your body it is time to relax.';
        break;
      default:
        tipTr = '🌙 Düzenin harika — bu saatlere sadık kal, alışkanlık otursun.';
        tipEn = '🌙 Great routine — stick to these hours to lock in the habit.';
    }
    if (a['caffeine'] == 'A lot (3+ cups)') {
      tipTr += ' Kahveyi azaltmak uykunu derinleştirir.';
      tipEn += ' Cutting back on coffee deepens your sleep.';
    }

    final warn = a['wakeups'] == '3+ times' || a['morning'] == 'Awful';

    return SleepRecommendation(
      bedStart: bedStart,
      bedEnd: bedEnd,
      wakeLabel: wake,
      tipTr: tipTr,
      tipEn: tipEn,
      qualityWarning: warn,
    );
  }
}

/// Loads onboarding answers and computes the recommendation (null if the user
/// hasn't onboarded / no answers stored).
final sleepRecommendationProvider =
    FutureProvider<SleepRecommendation?>((ref) async {
  final answers = await OnboardingStore.answers();
  if (answers.isEmpty) return null;
  return SleepRecommendation.fromAnswers(answers);
});
