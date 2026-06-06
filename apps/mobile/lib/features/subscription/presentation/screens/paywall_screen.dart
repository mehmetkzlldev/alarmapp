import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import 'package:alarmy/core/theme/app_colors.dart';
import 'package:alarmy/features/subscription/domain/entities/plan_entity.dart';
import 'package:alarmy/features/subscription/presentation/providers/subscription_provider.dart';

/// External legal links shown at the bottom of the paywall. Required by both
/// stores for any screen that sells a subscription.
class _LegalUrls {
  _LegalUrls._();
  static final Uri terms = Uri.parse('https://alarmy.app/terms');
  static final Uri privacy = Uri.parse('https://alarmy.app/privacy');
}

/// Premium features advertised on the paywall. Mirrors the premium-gated
/// backend capabilities: AI missions, advanced statistics, unlimited alarms.
/// The user-facing title/subtitle strings are resolved (localized) at build
/// time in [_FeatureList]; only the icons are constant here.
const List<IconData> _premiumFeatureIcons = [
  Icons.auto_awesome,
  Icons.insights,
  Icons.alarm_add,
  Icons.workspace_premium,
];

/// The subscription paywall: compares Free vs Premium Monthly vs Premium Yearly,
/// lets the user purchase or restore, and links to the legal terms.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  /// Index of the plan the user has selected (defaults to the yearly/most
  /// popular plan once plans load).
  String? _selectedProductId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final asyncState = ref.watch(subscriptionProvider);

    // Surface transient success/error messages as snackbars, then clear them.
    ref.listen(subscriptionProvider, (previous, next) {
      final value = next.valueOrNull;
      if (value == null) return;
      final messenger = ScaffoldMessenger.of(context);
      if (value.lastError != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(value.lastError!),
            backgroundColor: AppColors.danger,
          ),
        );
        ref.read(subscriptionProvider.notifier).clearTransient();
      } else if (value.lastMessage != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(value.lastMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(subscriptionProvider.notifier).clearTransient();
        // If the user is now premium, pop back to where they came from.
        if (value.isPremium && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paywallGoPremium),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            message: l10n.paywallLoadError,
            onRetry: () => ref.read(subscriptionProvider.notifier).refresh(),
          ),
          data: (sub) {
            // Already premium — show a confirmation instead of the offer.
            if (sub.isPremium) {
              return const _AlreadyPremiumView();
            }

            final plans = sub.plans;
            final purchasablePlans =
                plans.where((p) => !p.isFree).toList(growable: false);
            final freePlan = plans.firstWhere(
              (p) => p.isFree,
              orElse: PlanEntity.free,
            );

            // Default selection: the "most popular" plan, else the first.
            final selectedId = _selectedProductId ??
                (purchasablePlans
                        .firstWhere(
                          (p) => p.isMostPopular,
                          orElse: () => purchasablePlans.isNotEmpty
                              ? purchasablePlans.first
                              : freePlan,
                        )
                        .productId);

            final selectedPlan = purchasablePlans.firstWhere(
              (p) => p.productId == selectedId,
              orElse: () => purchasablePlans.isNotEmpty
                  ? purchasablePlans.first
                  : freePlan,
            );

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      _Header(theme: theme),
                      const SizedBox(height: 24),
                      _FeatureList(theme: theme),
                      const SizedBox(height: 24),
                      Text(
                        l10n.paywallChoosePlan,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      // Free plan (for comparison; not purchasable).
                      _PlanCard(
                        plan: freePlan,
                        selected: false,
                        onTap: null,
                      ),
                      const SizedBox(height: 12),
                      // Purchasable premium plans.
                      for (final plan in purchasablePlans) ...[
                        _PlanCard(
                          plan: plan,
                          selected: plan.productId == selectedId,
                          onTap: () => setState(
                            () => _selectedProductId = plan.productId,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                _Footer(
                  selectedPlan: selectedPlan,
                  isPurchasing: sub.isPurchasing,
                  isRestoring: sub.isRestoring,
                  canBuy: purchasablePlans.isNotEmpty,
                  onBuy: () =>
                      ref.read(subscriptionProvider.notifier).buy(selectedPlan),
                  onRestore: () =>
                      ref.read(subscriptionProvider.notifier).restore(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.sunrise, AppColors.seed],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.workspace_premium,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.paywallHeaderTitle,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.paywallHeaderSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Localized title/subtitle resolved here, paired with the constant icons.
    final features = <({IconData icon, String title, String subtitle})>[
      (
        icon: _premiumFeatureIcons[0],
        title: l10n.paywallFeatureAiMissionsTitle,
        subtitle: l10n.paywallFeatureAiMissionsSubtitle,
      ),
      (
        icon: _premiumFeatureIcons[1],
        title: l10n.paywallFeatureStatsTitle,
        subtitle: l10n.paywallFeatureStatsSubtitle,
      ),
      (
        icon: _premiumFeatureIcons[2],
        title: l10n.paywallFeatureUnlimitedAlarmsTitle,
        subtitle: l10n.paywallFeatureUnlimitedAlarmsSubtitle,
      ),
      (
        icon: _premiumFeatureIcons[3],
        title: l10n.paywallFeatureAllMissionTypesTitle,
        subtitle: l10n.paywallFeatureAllMissionTypesSubtitle,
      ),
    ];
    return Column(
      children: [
        for (final f in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.sunrise.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(f.icon, color: AppColors.sunrise, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A selectable plan card. The free plan is rendered with [onTap] == null.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PlanEntity plan;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor =
        selected ? AppColors.sunrise : scheme.outline.withValues(alpha: 0.3);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Selection indicator (radio-style).
            Icon(
              onTap == null
                  ? Icons.remove_circle_outline
                  : (selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
              color: selected ? AppColors.sunrise : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (plan.isMostPopular) ...[
                        const SizedBox(width: 8),
                        _Badge(text: l10n.paywallBestValue),
                      ],
                    ],
                  ),
                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      plan.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  if (plan.trialDays != null && plan.trialDays! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.paywallFreeTrial(plan.trialDays!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              plan.priceLabel.isEmpty ? '—' : plan.priceLabel,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sunrise,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Sticky bottom bar: buy CTA, restore link, and legal terms.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.selectedPlan,
    required this.isPurchasing,
    required this.isRestoring,
    required this.canBuy,
    required this.onBuy,
    required this.onRestore,
  });

  final PlanEntity selectedPlan;
  final bool isPurchasing;
  final bool isRestoring;
  final bool canBuy;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = isPurchasing || isRestoring;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunrise),
            onPressed: (busy || !canBuy) ? null : onBuy,
            child: isPurchasing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    canBuy
                        ? (selectedPlan.priceLabel.isNotEmpty
                            ? l10n.paywallContinueWithPrice(
                                selectedPlan.priceLabel)
                            : l10n.paywallContinue)
                        : l10n.paywallPlansUnavailable,
                  ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: busy ? null : onRestore,
            child: isRestoring
                ? Text(l10n.paywallRestoring)
                : Text(l10n.paywallRestorePurchases),
          ),
          _LegalLinks(theme: theme),
        ],
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.theme});
  final ThemeData theme;

  Future<void> _open(Uri uri) async {
    // Best-effort: silently ignore if no browser can handle the link.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      decoration: TextDecoration.underline,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            l10n.paywallLegalDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          GestureDetector(
            onTap: () => _open(_LegalUrls.terms),
            child: Text(l10n.paywallTerms, style: style),
          ),
          Text('·',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface)),
          GestureDetector(
            onTap: () => _open(_LegalUrls.privacy),
            child: Text(l10n.paywallPrivacy, style: style),
          ),
        ],
      ),
    );
  }
}

class _AlreadyPremiumView extends StatelessWidget {
  const _AlreadyPremiumView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.paywallAlreadyPremiumTitle,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paywallAlreadyPremiumBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.paywallDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: AppColors.danger, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: Text(l10n.paywallRetry)),
          ],
        ),
      ),
    );
  }
}
