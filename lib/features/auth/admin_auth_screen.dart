import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/session_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/surfaces.dart';

enum _AuthMode { login, signup }

/// Organiser sign-in and sign-up in one screen.
///
/// The role is decided entirely by the invite code — the API never accepts a
/// role from the client — so the code field is what separates an organiser
/// account from an ordinary one.
class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _inviteCode = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  bool get _isSignup => _mode == _AuthMode.signup;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _error = null;
    });

    final session = context.read<SessionController>();

    try {
      if (_isSignup) {
        await session.signUpAsAdmin(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          inviteCode: _inviteCode.text,
        );
      } else {
        await session.signInAsAdmin(
          email: _email.text,
          password: _password.text,
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
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
                Text('ORGANISER PORTAL', style: AppText.eyebrow),
                const SizedBox(height: 8),
                Text(
                  _isSignup ? 'Create account' : 'Sign in',
                  style: AppText.display,
                ),
                const SizedBox(height: 10),
                Text(
                  _isSignup
                      ? 'Organiser accounts are invite-only. Enter the code '
                          'issued to your studio to continue.'
                      : 'Manage events, upload galleries and track delivery.',
                  style: AppText.body.copyWith(height: 1.6),
                ),
                const SizedBox(height: 22),
                _ModeToggle(mode: _mode, onChanged: _switchMode),
                const SizedBox(height: 22),
                if (_isSignup) ...[
                  AppField(
                    label: 'Full name',
                    controller: _name,
                    hint: 'Aarav Sharma',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        Validate.required(value, field: 'Name'),
                  ),
                  const SizedBox(height: 16),
                ],
                AppField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'studio@example.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: Validate.email,
                ),
                const SizedBox(height: 16),
                AppField(
                  label: 'Password',
                  controller: _password,
                  hint: _isSignup ? 'At least 8 characters' : '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  autofillHints: [
                    _isSignup ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  textInputAction:
                      _isSignup ? TextInputAction.next : TextInputAction.done,
                  validator: _isSignup
                      ? Validate.password
                      : (value) => Validate.required(value, field: 'Password'),
                  onSubmitted: (_) => _isSignup ? null : _submit(),
                  trailing: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Text(
                      _obscure ? 'SHOW' : 'HIDE',
                      style: AppText.eyebrow.copyWith(color: AppColors.muted),
                    ),
                  ),
                ),
                if (_isSignup) ...[
                  const SizedBox(height: 16),
                  AppField(
                    label: 'Invite code',
                    controller: _inviteCode,
                    hint: 'Provided by FaceDeliver',
                    icon: Icons.vpn_key_outlined,
                    textInputAction: TextInputAction.done,
                    validator: (value) =>
                        Validate.required(value, field: 'Invite code'),
                    onSubmitted: (_) => _submit(),
                    helper:
                        'Without a valid code the account is created as a guest.',
                  ),
                ],
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
                  label: _isSignup ? 'Create account' : 'Sign in',
                  icon: _isSignup
                      ? Icons.person_add_alt_1_rounded
                      : Icons.login_rounded,
                  busy: _busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Protected by rate limiting — 10 attempts every 15 minutes.',
                    style: AppText.micro,
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

/// Segmented control for login / signup.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
      ),
      child: Row(
        children: [
          _segment('Sign in', _AuthMode.login),
          _segment('Create account', _AuthMode.signup),
        ],
      ),
    );
  }

  Widget _segment(String label, _AuthMode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppTokens.fast,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? AppColors.cardShadow : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppText.bodyStrong.copyWith(
                fontSize: 13,
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
