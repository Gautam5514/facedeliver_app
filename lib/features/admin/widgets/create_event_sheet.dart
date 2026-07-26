import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/event_code.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_field.dart';
import '../../../widgets/surfaces.dart';

/// Creates an event and returns it to the caller.
///
/// The code is the public key that ends up inside every guest QR link, so it is
/// derived from the name automatically and can still be edited before saving —
/// after creation it is effectively permanent.
class CreateEventSheet extends StatefulWidget {
  const CreateEventSheet({super.key});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();

  /// Stops the auto-slug from overwriting a code the organiser typed by hand.
  bool _codeEditedManually = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(_syncCode);
    // Once the code diverges from what the name would generate, it belongs to
    // the organiser and the auto-slug stops touching it. Clearing the field
    // hands control back.
    _code.addListener(() {
      if (_code.text != suggestEventCode(_name.text)) {
        _codeEditedManually = _code.text.isNotEmpty;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _syncCode() {
    if (_codeEditedManually) return;
    final suggestion = suggestEventCode(_name.text);
    if (_code.text != suggestion) _code.text = suggestion;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final event = await context.read<AdminRepository>().createEvent(
            name: _name.text,
            code: _code.text,
          );
      if (mounted) Navigator.of(context).pop(event);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not create the event.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEW EVENT', style: AppText.eyebrow),
              const SizedBox(height: 6),
              Text(
                'Create an event',
                style: AppText.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Guests scan this event’s QR code to register their face and '
                'receive their photos automatically.',
                style: AppText.caption.copyWith(height: 1.55),
              ),
              const SizedBox(height: 22),
              AppField(
                label: 'Event name',
                controller: _name,
                hint: 'Sharma Wedding 2026',
                icon: Icons.celebration_outlined,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validate.required(value, field: 'Event name'),
              ),
              const SizedBox(height: 16),
              AppField(
                label: 'Event code',
                controller: _code,
                hint: 'sharma-wedding-2026',
                icon: Icons.qr_code_2_rounded,
                textInputAction: TextInputAction.done,
                validator: Validate.eventCode,
                onSubmitted: (_) => _submit(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                  TextInputFormatter.withFunction(
                    (_, next) => next.copyWith(text: next.text.toLowerCase()),
                  ),
                ],
                helper:
                    'Appears in the guest link. Choose carefully — it cannot be '
                    'changed later.',
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
                label: 'Create event',
                icon: Icons.add_rounded,
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
