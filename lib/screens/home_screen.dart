import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pointcalc_models.dart';
import '../screens/account_screen.dart';
import '../services/admin_access_controller.dart';
import '../services/admin_gate.dart';
import '../services/spreadsheet_tournament_importer.dart';
import '../services/tournament_codec.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import 'create_tournament_screen.dart';
import 'poster_editor_screen.dart';
import 'scoreboard_screen.dart';
import 'team_card_builder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tournaments = context.watch<TournamentStore>().tournaments;
    final isAdmin = context.watch<AdminAccessController>().isAuthenticated;
    return AppScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 108),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ALL GAMES ESPORTS MANAGER',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.accentLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                              const SizedBox(height: 5),
                                const FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text('Point Table',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1.05)),
                                ),
                              const SizedBox(height: 7),
                              Row(children: [
                                Icon(
                                    isAdmin
                                        ? Icons.verified_user_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 13,
                                    color: isAdmin
                                        ? AppColors.mint
                                        : AppColors.muted),
                                const SizedBox(width: 5),
                                Text(
                                    isAdmin ? 'ADMIN UNLOCKED' : 'ADMIN LOCKED',
                                    style: TextStyle(
                                        color: isAdmin
                                            ? AppColors.mint
                                            : AppColors.muted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7))
                              ]),
                            ],
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [AppColors.accent, AppColors.gold]),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  const Icon(Icons.emoji_events_rounded,
                                      color: Colors.white, size: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: AppColors.surfaceRaised,
                          child: IconButton(
                            tooltip: 'Profile and access',
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AccountScreen())),
                            icon: const Icon(Icons.person_outline_rounded,
                                color: AppColors.accentLight),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Backup and restore',
                          onSelected: (action) {
                            if (action == 'restore') _showImportInfo(context);
                            if (action == 'backup')
                              _exportBackup(context, tournaments);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'backup',
                                child: Text('Backup tournaments')),
                            PopupMenuItem(
                                value: 'restore',
                                child: Text('Restore JSON backup')),
                            PopupMenuItem(
                                value: 'spreadsheet',
                                child: Text('Tournament from CSV / Excel')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const SectionLabel('Quick actions'),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.outline)),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.85,
                        children: [
                          _ActionTile(
                              icon: Icons.badge_outlined,
                              title: 'Create Team card',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const TeamCardBuilderScreen()))),
                          _ActionTile(
                              icon: Icons.file_download_outlined,
                              title: 'Import Tourney',
                              onTap: () => _showImportInfo(context)),
                          _ActionTile(
                              icon: Icons.groups_2_outlined,
                              title: 'Import Team card',
                              onTap: () => _importTeamCard(context)),
                          _ActionTile(
                              icon: Icons.merge_type_rounded,
                              title: 'Merge Tourney',
                              onTap: () =>
                                  _mergeTournaments(context, tournaments)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionLabel('All tournaments'),
                          if (tournaments.isNotEmpty)
                            Text('${tournaments.length} events',
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 12))
                        ]),
                    const SizedBox(height: 13),
                    if (tournaments.isEmpty)
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.outline)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent
                                        .withValues(alpha: 0.12)),
                                child: const Icon(Icons.emoji_events_outlined,
                                    size: 38, color: AppColors.accentLight)),
                            const SizedBox(height: 17),
                            const Text('Your next lobby starts here',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 7),
                            const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 26),
                                child: Text(
                                    'Add any tournaments to see all the available features ->',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColors.muted, height: 1.45))),
                          ],
                        ),
                      )
                    else
                      ...List.generate(
                          tournaments.length,
                          (index) => _TournamentTile(
                              tournament: tournaments[index],
                              index: index + 1)),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 22,
            bottom: 18,
            child: FilledButton.icon(
              onPressed: () async {
                if (!await requireAdmin(context) || !context.mounted) return;
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateTournamentScreen()));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 23, vertical: 15),
                  shape: const StadiumBorder()),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showImportInfo(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['json', 'csv', 'xlsx'],
          withData: true);
      if (result == null ||
          result.files.single.bytes == null ||
          !context.mounted) return;
      final file = result.files.single;
      final bytes = file.bytes!;
      final extension = file.extension?.toLowerCase() ?? '';
      final tournamentName =
          file.name.replaceFirst(RegExp(r'\.[^.]+$'), '').trim();
      if (extension == 'csv' || extension == 'xlsx') {
        final tournament = extension == 'csv'
            ? SpreadsheetTournamentImporter.fromCsv(bytes, name: tournamentName)
            : SpreadsheetTournamentImporter.fromXlsx(bytes,
                name: tournamentName);
        context.read<TournamentStore>().add(tournament);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Imported ${tournament.name} from ${extension.toUpperCase()}.')));
        return;
      }
      final source = utf8.decode(bytes);
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic> &&
          decoded['format'] == 'pointtable.backup.v1' &&
          decoded['tournaments'] is List) {
        final items =
            (decoded['tournaments'] as List).whereType<Map<String, dynamic>>();
        final store = context.read<TournamentStore>();
        for (final item in items) {
          store.add(TournamentCodec.fromJson(jsonEncode(item)));
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restored ${items.length} tournaments.')));
      } else {
        final tournament = TournamentCodec.fromJson(source);
        context.read<TournamentStore>().add(tournament);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${tournament.name}.')));
      }
    } on FormatException catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'That file is not a valid tournament export: ${error.message}')));
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not import tournament: $error')));
    }
  }

  static Future<void> _exportBackup(
      BuildContext context, List<Tournament> tournaments) async {
    if (tournaments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('There are no tournaments to back up yet.')));
      return;
    }
    final backup = jsonEncode({
      'format': 'pointtable.backup.v1',
      'tournaments': tournaments.map(TournamentCodec.encode).toList(),
    });
    await Share.shareXFiles(
      [
        XFile.fromData(Uint8List.fromList(utf8.encode(backup)),
            name: 'point-table-backup.json', mimeType: 'application/json')
      ],
      text: 'Point Table tournament backup',
    );
  }

  static Future<void> _importTeamCard(BuildContext context) async {
    final image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (image == null || !context.mounted) return;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(image.path));
      final lines = result.text
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .where((line) => line.length > 1)
          .toList();
      final teamName = lines.isEmpty ? '' : lines.first;
      final players =
          lines.length < 2 ? const <String>[] : lines.skip(1).take(8).toList();
      if (!context.mounted) return;
      await Navigator.push<void>(
          context,
          MaterialPageRoute(
              builder: (_) => TeamCardBuilderScreen(
                  initialName: teamName,
                  initialPlayers: players,
                  initialLogoPath: image.path)));
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not read team card: $error')));
    } finally {
      await recognizer.close();
    }
  }

  static void _mergeTournaments(
      BuildContext context, List<Tournament> tournaments) {
    if (tournaments.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Create or import at least two tournaments to merge.')));
      return;
    }
    final selected = <String>{};
    final nameController = TextEditingController(text: 'Merged tournament');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => Padding(
                padding: EdgeInsets.fromLTRB(
                    22, 24, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Merge tournaments',
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 15),
                      TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                              hintText: 'New tournament name')),
                      ...tournaments.map((item) => CheckboxListTile(
                          value: selected.contains(item.id),
                          title: Text(item.name),
                          activeColor: AppColors.accent,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) => setState(() => value == true
                              ? selected.add(item.id)
                              : selected.remove(item.id)))),
                      const SizedBox(height: 8),
                      PrimaryButton(
                          label: 'Merge selected',
                          onPressed: selected.length < 2
                              ? null
                              : () {
                                  context.read<TournamentStore>().merge(
                                      selected.toList(),
                                      nameController.text.trim().isEmpty
                                          ? 'Merged tournament'
                                          : nameController.text.trim());
                                  Navigator.pop(context);
                                }),
                    ]),
              )),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
              child: Row(children: [
                Icon(icon, color: AppColors.accentLight, size: 21),
                const SizedBox(width: 9),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12.5)))
              ])),
        ),
      );
}

