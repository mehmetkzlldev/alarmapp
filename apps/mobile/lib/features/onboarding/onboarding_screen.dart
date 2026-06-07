import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alarmy/core/router/route_names.dart';
import 'package:alarmy/core/theme/app_colors.dart';
import 'package:alarmy/features/auth/presentation/providers/auth_provider.dart';
import 'onboarding_data.dart';

/// Replaces login/register. A bright "Mango Sunrise" sleep questionnaire that
/// silently provisions an anonymous account in the background, then enters.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _index = 0;
  final Map<String, String> _answers = {};
  String? _selected;
  bool _anonStarted = false;
  bool _finishing = false;
  bool _flashing = false;
  double _flashOpacity = 0;

  bool get _isTr => Localizations.localeOf(context).languageCode == 'tr';
  int get _total => kOnboardingQuestions.length;
  bool get _isLast => _index == _total - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _qText(OnboardingQuestion q) => _isTr ? q.tr : q.en;
  String _oText(OnboardingOption o) => _isTr ? o.tr : o.en;

  void _startAnonSession(String name) {
    if (_anonStarted) return;
    _anonStarted = true;
    ref
        .read(authNotifierProvider.notifier)
        .ensureAnonymousSession(displayName: name);
  }

  void _onNameNext() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTr ? 'Bir isim yaz 🙂' : 'Enter a name 🙂'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _answers['name'] = name;
    _startAnonSession(name);
    _advance();
  }

  void _onOptionTap(OnboardingQuestion q, OnboardingOption o) {
    setState(() => _selected = o.en);
    Future<void>.delayed(const Duration(milliseconds: 230), () {
      if (!mounted) return;
      _answers[q.id] = o.en;
      if (_isLast) {
        _finish();
      } else {
        _advance();
      }
    });
  }

  void _advance() {
    _whiteTransition(() {
      setState(() {
        _index++;
        _selected = null;
      });
      _pageController.jumpToPage(_index);
    });
  }

  void _back() {
    if (_index == 0) return;
    _whiteTransition(() {
      setState(() {
        _index--;
        _selected = null;
      });
      _pageController.jumpToPage(_index);
    });
  }

  /// Soft white dissolve between questions: fade a white sheet in, swap the
  /// page underneath, then fade it back out.
  Future<void> _whiteTransition(VoidCallback midpoint) async {
    if (_flashing) return;
    _flashing = true;
    setState(() => _flashOpacity = 1);
    await Future<void>.delayed(const Duration(milliseconds: 210));
    if (!mounted) {
      _flashing = false;
      return;
    }
    midpoint();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    if (!mounted) {
      _flashing = false;
      return;
    }
    setState(() => _flashOpacity = 0);
    await Future<void>.delayed(const Duration(milliseconds: 230));
    _flashing = false;
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final name = _answers['name'] ??
        _nameController.text.trim().ifEmptyFallback(_isTr ? 'Misafir' : 'Guest');
    await OnboardingStore.save(name: name, answers: _answers);

    await ref
        .read(authNotifierProvider.notifier)
        .ensureAnonymousSession(displayName: name);

    if (!mounted) return;
    if (ref.read(isAuthenticatedProvider)) {
      context.go(Routes.dashboard);
    } else {
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTr
              ? 'Bağlanılamadı, tekrar dene (sunucu uyanıyor olabilir).'
              : "Couldn't connect, try again (server may be waking up)."),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _total,
                      itemBuilder: (_, i) => _buildPage(kOnboardingQuestions[i]),
                    ),
                  ),
                ],
              ),
              IgnorePointer(
                ignoring: _flashOpacity == 0,
                child: AnimatedOpacity(
                  opacity: _flashOpacity,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: Container(color: Colors.white),
                ),
              ),
              if (_finishing) _buildFinishingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: _index > 0
                ? IconButton(
                    onPressed: _finishing ? null : _back,
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.ink),
                  )
                : null,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    color: AppColors.seed.withValues(alpha: 0.15),
                  ),
                  FractionallySizedBox(
                    widthFactor: (_index + 1) / _total,
                    child: Container(
                      height: 10,
                      decoration:
                          const BoxDecoration(gradient: AppColors.brandGradient),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                '${_index + 1}/$_total',
                style: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingQuestion q) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(q.emoji,
              style: const TextStyle(fontSize: 60), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text(
            _qText(q),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          if (q.isNameInput) _buildNameInput() else ..._buildOptions(q),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
              color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          cursorColor: AppColors.seed,
          decoration: InputDecoration(
            hintText: _isTr ? 'Adın...' : 'Your name...',
            hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.35)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          ),
          onSubmitted: (_) => _onNameNext(),
        ),
        const SizedBox(height: 24),
        _gradientButton(_isTr ? 'İleri' : 'Next', _onNameNext),
      ],
    );
  }

  List<Widget> _buildOptions(OnboardingQuestion q) {
    return q.options.map((o) {
      final isSel = _selected == o.en;
      return Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isSel ? AppColors.brandGradient : null,
            color: isSel ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (isSel ? AppColors.gradientEnd : AppColors.seed)
                    .withValues(alpha: isSel ? 0.35 : 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _finishing ? null : () => _onOptionTap(q, o),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                child: Row(
                  children: [
                    if (o.emoji.isNotEmpty) ...[
                      Text(o.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(
                        _oText(o),
                        style: TextStyle(
                          color: isSel ? Colors.white : AppColors.ink,
                          fontSize: 17,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isSel)
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _gradientButton(String label, VoidCallback onTap) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.4),
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
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.seed),
            ),
            const SizedBox(height: 20),
            Text(
              _isTr ? 'Her şey hazırlanıyor...' : 'Getting everything ready...',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _StringFallback on String {
  String ifEmptyFallback(String fallback) => trim().isEmpty ? fallback : this;
}
