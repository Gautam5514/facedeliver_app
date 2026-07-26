import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_tools.dart';
import '../../data/repositories/guest_repository.dart';
import '../../state/session_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/states.dart';
import '../../widgets/surfaces.dart';

/// Guest registration: name, email, one selfie, explicit consent.
///
/// This is the only screen that writes biometric data, so consent is a hard
/// gate — the API rejects the request outright without it, and the UI says
/// exactly what is collected before asking.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.eventCode});

  final String eventCode;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _picker = ImagePicker();

  String? _selfiePath;
  bool _consent = false;
  bool _busy = false;
  bool _preparingSelfie = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _captureSelfie(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 92,
      );
      if (picked == null) return;

      setState(() => _preparingSelfie = true);
      final prepared = await ImageTools.prepareSelfie(picked.path);

      // Drop the previous attempt so retakes do not pile up in temp storage.
      final previous = _selfiePath;
      if (previous != null && previous != prepared) {
        ImageTools.discard([previous]);
      }

      if (!mounted) return;
      setState(() {
        _selfiePath = prepared;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        showSnack(
          context,
          'Could not open the camera. Check app permissions.',
          tone: SnackTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _preparingSelfie = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selfiePath == null) {
      setState(() => _error = 'A selfie is required so we can find your photos.');
      return;
    }
    if (!_consent) {
      setState(() =>
          _error = 'Please accept the privacy notice before we process your face data.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final message = await context.read<GuestRepository>().register(
            name: _name.text,
            email: _email.text,
            eventCode: widget.eventCode,
            selfiePath: _selfiePath!,
          );
      if (mounted) setState(() => _successMessage = message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Registration failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Straight from success into the gallery — the guest already proved this
  /// email is theirs by registering with it.
  ///
  /// Registration stays reachable while signed in (a guest may register for a
  /// second event), so the router does not bounce this route and the navigation
  /// has to be explicit.
  Future<void> _openGallery() async {
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().signInAsGuest(_email.text);
      if (mounted) context.go(Routes.gallery);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, error.message, tone: SnackTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventCode.trim().isEmpty) return _missingEventCode();
    if (_successMessage != null) return _success();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EventMonogram(label: widget.eventCode, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EVENT', style: AppText.eyebrow),
                          const SizedBox(height: 3),
                          Text(
                            widget.eventCode,
                            style: AppText.bodyStrong,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Get your photos', style: AppText.display.copyWith(fontSize: 27)),
                const SizedBox(height: 9),
                Text(
                  'One selfie teaches us your face. Every photo you appear in '
                  'is delivered to you automatically — no searching.',
                  style: AppText.body.copyWith(height: 1.6),
                ),
                const SizedBox(height: 24),
                _SelfiePanel(
                  path: _selfiePath,
                  busy: _preparingSelfie,
                  onCamera: () => _captureSelfie(ImageSource.camera),
                  onGallery: () => _captureSelfie(ImageSource.gallery),
                ),
                const SizedBox(height: 22),
                AppField(
                  label: 'Your name',
                  controller: _name,
                  hint: 'Aarav Sharma',
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validate.required(value, field: 'Name'),
                ),
                const SizedBox(height: 16),
                AppField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'you@example.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  validator: Validate.email,
                  helper: 'We email you the moment your photos are ready.',
                ),
                const SizedBox(height: 20),
                _ConsentRow(
                  value: _consent,
                  onChanged: (value) => setState(() {
                    _consent = value;
                    if (value) _error = null;
                  }),
                  onReadNotice: _showPrivacyNotice,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  InfoBanner(
                    message: _error!,
                    icon: Icons.error_outline_rounded,
                    tone: ChipTone.danger,
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: 'Register with this selfie',
                  icon: Icons.auto_awesome_rounded,
                  busy: _busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Face data is permanently deleted '
                    '${AppConfig.retentionDays} days after the event.',
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

  Widget _missingEventCode() {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: StateMessage(
        icon: Icons.qr_code_2_rounded,
        title: 'No event code',
        message:
            'Scan the QR code shared by your organiser so we know which event '
            'to register you for.',
        actionLabel: 'Open scanner',
        onAction: () => context.pushReplacement(Routes.scan),
      ),
    );
  }

  Widget _success() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 30,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 22),
              Text('YOU ARE REGISTERED', style: AppText.eyebrow),
              const SizedBox(height: 8),
              Text("You're all set", style: AppText.display),
              const SizedBox(height: 12),
              Text(_successMessage!, style: AppText.body.copyWith(height: 1.6)),
              const SizedBox(height: 20),
              const InfoBanner(
                title: 'What happens next',
                message:
                    'Matching runs automatically as the organiser uploads. '
                    'You will get an email the moment your photos are ready — '
                    'and they will already be waiting in your gallery.',
                icon: Icons.bolt_rounded,
              ),
              const Spacer(),
              AppButton(
                label: 'Open my gallery',
                icon: Icons.photo_library_rounded,
                busy: _busy,
                onPressed: _openGallery,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Register another guest',
                tone: AppButtonTone.ghost,
                onPressed: () => context.pushReplacement(Routes.scan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyNotice() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRIVACY NOTICE', style: AppText.eyebrow),
                const SizedBox(height: 6),
                Text(
                  'What we collect and why',
                  style: AppText.title.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 18),
                for (final item in const [
                  (
                    'What we collect',
                    'A photo of your face, plus a mathematical face descriptor '
                        'used only for photo matching.'
                  ),
                  (
                    'Why',
                    'To find and deliver your event photos. Nothing else, ever.'
                  ),
                  (
                    'Where it is stored',
                    'Your selfie is stored on Cloudinary; the face descriptor '
                        'stays in our database.'
                  ),
                  (
                    'Retention',
                    'All face data is permanently deleted '
                        '${AppConfig.retentionDays} days after the event.'
                  ),
                  (
                    'Your rights',
                    'Delete everything instantly from your gallery at any time, '
                        'or email ${AppConfig.supportEmail}.'
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: AppText.bodyStrong.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          style: AppText.caption.copyWith(height: 1.55),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'I understand and accept',
                  icon: Icons.verified_user_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    setState(() {
                      _consent = true;
                      _error = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selfie capture surface — dark so the preview reads like a viewfinder.
class _SelfiePanel extends StatelessWidget {
  const _SelfiePanel({
    required this.path,
    required this.busy,
    required this.onCamera,
    required this.onGallery,
  });

  final String? path;
  final bool busy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.night,
              borderRadius: BorderRadius.circular(AppTokens.rXl),
              border: Border.all(color: AppColors.border),
            ),
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  )
                : path == null
                    ? _placeholder()
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(path!), fit: BoxFit.cover),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rPill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Captured',
                                    style: AppText.micro.copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: path == null ? 'Take selfie' : 'Retake',
                icon: Icons.camera_alt_rounded,
                tone: path == null
                    ? AppButtonTone.primary
                    : AppButtonTone.neutral,
                size: AppButtonSize.compact,
                onPressed: onCamera,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Choose photo',
                icon: Icons.photo_outlined,
                tone: AppButtonTone.neutral,
                size: AppButtonSize.compact,
                onPressed: onGallery,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.face_retouching_natural_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          Text(
            'Take a clear selfie',
            style: AppText.bodyStrong.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Text(
              'Good light, face straight on, no sunglasses or masks.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: AppColors.nightMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.onReadNotice,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onReadNotice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(
          color: value ? AppColors.successBorder : AppColors.warningBorder,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: AppTokens.fast,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: value ? AppColors.success : AppColors.warning,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text(
                'I consent to my face data being processed to find my photos.',
                style: AppText.caption.copyWith(
                  color: value ? AppColors.success : AppColors.warning,
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReadNotice,
            child: Text(
              'READ',
              style: AppText.eyebrow.copyWith(
                color: value ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
