import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/session_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/surfaces.dart';

/// Guests never chose a password — the backend mints an account from the Guest
/// record created when they registered at the event. Email is the whole login.
class GuestLoginScreen extends StatefulWidget {
  const GuestLoginScreen({super.key});

  @override
  State<GuestLoginScreen> createState() => _GuestLoginScreenState();
}

class _GuestLoginScreenState extends State<GuestLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await context.read<SessionController>().signInAsGuest(_email.text);
      // The router redirects to the gallery as soon as the session lands.
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not sign you in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(size: 46),
                const SizedBox(height: 26),
                Text('GUEST ACCESS', style: AppText.eyebrow),
                const SizedBox(height: 8),
                Text('Welcome back', style: AppText.display),
                const SizedBox(height: 10),
                Text(
                  'Use the email address you gave when you registered at the '
                  'event. We will open your personal gallery.',
                  style: AppText.body.copyWith(height: 1.6),
                ),
                const SizedBox(height: 28),
                AppField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'you@example.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  validator: Validate.email,
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  InfoBanner(
                    message: _error!,
                    icon: Icons.error_outline_rounded,
                    tone: ChipTone.danger,
                  ),
                ],
                const SizedBox(height: 22),
                AppButton(
                  label: 'View my gallery',
                  icon: Icons.photo_library_rounded,
                  busy: _busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppTokens.rMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not registered yet?',
                        style: AppText.bodyStrong.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Scan the QR code shared by your event organiser to '
                        'register with a selfie.',
                        style: AppText.caption.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 13),
                      AppButton(
                        label: 'Scan event QR code',
                        icon: Icons.qr_code_scanner_rounded,
                        tone: AppButtonTone.neutral,
                        size: AppButtonSize.compact,
                        expand: false,
                        onPressed: () => context.push(Routes.scan),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
