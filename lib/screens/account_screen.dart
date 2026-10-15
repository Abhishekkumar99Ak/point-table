import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pointcalc_models.dart';
import '../services/account_settings_store.dart';
import '../services/admin_access_controller.dart';
import '../services/admin_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AdminAccessController>();
    final tournamentCount = context.watch<TournamentStore>().tournaments.length;
    return AppScaffold(
      appBar: AppBar(
          title: const Text('Account'), backgroundColor: Colors.transparent),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.surfaceRaised,
                child: Icon(Icons.person_outline_rounded,
                    color: AppColors.accentLight, size: 29),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Point Table',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('$tournamentCount tournaments on this device',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ]),
              ),
              _StatusBadge(
                  label: access.isAuthenticated ? 'ADMIN' : 'LOCKED',
                  active: access.isAuthenticated),
            ]),
          ),
          const SizedBox(height: 22),
          const _Heading('ACCESS'),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 13),
            secondary: const Icon(Icons.admin_panel_settings_outlined,
                color: AppColors.accentLight),
            title: const Text('Admin Mode',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(
                access.isConfigured
                    ? 'Local privileged tools'
                    : 'Set a passcode on first unlock',
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            value: access.isAuthenticated,
            activeTrackColor: AppColors.accentLight,
            onChanged: (enabled) async {
              if (!enabled) {
                access.lock();
              } else {
                await requireAdmin(context);
              }
            },
          ),
          _SettingTile(
            icon: Icons.key_outlined,
            title: access.isConfigured
                ? 'Change admin passcode'
                : 'Set up Admin Gate',
            subtitle: 'Salted credential stored on this device',
            onTap: () => _changePasscode(context, access),
          ),
          if (access.isAuthenticated)
            _SettingTile(
              icon: Icons.lock_outline_rounded,
              title: 'Lock admin session',
              subtitle: 'Require the passcode again for gated tools',
              onTap: () {
                access.lock();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin session locked.')));
              },
            ),
          const SizedBox(height: 22),
          const _Heading('CLOUD & DEVICES'),
          const SizedBox(height: 8),
          _SettingTile(
            icon: Icons.cloud_off_outlined,
            title: 'Cloud theme sync',
            subtitle: access.cloudConnected
                ? 'Connected'
                : 'Not configured: Firebase credentials required',
            trailing:
                const Icon(Icons.info_outline_rounded, color: AppColors.muted),
            onTap: () => _showCloudInfo(context),
          ),
          _SettingTile(
            icon: Icons.devices_other_outlined,
            title: 'Manage devices',
            subtitle: 'Remote approval requires an online admin service',
            trailing: Icon(Icons.cloud_queue_outlined, color: AppColors.muted),
            onTap: () => _showDeviceInfo(context),
          ),
          _SettingTile(
            icon: Icons.card_membership_outlined,
            title: 'Subscription and access',
            subtitle: 'No subscription or remote tokens are configured',
            trailing: Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            onTap: () => _showSubscriptionInfo(context),
          ),
          const SizedBox(height: 22),
          const _Heading('APP'),
          const SizedBox(height: 8),
          _SettingTile(
              icon: Icons.delete_outline_rounded,
              title: 'Trash',
              subtitle: 'Restore or permanently delete removed tournaments',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _TrashScreen()))),
          _SettingTile(
              icon: Icons.mail_outline_rounded,
              title: 'Support',
              subtitle: 'Email and Instagram contact settings',
              onTap: () => _showSupportOptions(context)),
          _SettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              subtitle: 'Open or configure your policy URL',
              onTap: () => _openPrivacyPolicy(context)),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 17, 14, 4),
            child: Text('Point Table · All Games Esports Manager · 1.0.0+1',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _changePasscode(
      BuildContext context, AdminAccessController access) async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();
    final isSetup = !access.isConfigured;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: Text(
                    isSetup ? 'Set up Admin Gate' : 'Change admin passcode'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (!isSetup) ...[
                    TextField(
                        controller: currentController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Current passcode')),
                    const SizedBox(height: 9),
                  ],
                  TextField(
                      controller: nextController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'New passcode (8+ characters)')),
                  const SizedBox(height: 9),
                  TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Confirm passcode')),
                  if (error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Text(error!,
                            style: const TextStyle(color: Color(0xFFFF7185)))),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () async {
                        if (nextController.text != confirmController.text) {
                          setState(() => error = 'The passcodes do not match.');
                          return;
                        }
                        try {
                          if (isSetup) {
                            await access.configure(nextController.text);
                          } else {
                            await access.changePasscode(
                                currentController.text, nextController.text);
                          }
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                        } catch (failure) {
                          setState(() => error = failure.toString());
                        }
                      },
                      child: const Text('Save')),
                ],
              )),
    );
    currentController.dispose();
    nextController.dispose();
    confirmController.dispose();
  }

  void _showCloudInfo(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Cloud service not configured'),
          content: const Text(
              'Online access, device approvals, subscriptions and theme sync need a Firebase project, security rules and an admin-verification service. Tournament data currently stays on this device unless exported.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        ),
      );

  void _showDeviceInfo(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('This device'),
          content: const Text(
              'This installation stores tournaments and the local Admin Gate on this device. Remote device approval is unavailable until an authenticated cloud service is configured.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        ),
      );

  void _showSubscriptionInfo(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Subscription and access'),
          content: const Text(
              'This build has no billing provider or token-verification endpoint. No subscription status is implied. Configure a verified server-side entitlement service before offering paid access.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        ),
      );

  Future<void> _showSupportOptions(BuildContext context) async {
    final settings = await AccountSettingsStore.load();
    if (!context.mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(settings['supportEmail']?.isNotEmpty == true
                ? settings['supportEmail']!
                : 'Set support email first'),
            onTap: settings['supportEmail']?.isNotEmpty == true
                ? () => Navigator.pop(context, 'email')
                : null),
        ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(settings['instagram']?.isNotEmpty == true
                ? '@${settings['instagram']!.replaceFirst('@', '')}'
                : 'Set Instagram first'),
            onTap: settings['instagram']?.isNotEmpty == true
                ? () => Navigator.pop(context, 'instagram')
                : null),
        ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Configure support links'),
            onTap: () => Navigator.pop(context, 'configure')),
      ])),
    );
    if (!context.mounted || action == null) return;
    if (action == 'configure') {
      await _editAccountLinks(context);
    } else if (action == 'email') {
      await launchUrl(Uri(scheme: 'mailto', path: settings['supportEmail']));
    } else {
      final handle = settings['instagram']!.replaceFirst('@', '');
      await launchUrl(Uri.https('instagram.com', '/$handle'));
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final settings = await AccountSettingsStore.load();
    if (!context.mounted) return;
    final url = settings['privacyPolicyUrl']?.trim() ?? '';
    if (url.isEmpty) {
      await _editAccountLinks(context);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open that privacy-policy URL.')));
      }
    }
  }

  Future<void> _editAccountLinks(BuildContext context) async {
    final settings = await AccountSettingsStore.load();
    if (!context.mounted) return;
    final email = TextEditingController(text: settings['supportEmail'] ?? '');
    final instagram = TextEditingController(text: settings['instagram'] ?? '');
    final privacy =
        TextEditingController(text: settings['privacyPolicyUrl'] ?? '');
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Support and privacy links'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Support email')),
                const SizedBox(height: 8),
                TextField(
                    controller: instagram,
                    decoration:
                        const InputDecoration(labelText: 'Instagram username')),
                const SizedBox(height: 8),
                TextField(
                    controller: privacy,
                    keyboardType: TextInputType.url,
                    decoration:
                        const InputDecoration(labelText: 'Privacy policy URL')),
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'))
              ],
            ));
    if (accepted == true) {
      await AccountSettingsStore.save({
        'supportEmail': email.text.trim(),
        'instagram': instagram.text.trim(),
        'privacyPolicyUrl': privacy.text.trim()
      });
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account links saved on this device.')));
    }
    email.dispose();
    instagram.dispose();
    privacy.dispose();
  }
}

