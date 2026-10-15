import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import 'admin_access_controller.dart';

Future<bool> requireAdmin(BuildContext context) async {
  final access = context.read<AdminAccessController>();
  if (access.isAuthenticated) return true;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _AdminGateDialog(),
      ) ??
      false;
}

class _AdminGateDialog extends StatefulWidget {
  const _AdminGateDialog();

  @override
  State<_AdminGateDialog> createState() => _AdminGateDialogState();
}

class _AdminGateDialogState extends State<_AdminGateDialog> {
  final _passcode = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _passcode.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = context.read<AdminAccessController>();
    final isSetup = !access.isConfigured;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(isSetup ? 'Set up Admin Gate' : 'Admin Gate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSetup
                ? 'Create an 8-character minimum passcode for this device.'
                : 'Enter the admin passcode to continue.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passcode,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Passcode'),
            onSubmitted: (_) => _submit(isSetup),
          ),
          if (isSetup) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _confirmation,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm passcode'),
              onSubmitted: (_) => _submit(true),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFFF7185))),
          ],
          const SizedBox(height: 12),
          const Text(
            'This gate is stored on this device. It is not server-side identity verification.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : () => _submit(isSetup),
          child: Text(_busy
              ? 'Checking...'
              : isSetup
                  ? 'Create gate'
                  : 'Unlock'),
        ),
      ],
    );
  }

  Future<void> _submit(bool isSetup) async {
    final value = _passcode.text;
    final access = context.read<AdminAccessController>();
    if (isSetup && value != _confirmation.text) {
      setState(() => _error = 'The passcodes do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (isSetup) {
        await access.configure(value);
      } else if (!access.authenticate(value)) {
        setState(() => _error = 'That passcode is not correct.');
        return;
      }
      if (mounted) Navigator.pop(context, true);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message.toString());
    } catch (error) {
      setState(() => _error = 'Could not save the local admin setting: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
