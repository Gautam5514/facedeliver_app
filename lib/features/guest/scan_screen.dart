import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/event_code.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/feedback.dart';

/// Live QR scanner. The organiser's QR encodes a full registration URL, so the
/// raw value is parsed rather than used directly.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Guards against the detector firing again while we are navigating away.
  bool _handled = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final code = parseEventCode(barcode.rawValue);
      if (code != null) {
        _handled = true;
        _controller.stop();
        context.pushReplacement('${Routes.register}?eventId=$code');
        return;
      }
    }
  }

  Future<void> _enterCodeManually() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ManualCodeSheet(),
    );

    if (code == null || !mounted) return;
    _handled = true;
    context.pushReplacement('${Routes.register}?eventId=$code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(
              error: error,
              onManualEntry: _enterCodeManually,
            ),
          ),

          // Dim everything outside the reticle so the eye goes straight to it.
          const _ScannerOverlay(),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back_rounded,
                        onDark: true,
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      AppIconButton(
                        icon: _torchOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        onDark: true,
                        tooltip: 'Torch',
                        onPressed: () async {
                          await _controller.toggleTorch();
                          if (mounted) setState(() => _torchOn = !_torchOn);
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(
                    children: [
                      Text(
                        'SCAN EVENT QR',
                        style: AppText.eyebrow.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Point at the organiser’s QR code',
                        textAlign: TextAlign.center,
                        style: AppText.title
                            .copyWith(fontSize: 19, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'It is usually printed on the entrance signage or '
                        'shared in your event group.',
                        textAlign: TextAlign.center,
                        style: AppText.caption
                            .copyWith(color: AppColors.nightMuted, height: 1.55),
                      ),
                      const SizedBox(height: 22),
                      AppButton(
                        label: 'Enter code manually',
                        icon: Icons.keyboard_alt_outlined,
                        tone: AppButtonTone.neutral,
                        onPressed: _enterCodeManually,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cut-out mask with corner brackets around the scan target.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth * 0.68;
        final top = (constraints.maxHeight - side) / 2 - 40;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.62),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - side) / 2,
                    top: top,
                    child: Container(
                      width: side,
                      height: side,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(AppTokens.rXl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: (constraints.maxWidth - side) / 2,
              top: top,
              child: Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.rXl),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onManualEntry});

  final MobileScannerException error;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    final deniedPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: AppColors.night,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                deniedPermission
                    ? Icons.no_photography_rounded
                    : Icons.videocam_off_rounded,
                size: 34,
                color: AppColors.nightMuted,
              ),
              const SizedBox(height: 18),
              Text(
                deniedPermission
                    ? 'Camera access is off'
                    : 'Camera unavailable',
                style: AppText.title.copyWith(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                deniedPermission
                    ? 'Allow camera access in Settings to scan the event QR '
                        'code, or type the code instead.'
                    : 'We could not start the camera on this device. You can '
                        'still type the event code.',
                textAlign: TextAlign.center,
                style: AppText.caption
                    .copyWith(color: AppColors.nightMuted, height: 1.55),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Enter code manually',
                icon: Icons.keyboard_alt_outlined,
                tone: AppButtonTone.neutral,
                expand: false,
                onPressed: onManualEntry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback for damaged QR codes, bad lighting, or a denied camera.
class _ManualCodeSheet extends StatefulWidget {
  const _ManualCodeSheet();

  @override
  State<_ManualCodeSheet> createState() => _ManualCodeSheetState();
}

class _ManualCodeSheetState extends State<_ManualCodeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = parseEventCode(_controller.text);
    if (code == null) {
      showSnack(
        context,
        'That does not look like a valid event code.',
        tone: SnackTone.danger,
      );
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EVENT CODE', style: AppText.eyebrow),
          const SizedBox(height: 6),
          Text('Enter it manually', style: AppText.title.copyWith(fontSize: 19)),
          const SizedBox(height: 8),
          Text(
            'The code appears under the QR on your event signage — you can '
            'also paste the whole registration link.',
            style: AppText.caption.copyWith(height: 1.55),
          ),
          const SizedBox(height: 20),
          AppField(
            label: 'Event code or link',
            controller: _controller,
            hint: 'sharma-wedding-2026',
            icon: Icons.confirmation_number_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