class _TrashScreen extends StatelessWidget {
  const _TrashScreen();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TournamentStore>();
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        backgroundColor: Colors.transparent,
        actions: [
          if (store.trash.isNotEmpty)
            IconButton(
                tooltip: 'Empty trash',
                onPressed: () => _emptyTrash(context, store),
                icon: const Icon(Icons.delete_forever_outlined)),
        ],
      ),
      child: store.trash.isEmpty
          ? const Center(
              child: Text('Trash is empty.',
                  style: TextStyle(color: AppColors.muted)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: store.trash
                  .map((tournament) => ListTile(
                        leading: const Icon(Icons.emoji_events_outlined,
                            color: AppColors.accentLight),
                        title: Text(tournament.name),
                        subtitle: Text(
                            '${tournament.teams.length} teams · ${tournament.standings.length} results'),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              tooltip: 'Restore tournament',
                              onPressed: () => store.restore(tournament.id),
                              icon: const Icon(Icons.restore_rounded)),
                          IconButton(
                              tooltip: 'Permanently delete',
                              onPressed: () => _permanentlyDelete(
                                  context, store, tournament),
                              icon: const Icon(Icons.delete_forever_outlined)),
                        ]),
                      ))
                  .toList()),
    );
  }

  Future<void> _emptyTrash(BuildContext context, TournamentStore store) async {
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Empty trash?'),
              content: const Text(
                  'All trashed tournaments will be permanently removed from this device.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete all'))
              ],
            ));
    if (accepted == true) store.emptyTrash();
  }

  Future<void> _permanentlyDelete(BuildContext context, TournamentStore store,
      Tournament tournament) async {
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Permanently delete?'),
              content:
                  Text('"${tournament.name}" cannot be restored after this.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete forever'))
              ],
            ));
    if (accepted == true) store.permanentlyDelete(tournament.id);
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1));
}

class _SettingTile extends StatelessWidget {
  const _SettingTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.trailing,
      this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
        leading: Icon(icon, color: AppColors.accentLight),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        trailing: trailing ??
            (onTap == null
                ? null
                : const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted)),
        onTap: onTap,
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: (active ? AppColors.mint : AppColors.accent)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(
                color: active ? AppColors.mint : AppColors.accentLight,
                fontSize: 9,
                fontWeight: FontWeight.w800)),
      );
}
