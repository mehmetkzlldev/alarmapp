import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single onboarding question. Bilingual (TR/EN) inline so this one-off
/// questionnaire doesn't bloat the ARB files.
class OnboardingQuestion {
  const OnboardingQuestion({
    required this.id,
    required this.tr,
    required this.en,
    this.options = const [],
    this.isNameInput = false,
    this.emoji = '🌙',
  });

  final String id;
  final String tr;
  final String en;
  final List<OnboardingOption> options;
  final bool isNameInput;
  final String emoji;
}

class OnboardingOption {
  const OnboardingOption({required this.tr, required this.en, this.emoji = ''});
  final String tr;
  final String en;
  final String emoji;
}

/// The 10 onboarding questions shown in place of login/register.
const List<OnboardingQuestion> kOnboardingQuestions = [
  OnboardingQuestion(
    id: 'name',
    tr: 'Sana nasıl hitap edelim?',
    en: 'What should we call you?',
    isNameInput: true,
    emoji: '👋',
  ),
  OnboardingQuestion(
    id: 'bedtime',
    tr: 'Genelde gece kaçta yatıyorsun?',
    en: 'When do you usually go to bed?',
    emoji: '🛏️',
    options: [
      OnboardingOption(tr: '22:00\'den önce', en: 'Before 22:00', emoji: '🌆'),
      OnboardingOption(tr: '22:00 - 00:00', en: '22:00 - 00:00', emoji: '🌙'),
      OnboardingOption(tr: '00:00 - 02:00', en: '00:00 - 02:00', emoji: '🌌'),
      OnboardingOption(tr: '02:00\'den sonra', en: 'After 02:00', emoji: '🦉'),
    ],
  ),
  OnboardingQuestion(
    id: 'waketime',
    tr: 'Sabah kaçta kalkman gerekiyor?',
    en: 'When do you need to wake up?',
    emoji: '⏰',
    options: [
      OnboardingOption(tr: '05:00 - 06:00', en: '05:00 - 06:00', emoji: '🌅'),
      OnboardingOption(tr: '06:00 - 07:00', en: '06:00 - 07:00', emoji: '☀️'),
      OnboardingOption(tr: '07:00 - 08:00', en: '07:00 - 08:00', emoji: '🌤️'),
      OnboardingOption(tr: '08:00\'den sonra', en: 'After 08:00', emoji: '😎'),
    ],
  ),
  OnboardingQuestion(
    id: 'why',
    tr: 'Neden uyuyamıyorsun?',
    en: "Why can't you sleep?",
    emoji: '🤔',
    options: [
      OnboardingOption(tr: 'Çok düşünüyorum', en: 'Overthinking', emoji: '🧠'),
      OnboardingOption(tr: 'Telefon / ekran', en: 'Phone / screens', emoji: '📱'),
      OnboardingOption(tr: 'Kahve / enerji', en: 'Caffeine / energy', emoji: '☕'),
      OnboardingOption(tr: 'Stres / kaygı', en: 'Stress / anxiety', emoji: '😰'),
      OnboardingOption(tr: 'Bir sorunum yok', en: 'No real problem', emoji: '😌'),
    ],
  ),
  OnboardingQuestion(
    id: 'wakeups',
    tr: 'Gece kaç kez uyanıyorsun?',
    en: 'How often do you wake up at night?',
    emoji: '😴',
    options: [
      OnboardingOption(tr: 'Hiç', en: 'Never', emoji: '✅'),
      OnboardingOption(tr: '1-2 kez', en: '1-2 times', emoji: '🌗'),
      OnboardingOption(tr: '3+ kez', en: '3+ times', emoji: '🔁'),
    ],
  ),
  OnboardingQuestion(
    id: 'morning',
    tr: 'Sabah kendini nasıl hissediyorsun?',
    en: 'How do you feel in the morning?',
    emoji: '🌅',
    options: [
      OnboardingOption(tr: 'Dinç ve enerjik', en: 'Fresh & energetic', emoji: '💪'),
      OnboardingOption(tr: 'İdare eder', en: 'So-so', emoji: '🙂'),
      OnboardingOption(tr: 'Yorgun', en: 'Tired', emoji: '😪'),
      OnboardingOption(tr: 'Berbat', en: 'Awful', emoji: '🥴'),
    ],
  ),
  OnboardingQuestion(
    id: 'snooze',
    tr: 'Alarmı erteler misin?',
    en: 'Do you hit snooze?',
    emoji: '🔁',
    options: [
      OnboardingOption(tr: 'Sürekli, defalarca', en: 'Always, many times', emoji: '😅'),
      OnboardingOption(tr: 'Bazen', en: 'Sometimes', emoji: '🤷'),
      OnboardingOption(tr: 'Hiç, hemen kalkarım', en: 'Never, I get up', emoji: '⚡'),
    ],
  ),
  OnboardingQuestion(
    id: 'phone',
    tr: 'Yatmadan önce telefon kullanıyor musun?',
    en: 'Do you use your phone before bed?',
    emoji: '📱',
    options: [
      OnboardingOption(tr: 'Saatlerce', en: 'For hours', emoji: '🌀'),
      OnboardingOption(tr: 'Biraz', en: 'A little', emoji: '👌'),
      OnboardingOption(tr: 'Hayır', en: 'No', emoji: '🚫'),
    ],
  ),
  OnboardingQuestion(
    id: 'caffeine',
    tr: 'Gün içinde ne kadar kafein alıyorsun?',
    en: 'How much caffeine during the day?',
    emoji: '☕',
    options: [
      OnboardingOption(tr: 'Çok (3+ bardak)', en: 'A lot (3+ cups)', emoji: '🔥'),
      OnboardingOption(tr: 'Orta (1-2)', en: 'Moderate (1-2)', emoji: '☕'),
      OnboardingOption(tr: 'Az / hiç', en: 'Little / none', emoji: '💧'),
    ],
  ),
  OnboardingQuestion(
    id: 'goal',
    tr: 'En çok ne istiyorsun?',
    en: 'What do you want most?',
    emoji: '🎯',
    options: [
      OnboardingOption(tr: 'Erken kalkmak', en: 'Wake up early', emoji: '🌅'),
      OnboardingOption(tr: 'Kaliteli uyku', en: 'Better sleep', emoji: '😴'),
      OnboardingOption(tr: 'Alarmı kesin duymak', en: 'Actually hear the alarm', emoji: '🔔'),
      OnboardingOption(tr: 'Bir düzen kurmak', en: 'Build a routine', emoji: '📅'),
    ],
  ),
];

/// Persists onboarding answers (non-sensitive) for later personalization.
class OnboardingStore {
  OnboardingStore._();

  static const String _kName = 'onboarding.name';
  static const String _kAnswers = 'onboarding.answers';

  static Future<void> save({
    required String name,
    required Map<String, String> answers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name);
    await prefs.setString(_kAnswers, jsonEncode(answers));
  }

  static Future<String?> name() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kName);
  }

  static Future<Map<String, String>> answers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAnswers);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }
}