class _TournamentTile extends StatelessWidget {
  const _TournamentTile({required this.tournament, required this.index});
  final Tournament tournament;
  final int index;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.outline)),
                leading: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(13)),
                    child: Text(index.toString().padLeft(2, '0'),
                        style: const TextStyle(
                            color: AppColors.accentLight,
                            fontWeight: FontWeight.w800))),
                title: Text(tournament.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${tournament.pointSystem.game}  ·  ${tournament.teams.length} teams  ·  ${tournament.standings.length} results',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Tournament actions',
                  onSelected: (action) {
                    if (action == 'delete') _confirmDelete(context);
                    if (action == 'open') _openScoreboard(context);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'open', child: Text('Open tournament')),
                    PopupMenuItem(
                        value: 'delete', child: Text('Delete tournament')),
                  ],
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.muted),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ScoreboardScreen(tournament: tournament))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    _tool('Calculate', Icons.calculate_outlined,
                        () => _openScoreboard(context)),
                    _tool('Tables', Icons.table_chart_outlined,
                        () => _openScoreboard(context)),
                    _tool('Warheads', Icons.military_tech_outlined,
                        () => _openPoster(context, 'Warheads')),
                    _tool('Fraggers', Icons.bolt_rounded,
                        () => _openPoster(context, 'Fraggers')),
                    _tool('Team poster', Icons.grid_view_rounded,
                        () => _openPoster(context, 'Team poster')),
                    _tool('Slot list', Icons.view_list_rounded,
                        () => _openPoster(context, 'Slot list')),
                    _tool('Certificate', Icons.workspace_premium_outlined,
                        () => _openPoster(context, 'Certificate')),
                    _tool('Share / Edit', Icons.ios_share_rounded,
                        () => _openScoreboard(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tool(String label, IconData icon, VoidCallback action) => ActionChip(
        avatar: Icon(icon, size: 15, color: AppColors.accentLight),
        label: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        onPressed: action,
        backgroundColor: AppColors.surfaceRaised,
        side: const BorderSide(color: AppColors.outline),
        visualDensity: VisualDensity.compact,
      );

  void _openScoreboard(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ScoreboardScreen(tournament: tournament)));

  void _openPoster(BuildContext context, String mode) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              PosterEditorScreen(tournament: tournament, mode: mode)));

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete tournament?'),
        content: Text('"${tournament.name}" will be removed from this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted)
      context.read<TournamentStore>().delete(tournament.id);
  }
}
