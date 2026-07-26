import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_tools.dart';
import '../../state/session_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/surfaces.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _picker = ImagePicker();

  String? _newImagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.text = context.read<SessionController>().user?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) return;

    // The profile endpoint caps uploads at 2 MB, so compress before sending.
    final prepared = await ImageTools.prepareSelfie(picked.path);
    if (mounted) setState(() => _newImagePath = prepared);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() => _saving = true);
    try {
      await context.read<SessionController>().updateProfile(
            name: _name.text,
            profileImagePath: _newImagePath,
          );
      if (!mounted) return;
      setState(() => _newImagePath = null);
      showSnack(context, 'Profile updated.', tone: SnackTone.success);
    } on ApiException catch (error) {
      if (mounted) showSnack(context, error.message, tone: SnackTone.danger);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not save your profile.',
            tone: SnackTone.danger);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out',
      message:
          'You will need your email and password to sign back in. Events, '
          'photos and guests are unaffected.',
      confirmLabel: 'Sign out',
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !mounted) return;
    await context.read<SessionController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.ink,
                          border: Border.all(color: AppColors.border, width: 3),
                        ),
                        child: _newImagePath != null
                            ? Image.file(File(_newImagePath!), fit: BoxFit.cover)
                            : user?.profileImageUrl != null
                                ? Image.network(
                                    user!.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _initial(user),
                                  )
                                : _initial(user),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              size: 15,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(user?.email ?? '', style: AppText.caption),
                  const SizedBox(height: 8),
                  const StatusChip(
                    label: 'Organiser',
                    tone: ChipTone.ink,
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            AppField(
              label: 'Display name',
              controller: _name,
              hint: 'Your studio or full name',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              validator: (value) => Validate.required(value, field: 'Name'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Save changes',
              icon: Icons.check_rounded,
              busy: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 30),
            const SectionHeading(eyebrow: 'About', title: 'This workspace'),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Email',
                    value: user?.email ?? '—',
                  ),
                  const Divider(height: 22),
                  _InfoRow(
                    label: 'Data retention',
                    value: '${AppConfig.retentionDays} days after each event',
                  ),
                  const Divider(height: 22),
                  const _InfoRow(
                    label: 'Support',
                    value: AppConfig.supportEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: 'Sign out',
              icon: Icons.logout_rounded,
              tone: AppButtonTone.neutral,
              onPressed: _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _initial(dynamic user) {
    final name = user?.name as String? ?? 'A';
    return Center(
      child: Text(
        name.isEmpty ? 'A' : name[0].toUpperCase(),
        style: AppText.display.copyWith(color: Colors.white, fontSize: 34),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.caption)),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppText.bodyStrong.copyWith(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
