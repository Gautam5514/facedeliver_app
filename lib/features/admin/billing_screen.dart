import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/billing_models.dart';
import '../../data/repositories/billing_repository.dart';
import '../../state/session_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/states.dart';
import '../../widgets/surfaces.dart';
import 'widgets/quota_card.dart';

/// Plans, current subscription, and Razorpay checkout.
///
/// Billing is admin-scoped, not event-scoped: one subscription covers every
/// event the organiser owns, and it gates uploads across all of them.
class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late final Razorpay _razorpay;

  List<BillingPlan> _plans = const [];
  BillingStatus _billing = BillingStatus.none;
  bool _loading = true;
  bool _checkingOut = false;
  String? _error;

  /// Remembered between opening checkout and the success callback so the
  /// confirmation can name the plan.
  String? _pendingPlanName;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final repository = context.read<BillingRepository>();
      final results = await Future.wait([
        repository.plans(),
        repository.status(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<BillingPlan>;
        _billing = results[1] as BillingStatus;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load billing details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startCheckout(BillingPlan plan) async {
    setState(() {
      _checkingOut = true;
      _pendingPlanName = plan.name;
    });

    // Read the user before the await so the prefill does not depend on the
    // context still being mounted when checkout opens.
    final user = context.read<SessionController>().user;

    try {
      final order = await context.read<BillingRepository>().createOrder(plan.code);

      if (order.razorpayKeyId.isEmpty) {
        throw ApiException('Payments are not configured. Contact support.');
      }

      _razorpay.open({
        'key': order.razorpayKeyId,
        'amount': order.amount,
        'currency': order.currency,
        'order_id': order.orderId,
        'name': AppConfig.appName,
        'description': '${plan.name} · ${Format.count(plan.uploadLimit)} uploads',
        'prefill': {
          if (user != null) 'email': user.email,
          if (user != null) 'name': user.name,
        },
        'theme': {'color': '#09090B'},
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _checkingOut = false);
        showSnack(context, error.message, tone: SnackTone.danger);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checkingOut = false);
        showSnack(
          context,
          'Could not start checkout. Please try again.',
          tone: SnackTone.danger,
        );
      }
    }
  }

  /// Checkout succeeding is not activation — the server must verify the
  /// signature before the plan and quota actually change.
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;

    if (orderId == null || paymentId == null || signature == null) {
      if (mounted) {
        setState(() => _checkingOut = false);
        showSnack(
          context,
          'Payment captured but incomplete. If the plan does not activate '
          'shortly, contact support.',
          tone: SnackTone.danger,
        );
      }
      return;
    }

    try {
      await context.read<BillingRepository>().verifyPayment(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          );
      if (!mounted) return;
      showSnack(
        context,
        '${_pendingPlanName ?? 'Your plan'} is active. Upload away.',
        tone: SnackTone.success,
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) showSnack(context, error.message, tone: SnackTone.danger);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _checkingOut = false);
    showSnack(
      context,
      response.message?.trim().isNotEmpty == true
          ? response.message!.trim()
          : 'Payment was not completed.',
      tone: SnackTone.danger,
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _checkingOut = false);
    showSnack(context, 'Continuing in ${response.walletName ?? 'your wallet'}…');
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = _billing.subscription?.planCode;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('BILLING', style: AppText.eyebrow),
            const SizedBox(height: 3),
            Text('Plan & usage', style: AppText.title.copyWith(fontSize: 19)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.ink,
        backgroundColor: AppColors.surface,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SkeletonList(count: 4, height: 130),
              )
            : _error != null
                ? ListView(
                    children: [
                      StateMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Billing unavailable',
                        message: _error!,
                        tone: ChipTone.danger,
                        actionLabel: 'Try again',
                        onAction: _load,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                    children: [
                      QuotaCard(billing: _billing),
                      const SizedBox(height: 24),
                      SectionHeading(
                        eyebrow: 'Plans',
                        title: _billing.hasPlan
                            ? 'Change your plan'
                            : 'Choose a plan',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'One subscription covers every event you own. Upload '
                        'capacity resets at the start of each billing period.',
                        style: AppText.caption.copyWith(height: 1.55),
                      ),
                      const SizedBox(height: 16),
                      for (final plan in _plans)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            plan: plan,
                            isCurrent: plan.code == currentCode,
                            busy: _checkingOut,
                            onSelect: () => _startCheckout(plan),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const InfoBanner(
                        message:
                            'Payments are processed by Razorpay. Your card '
                            'details never touch FaceDeliver’s servers.',
                        icon: Icons.lock_outline_rounded,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.busy,
    required this.onSelect,
  });

  final BillingPlan plan;
  final bool isCurrent;
  final bool busy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: isCurrent ? AppColors.ink : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: AppText.title.copyWith(fontSize: 18),
                ),
              ),
              if (isCurrent)
                const StatusChip(
                  label: 'Current plan',
                  tone: ChipTone.ink,
                  icon: Icons.check_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Format.money(plan.amount, plan.currency),
                style: AppText.metric.copyWith(fontSize: 26),
              ),
              const SizedBox(width: 7),
              Text(plan.cycleLabel, style: AppText.caption),
            ],
          ),
          const SizedBox(height: 14),
          _PlanFeature(
            icon: Icons.cloud_upload_outlined,
            label: '${Format.count(plan.uploadLimit)} photo uploads',
          ),
          const _PlanFeature(
            icon: Icons.auto_awesome_outlined,
            label: 'Unlimited events and guests',
          ),
          const _PlanFeature(
            icon: Icons.mark_email_read_outlined,
            label: 'Automatic guest emails when photos are ready',
          ),
          const SizedBox(height: 16),
          AppButton(
            label: isCurrent ? 'Renew this plan' : 'Choose ${plan.name}',
            icon: Icons.credit_card_rounded,
            tone: isCurrent ? AppButtonTone.neutral : AppButtonTone.primary,
            busy: busy,
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.faint),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: AppText.caption)),
        ],
      ),
    );
  }
}
