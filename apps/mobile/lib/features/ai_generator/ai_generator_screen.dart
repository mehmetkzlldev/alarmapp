import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/core/theme/app_colors.dart';
import 'package:alarmy/features/missions/domain/entities/ai_mission.dart';
import 'package:alarmy/features/missions/domain/usecases/generate_custom_ai_mission.dart';
import 'package:alarmy/features/missions/presentation/providers/mission_providers.dart';
import 'package:alarmy/features/subscription/presentation/providers/subscription_provider.dart';

/// The premium "AI Mission Designer". Non-premium users see an enticing,
/// shimmering paywall (₺49). Premium users describe a wake-up mission and
/// Gemini designs it on demand.
class AiGeneratorScreen extends ConsumerStatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  ConsumerState<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends ConsumerState<AiGeneratorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _prompt = TextEditingController();
  late final AnimationController _anim;

  String _difficulty = 'medium';
  bool _generating = false;
  AiMission? _result;
  String? _error;

  bool get _isTr => Localizations.localeOf(context).languageCode == 'tr';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _prompt.text.trim();
    if (text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isTr
            ? 'Birkaç kelimeyle ne istediğini yaz 🙂'
            : 'Describe what you want in a few words 🙂'),
      ));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _generating = true;
      _error = null;
      _result = null;
    });
    final params = GenerateCustomParams(prompt: text, difficulty: _difficulty);
    var res = await ref.read(generateCustomAiMissionProvider).call(params);
    if (res.isLeft()) {
      // The AI service can return a transient 503 right after idle — retry once
      // so the user's first attempt feels instant instead of failing.
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      res = await ref.read(generateCustomAiMissionProvider).call(params);
    }
    if (!mounted) return;
    res.fold(
      (f) => setState(() {
        _generating = false;
        _error = _isTr
            ? 'Üretilemedi: ${f.message}'
            : 'Could not generate: ${f.message}';
      }),
      (m) => setState(() {
        _generating = false;
        _result = m;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(isPremiumProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTr ? 'AI Görev Üreteci' : 'AI Mission Designer'),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: premium ? _buildGenerator() : _buildPaywall(),
        ),
      ),
    );
  }

  // ===========================================================================
  // PAYWALL (non-premium) — the enticing pitch
  // ===========================================================================

  Widget _buildPaywall() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          _glowOrb(),
          const SizedBox(height: 24),
          // Title + shimmer PREMIUM badge
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              Text(
                _isTr ? 'AI Görev Üreteci' : 'AI Mission Designer',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _shimmerBadge('PREMIUM'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _isTr
                ? 'Hayalindeki uyandırma görevini SEN tasarla. Aklından geçeni '
                    'yaz, yapay zeka onu saniyeler içinde gerçek, sana özel bir '
                    'göreve dönüştürsün. Sıradan alarmlara veda et — her sabah '
                    'akıllı, eğlenceli, taptaze bir meydan okuma seni bekliyor.'
                : 'Design your dream wake-up mission. Type what you imagine and '
                    'AI turns it into a real, personalized challenge in seconds. '
                    'Say goodbye to boring alarms — a fresh, fun, smart mission '
                    'every morning.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.75),
              fontSize: 15.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          _benefit('♾️', _isTr ? 'Sınırsız özel görev' : 'Unlimited custom missions',
              _isTr ? 'İstediğin kadar üret, asla tükenmez.' : 'Generate as many as you like.'),
          _benefit('🧠', _isTr ? 'Gemini AI motoru' : 'Powered by Gemini AI',
              _isTr ? 'Google\'ın en akıllı modeli senin için tasarlar.' : "Google's smartest model designs for you."),
          _benefit('🎯', _isTr ? 'İstediğin zorlukta' : 'Any difficulty',
              _isTr ? 'Kolay, orta, zor — sabahına göre seç.' : 'Easy, medium, hard — your call.'),
          _benefit('⚡', _isTr ? 'Saniyeler içinde' : 'In seconds',
              _isTr ? 'Yaz, dokun, hazır. Beklemek yok.' : 'Type, tap, done.'),
          const SizedBox(height: 26),
          _priceBlock(),
          const SizedBox(height: 20),
          _GradientButton(
            label: _isTr ? 'Premium\'a Geç • 49 ₺' : 'Go Premium • ₺49',
            anim: _anim,
            onTap: _unlock,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              _isTr ? 'Şimdilik geç' : 'Maybe later',
              style: TextStyle(color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unlock() async {
    await ref.read(demoPremiumProvider.notifier).unlock();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.success,
      content: Text(_isTr
          ? '🎉 Premium açıldı! Hadi ilk görevini tasarla.'
          : '🎉 Premium unlocked! Design your first mission.'),
    ));
    // Rebuild → isPremiumProvider now true → generator shows.
    setState(() {});
  }

  Widget _glowOrb() {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = (0.5 + 0.5 * (_anim.value)); // 0.5..1
        return Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientEnd.withValues(alpha: 0.25 + 0.35 * t),
                blurRadius: 30 + 16 * t,
                spreadRadius: 2 + 4 * t,
              ),
            ],
          ),
          child: const Center(
            child: Text('✨', style: TextStyle(fontSize: 52)),
          ),
        );
      },
    );
  }

  Widget _benefit(String emoji, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
                Text(sub,
                    style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.6),
                        fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.seed.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.seed.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isTr ? '🔥 Sınırlı süre teklifi' : '🔥 Limited-time offer',
              style: const TextStyle(
                  color: AppColors.pink, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _isTr ? '99₺' : '₺99',
                style: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.4),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                child: const Text(
                  '49 ₺',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _isTr ? ' /ay' : ' /mo',
                style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isTr ? 'İstediğin an iptal et.' : 'Cancel anytime.',
            style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.5), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBadge(String text) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final pos = _anim.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1 - pos * 2, 0),
            end: Alignment(1 + pos * 2, 0),
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // GENERATOR (premium)
  // ===========================================================================

  Widget _buildGenerator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _shimmerBadge('PREMIUM'),
              const SizedBox(width: 8),
              Text(
                _isTr ? 'sende açık' : 'unlocked',
                style: TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _isTr ? 'Nasıl bir görev istersin?' : 'What kind of mission?',
            style: const TextStyle(
                color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _isTr
                ? 'Aklından geçeni yaz, AI sana özel tasarlasın.'
                : 'Type your idea — AI designs it for you.',
            style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _prompt,
            maxLines: 3,
            minLines: 2,
            maxLength: 200,
            cursorColor: AppColors.seed,
            style: const TextStyle(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: _isTr
                  ? 'Örn: Mutfağa gidip bir bardak su içmemi iste'
                  : 'e.g. Make me walk to the kitchen for water',
              hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_isTr ? 'Zorluk:' : 'Difficulty:',
                  style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _diffChip('easy', _isTr ? 'Kolay' : 'Easy'),
                    _diffChip('medium', _isTr ? 'Orta' : 'Medium'),
                    _diffChip('hard', _isTr ? 'Zor' : 'Hard'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _GradientButton(
            label: _generating
                ? (_isTr ? 'Tasarlanıyor...' : 'Designing...')
                : (_isTr ? '✨ Üret' : '✨ Generate'),
            anim: _anim,
            onTap: _generating ? null : _generate,
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildResultArea(),
          ),
        ],
      ),
    );
  }

  Widget _diffChip(String code, String label) {
    final sel = _difficulty == code;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _difficulty = code),
      selectedColor: AppColors.seed,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: sel ? Colors.white : AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.seed.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_generating) {
      return Column(
        key: const ValueKey('gen'),
        children: [
          _glowOrb(),
          const SizedBox(height: 14),
          Text(
            _isTr ? 'AI senin için tasarlıyor...' : 'AI is designing for you...',
            style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700),
          ),
        ],
      );
    }
    if (_error != null) {
      return Container(
        key: const ValueKey('err'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(_error!,
            style: const TextStyle(color: AppColors.danger),
            textAlign: TextAlign.center),
      );
    }
    final m = _result;
    if (m == null) return const SizedBox.shrink(key: ValueKey('empty'));
    return _MissionRevealCard(
      key: const ValueKey('result'),
      mission: m,
      isTr: _isTr,
      onRegenerate: _generate,
    );
  }
}

