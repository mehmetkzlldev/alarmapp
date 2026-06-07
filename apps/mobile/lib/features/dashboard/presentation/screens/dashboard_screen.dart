import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import 'package:alarmy/core/theme/app_colors.dart';
import '../../../ai_generator/ai_generator_screen.dart';
import '../../../alarm_ring/presentation/screens/wake_challenge_screen.dart';
import '../../../alarms/domain/entities/alarm_entity.dart';
import '../../../alarms/presentation/providers/alarms_provider.dart';
import '../../../alarms/presentation/screens/alarm_create_screen.dart';
import '../../../alarms/presentation/screens/alarm_list_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/sleep_recommendation.dart';

/// Home dashboard — bright "Mango Sunrise" theme with staggered entrance
/// animations, a personalized sleep-recommendation card, the premium AI mission
/// designer entry, and quick actions.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  bool get _isTr => Localizations.localeOf(context).languageCode == 'tr';

  /// Staggered fade + slide-up for the card at [index].
  Widget _staggered(int index, Widget child) {
    final start = (index * 0.09).clamp(0.0, 0.7);
    final anim = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 26 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  void _openAlarms() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const AlarmListScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nextAlarm = ref.watch(nextAlarmProvider);
    final alarmsAsync = ref.watch(alarmsNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final recAsync = ref.watch(sleepRecommendationProvider);

    final name = user?.displayName.trim() ?? '';
    final showName = name.isNotEmpty && name.toLowerCase() != 'misafir';

    var i = 0;
    final cards = <Widget>[];
    final rec = recAsync.valueOrNull;
    if (rec != null) {
      cards.add(_staggered(i++, _SleepRecCard(rec: rec, isTr: _isTr)));
    }
    cards.add(_staggered(
      i++,
      _NextAlarmCard(
        alarm: nextAlarm,
        loading: alarmsAsync.isLoading && !alarmsAsync.hasValue,
        onTap: _openAlarms,
      ),
    ));
    cards.add(_staggered(i++, _AiDesignerCard(pulse: _pulse, isTr: _isTr)));
    cards.add(_staggered(i++, _ActionTile(
      emoji: '🔥',
      title: l10n.dashTryChallengeTitle,
      subtitle: l10n.dashTryChallengeSubtitle,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WakeChallengeScreen()),
      ),
    )));
    cards.add(_staggered(i++, _ActionTile(
      emoji: '⏰',
      title: l10n.dashNavAlarmsTitle,
      subtitle: l10n.dashNavAlarmsSubtitle,
      onTap: _openAlarms,
    )));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AlarmCreateScreen()),
        ),
        icon: const Icon(Icons.add_alarm),
        label: Text(_isTr ? 'Alarm Kur' : 'Add alarm'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.seed,
            onRefresh: () =>
                ref.read(alarmsNotifierProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
              children: [
                _staggered(
                  0,
                  _Header(
                    greeting: l10n.dashGoodMorning,
                    name: showName ? name : null,
                    onAlarms: _openAlarms,
                  ),
                ),
                const SizedBox(height: 18),
                for (final c in cards) ...[c, const SizedBox(height: 14)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.name, required this.onAlarms});

  final String greeting;
  final String? name;
  final VoidCallback onAlarms;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('☀️', style: TextStyle(fontSize: 34)),
        const SizedBox(width: 12),
        Expanded(
          child: ShaderMask(
            shaderCallback: (r) => AppColors.brandGradient.createShader(r),
            child: Text(
              name == null ? greeting : '$greeting,\n$name',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onAlarms,
          icon: const Icon(Icons.list_alt_rounded, color: AppColors.ink),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sleep recommendation card
// ---------------------------------------------------------------------------

class _SleepRecCard extends StatelessWidget {
  const _SleepRecCard({required this.rec, required this.isTr});

  final SleepRecommendation rec;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.seed.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Önerilen yatış saatin' : 'Your target bedtime',
                style: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.6),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (r) => AppColors.brandGradient.createShader(r),
            child: Text(
              rec.windowLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              rec.tip(isTr),
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.85),
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next alarm card
// ---------------------------------------------------------------------------

class _NextAlarmCard extends StatelessWidget {
  const _NextAlarmCard({
    required this.alarm,
    required this.loading,
    required this.onTap,
  });

  final AlarmEntity? alarm;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      shadowColor: AppColors.seed.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.alarm, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: loading
                    ? const _Skeleton()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashNextAlarm,
                            style: TextStyle(
                              color: AppColors.ink.withValues(alpha: 0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (alarm == null)
                            Text(
                              l10n.dashNoActiveAlarms,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else ...[
                            Text(
                              _formatTime(context, alarm!),
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _subtitle(l10n, alarm!),
                              style: TextStyle(
                                color: AppColors.ink.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.ink.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, AlarmEntity a) {
    final hm = a.hourMinute;
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final mm = hm.minute.toString().padLeft(2, '0');
    if (use24h) return '${hm.hour.toString().padLeft(2, '0')}:$mm';
    final l10n = AppLocalizations.of(context);
    final period = hm.hour < 12 ? l10n.timeAm : l10n.timePm;
    final h12 = hm.hour % 12 == 0 ? 12 : hm.hour % 12;
    return '$h12:$mm $period';
  }

  String _subtitle(AppLocalizations l10n, AlarmEntity a) {
    final label = a.label.isEmpty ? l10n.alarmDefaultLabel : a.label;
    if (a.missions.isEmpty) return label;
    return l10n.dashAlarmMissionCount(label, a.missions.length);
  }
}

// ---------------------------------------------------------------------------
// AI Mission Designer card (premium entry) — the flashy one
// ---------------------------------------------------------------------------

class _AiDesignerCard extends StatelessWidget {
  const _AiDesignerCard({required this.pulse, required this.isTr});

  final Animation<double> pulse;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientEnd.withValues(alpha: 0.25 + 0.25 * t),
                blurRadius: 18 + 10 * t,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AiGeneratorScreen()),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 34)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isTr ? 'AI Görev Üreteci' : 'AI Mission Designer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ShaderMask(
                                shaderCallback: (r) =>
                                    AppColors.brandGradient.createShader(r),
                                child: const Text(
                                  'PREMIUM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTr
                              ? 'Hayalindeki uyandırma görevini AI tasarlasın ✦'
                              : 'Let AI design your dream wake-up mission ✦',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic action tile
// ---------------------------------------------------------------------------

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1.5,
      shadowColor: AppColors.seed.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text(subtitle,
                        style: TextStyle(
                            color: AppColors.ink.withValues(alpha: 0.6),
                            fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.ink.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton placeholder
// ---------------------------------------------------------------------------

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(110, 12), bar(170, 22)],
    );
  }
}