/// A gradient CTA button with a moving sheen.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.anim,
    required this.onTap,
  });

  final String label;
  final Animation<double> anim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.7 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientStart.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: AnimatedBuilder(
              animation: anim,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    final p = anim.value;
                    return LinearGradient(
                      begin: Alignment(-1 - p * 2, 0),
                      end: Alignment(1 + p * 2, 0),
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ).createShader(bounds);
                  },
                  child: child,
                );
              },
              child: Container(
                height: 56,
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The animated reveal of a generated mission.
class _MissionRevealCard extends StatelessWidget {
  const _MissionRevealCard({
    super.key,
    required this.mission,
    required this.isTr,
    required this.onRegenerate,
  });

  final AiMission mission;
  final bool isTr;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final target = mission.targetObject;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientEnd.withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (r) => AppColors.brandGradient.createShader(r),
              child: Text(
                isTr ? 'Senin Görevin' : 'Your Mission',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mission.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.3),
            ),
            if (target != null && target.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📸 ${target.toUpperCase()}',
                  style: const TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.w800),
                ),
              ),
            ],
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: onRegenerate,
              icon: const Icon(Icons.refresh, color: AppColors.seed),
              label: Text(isTr ? 'Tekrar Üret' : 'Regenerate',
                  style: const TextStyle(
                      color: AppColors.seed, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
