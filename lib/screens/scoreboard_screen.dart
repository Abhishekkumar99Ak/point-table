import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pointcalc_models.dart';
import '../services/scoreboard_parser.dart';
import '../services/admin_gate.dart';
import '../services/lobby_parser.dart';
import '../services/tournament_codec.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import 'poster_editor_screen.dart';
import 'team_card_builder_screen.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key, required this.tournament});
  final Tournament tournament;

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  final _posterController = ScreenshotController();
  final _picker = ImagePicker();
  late Tournament _tournament = widget.tournament;
  late List<LobbySlot> _lobbySlots = widget.tournament.lobbySlots.isNotEmpty
      ? List.of(widget.tournament.lobbySlots)
      : List.generate(12, (index) => LobbySlot(slotNumber: index + 1));
  late bool _rememberLobby = widget.tournament.rememberLobby;
  late int _matchNumber = widget.tournament.standings.fold<int>(
    1,
    (current, row) =>
        row.matchNumber >= current ? row.matchNumber + 1 : current,
  );
  bool _autoIncrementMatch = true;
  bool _sortByKills = false;
  int _tableMatch = 0;
  bool _scanning = false;

  @override
  Widget build(BuildContext context) => AppScaffold(
        appBar: AppBar(
          title: Text(_tournament.name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
                tooltip: 'Create team poster',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PosterEditorScreen(tournament: _tournament))),
                icon: const Icon(Icons.auto_awesome_mosaic_outlined)),
            IconButton(
                tooltip: 'Export tournament data',
                onPressed: _shareTournament,
                icon: const Icon(Icons.ios_share_rounded)),
            IconButton(
                tooltip: 'Add team card',
                onPressed: _addTeam,
                icon: const Icon(Icons.group_add_outlined)),
          ],
        ),
        child: Column(children: [
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 7, 20, 20),
                  children: [
                Row(children: [
                  Expanded(
                      child: _SummaryStat(
                          label: 'GAME',
                          value: _tournament.pointSystem.game,
                          icon: Icons.sports_esports_rounded)),
                  const SizedBox(width: 9),
                  Expanded(
                      child: _SummaryStat(
                          label: 'KILL POINT',
                          value: '${_tournament.pointSystem.killPoints} pt',
                          icon: Icons.bolt_rounded)),
                  const SizedBox(width: 9),
                  Expanded(
                      child: _SummaryStat(
                          label: 'TEAMS',
                          value: '${_tournament.teams.length}',
                          icon: Icons.groups_2_outlined)),
                ]),
                const SizedBox(height: 19),
                const Text('Match results and standings',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                const Text(
                    'Import a scoreboard screenshot, then review every detected row.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 13),
                _matchControls(),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.outline)),
                  value: _rememberLobby,
                  activeTrackColor: AppColors.accentLight,
                  title: const Text('Remember lobby',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(
                      _rememberLobby
                          ? 'Saved locally for upcoming matches'
                          : 'Use once without saving',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                  onChanged: _setRememberLobby,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _scanning ? null : _pickLobby,
                  icon: const Icon(Icons.groups_2_outlined),
                  label: Text(
                      _lobbySlots.any((slot) => slot.teamName.isNotEmpty)
                          ? 'Replace lobby screenshot'
                          : 'Scan lobby screenshot'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentLight,
                      side: const BorderSide(color: AppColors.outline),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                ),
                const SizedBox(height: 8),
                _lobbyPreview(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _scanning ? null : _pickScoreboard,
                  icon: _scanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.document_scanner_outlined),
                  label: Text(_scanning
                      ? 'Reading scoreboard...'
                      : 'Upload scoreboard screenshot'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentLight,
                      side: const BorderSide(color: AppColors.outline),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                ),
                const SizedBox(height: 20),
                if (_tournament.standings.isEmpty)
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outline)),
                      child: const Column(children: [
                        Icon(Icons.query_stats_rounded,
                            size: 36, color: AppColors.accentLight),
                        SizedBox(height: 10),
                        Text('No results yet',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text(
                            'Add a screenshot or enter scores to build standings.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: AppColors.muted, fontSize: 12))
                      ]))
                else ...[
                  Row(children: [
                    const Text('Standings view',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _tableMatch,
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem(
                            value: 0, child: Text('Overall')),
                        ..._matchNumbers.map((number) => DropdownMenuItem(
                            value: number, child: Text('Match $number'))),
                      ],
                      onChanged: (value) =>
                          setState(() => _tableMatch = value ?? 0),
                    ),
                  ]),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: false,
                            label: Text('Points'),
                            icon: Icon(Icons.emoji_events_outlined)),
                        ButtonSegment(
                            value: true,
                            label: Text('Kills'),
                            icon: Icon(Icons.bolt_rounded)),
                      ],
                      selected: {_sortByKills},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          setState(() => _sortByKills = selection.first),
                    ),
                  ),
                  Screenshot(
                      controller: _posterController,
                      child: _StandingsPoster(
                          tournament: _tournament,
                          rows: _displayStandings,
                          selectedMatch: _tableMatch)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton.icon(
                            onPressed: _addManualScore,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add result'))),
                    const SizedBox(width: 9),
                    Expanded(
                        child: FilledButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PosterEditorScreen(
                                        tournament: _tournament))),
                            icon:
                                const Icon(Icons.auto_awesome_mosaic_outlined),
                            label: const Text('Make poster'),
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent))),
                  ]),
                ],
                if (_tournament.teams.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const SectionLabel('Registered teams'),
                  const SizedBox(height: 9),
                  ..._tournament.teams.map((team) => ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: AppColors.surfaceRaised,
                          child: Icon(Icons.shield_outlined,
                              color: AppColors.accentLight, size: 19)),
                      title: Text(team.name),
                      subtitle: Text('${team.players.length} players',
                          style: const TextStyle(color: AppColors.muted))))
                ],
              ])),
          if (_tournament.standings.isEmpty)
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: PrimaryButton(
                    label: 'Enter scores manually',
                    icon: Icons.edit_note_rounded,
                    onPressed: _addManualScore)),
        ]),
      );

  List<int> get _matchNumbers =>
      _tournament.standings.map((entry) => entry.matchNumber).toSet().toList()
        ..sort();

  List<ScoreEntry> get _displayStandings {
    if (_tableMatch > 0) {
      return _tournament.standings
          .where((entry) => entry.matchNumber == _tableMatch)
          .toList()
        ..sort(_compareStandings);
    }
    final totals = <String, List<ScoreEntry>>{};
    for (final entry in _tournament.standings) {
      totals.putIfAbsent(entry.teamName, () => []).add(entry);
    }
    return totals.entries.map((team) {
      final scores = team.value;
      return ScoreEntry(
        teamName: team.key,
        placement: scores
            .map((score) => score.placement)
            .reduce((a, b) => a < b ? a : b),
        kills: scores.fold(0, (sum, score) => sum + score.kills),
        totalPoints: scores.fold(0, (sum, score) => sum + score.totalPoints),
      );
    }).toList()
      ..sort(_compareStandings);
  }

  int _compareStandings(ScoreEntry left, ScoreEntry right) {
    final primary = _sortByKills
        ? right.kills.compareTo(left.kills)
        : right.totalPoints.compareTo(left.totalPoints);
    if (primary != 0) return primary;
    final secondary = _sortByKills
        ? right.totalPoints.compareTo(left.totalPoints)
        : right.kills.compareTo(left.kills);
    return secondary != 0
        ? secondary
        : left.placement.compareTo(right.placement);
  }

  Widget _matchControls() {
    final maxMatch = _matchNumbers.isEmpty ? 1 : _matchNumbers.last + 1;
    final choices = List.generate(maxMatch, (index) => index + 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline)),
      child: Row(children: [
        const Icon(Icons.sports_esports_outlined,
            color: AppColors.accentLight, size: 19),
        const SizedBox(width: 8),
        const Text('Match', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: choices.contains(_matchNumber) ? _matchNumber : choices.last,
          underline: const SizedBox.shrink(),
          items: choices
              .map((number) =>
                  DropdownMenuItem(value: number, child: Text('$number')))
              .toList(),
          onChanged: (value) =>
              setState(() => _matchNumber = value ?? _matchNumber),
        ),
        const Spacer(),
        const Text('Auto',
            style: TextStyle(color: AppColors.muted, fontSize: 11)),
        Switch.adaptive(
            value: _autoIncrementMatch,
            onChanged: (value) => setState(() => _autoIncrementMatch = value)),
      ]),
    );
  }

  Widget _lobbyPreview() => Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 13),
          title: const Text('Lobby slots',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
              '${_lobbySlots.where((slot) => slot.teamName.isNotEmpty).length} of 12 recognized',
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          children: _lobbySlots
              .map((slot) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surfaceRaised,
                        child: Text(slot.slotNumber.toString().padLeft(2, '0'),
                            style: const TextStyle(
                                color: AppColors.accentLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w800))),
                    title: Text(
                        slot.teamName.isEmpty
                            ? 'Unassigned slot'
                            : slot.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        slot.playerNames.isEmpty
                            ? 'No player names'
                            : slot.playerNames.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 10)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          tooltip: 'Update slot ${slot.slotNumber}',
                          onPressed: () => _editSlot(slot),
                          icon: const Icon(Icons.edit_outlined, size: 18)),
                      IconButton(
                          tooltip: 'Delete slot ${slot.slotNumber}',
                          onPressed: () => _deleteSlot(slot),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18)),
                    ]),
                  ))
              .toList(),
        ),
      );

  Future<void> _setRememberLobby(bool value) async {
    setState(() => _rememberLobby = value);
    _tournament = _tournament.copyWith(
        rememberLobby: value, lobbySlots: value ? _lobbySlots : const []);
    context.read<TournamentStore>().update(_tournament);
    if (value && !_lobbySlots.any((slot) => slot.teamName.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Scan a lobby to save its slots for the next match.')));
    }
  }

  Future<void> _pickLobby() async {
    if (!await requireAdmin(context) || !mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose lobby screenshot'),
            onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Capture lobby'),
            onTap: () => Navigator.pop(context, ImageSource.camera)),
      ])),
    );
    if (source == null || !mounted) return;
    final image = await _picker.pickImage(source: source, imageQuality: 100);
    if (image == null || !mounted) return;
    setState(() => _scanning = true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized =
          await recognizer.processImage(InputImage.fromFilePath(image.path));
      final parsed = LobbyParser.mapToRegisteredTeams(
          LobbyParser.parse(recognized.text), _tournament.teams);
      if (!parsed.any((slot) => slot.teamName.isNotEmpty)) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'No lobby slots were recognized. Try a clearer screenshot or enter slots manually.')));
        return;
      }
      setState(() => _lobbySlots = parsed);
      if (_rememberLobby) {
        _tournament =
            _tournament.copyWith(lobbySlots: parsed, rememberLobby: true);
        context.read<TournamentStore>().update(_tournament);
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Lobby scanned. Review and update the 12 slots before using the results.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not read that lobby image: $error')));
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _editSlot(LobbySlot slot) async {
    final team = TextEditingController(text: slot.teamName);
    final players = List.generate(
        4,
        (index) => TextEditingController(
            text: index < slot.playerNames.length
                ? slot.playerNames[index]
                : ''));
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                  'Update slot ${slot.slotNumber.toString().padLeft(2, '0')}'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: team,
                    decoration: const InputDecoration(labelText: 'Team name')),
                ...List.generate(
                    4,
                    (index) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextField(
                            controller: players[index],
                            decoration: InputDecoration(
                                labelText: 'Player ${index + 1}')))),
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
    if (accepted == true && mounted) {
      final replacement = LobbySlot(
          slotNumber: slot.slotNumber,
          teamName: team.text.trim(),
          playerNames: players
              .map((controller) => controller.text.trim())
              .where((name) => name.isNotEmpty)
              .toList());
      setState(() => _lobbySlots = _lobbySlots
          .map(
              (item) => item.slotNumber == slot.slotNumber ? replacement : item)
          .toList());
      if (_rememberLobby) {
        _tournament = _tournament.copyWith(lobbySlots: _lobbySlots);
        context.read<TournamentStore>().update(_tournament);
      }
    }
    team.dispose();
    for (final controller in players) {
      controller.dispose();
    }
  }

  Future<void> _deleteSlot(LobbySlot slot) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                  'Clear slot ${slot.slotNumber.toString().padLeft(2, '0')}?'),
              content: const Text(
                  'The team and player names will be removed from this lobby slot.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear'))
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _lobbySlots = _lobbySlots
        .map((item) => item.slotNumber == slot.slotNumber
            ? LobbySlot(slotNumber: item.slotNumber)
            : item)
        .toList());
    if (_rememberLobby) {
      _tournament = _tournament.copyWith(lobbySlots: _lobbySlots);
      context.read<TournamentStore>().update(_tournament);
    }
  }

  Future<void> _pickScoreboard() async {
    if (!await requireAdmin(context) || !mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take scoreboard photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera)),
        ]),
      ),
    );
    if (source == null || !mounted) return;
    final image = await _picker.pickImage(source: source, imageQuality: 100);
    if (image == null || !mounted) return;
    setState(() => _scanning = true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(image.path));
      final knownTeams = <String>{
        ..._tournament.teams.map((team) => team.name),
        ..._lobbySlots
            .map((slot) => slot.teamName)
            .where((name) => name.isNotEmpty),
      }.toList();
      final parsed = ScoreboardParser.parse(
        result.text,
        knownTeams: knownTeams,
        matchNumber: _matchNumber,
      );
      final entries = parsed.map((entry) {
        final slot = _lobbySlots.cast<LobbySlot?>().firstWhere(
              (candidate) =>
                  candidate?.teamName.toLowerCase() ==
                  entry.teamName.toLowerCase(),
              orElse: () => null,
            );
        return entry.copyWith(
          slotNumber: slot?.slotNumber ??
              _tournament.teams
                  .where((team) =>
                      team.name.toLowerCase() == entry.teamName.toLowerCase())
                  .firstOrNull
                  ?.slotNumber,
          playerKills: (slot?.playerNames ?? const <String>[])
              .map((name) => PlayerKill(playerName: name, kills: 0))
              .toList(),
        );
      }).toList();
      if (!mounted) return;
      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No score rows found. Try a sharper screenshot or enter scores manually.')));
        return;
      }
      final reviewed = await _reviewDetectedRows(entries);
      if (!mounted || reviewed == null) return;
      if (!await _confirmSaveAll(reviewed) || !mounted) return;
      _saveStandings(reviewed);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not read that screenshot: $error')));
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<List<ScoreEntry>?> _reviewDetectedRows(
      List<ScoreEntry> entries) async {
    final playerKills =
        entries.map((entry) => List<PlayerKill>.of(entry.playerKills)).toList();
    final controllers = entries
        .map((entry) => [
              TextEditingController(text: entry.teamName),
              TextEditingController(text: '${entry.placement}'),
              TextEditingController(text: '${entry.kills}')
            ])
        .toList();
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
                  child: Padding(
                padding: EdgeInsets.fromLTRB(
                    18, 18, 18, MediaQuery.viewInsetsOf(context).bottom + 16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Review detected scores',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  const Text(
                      'Check names, placement and kills before calculating points.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 13),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: List.generate(
                          controllers.length,
                          (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  SizedBox(
                                      width: 38,
                                      child: Text('#${index + 1}',
                                          style: const TextStyle(
                                              color: AppColors.accentLight,
                                              fontWeight: FontWeight.w700))),
                                  Expanded(
                                      flex: 5,
                                      child: TextField(
                                          controller: controllers[index][0],
                                          decoration: const InputDecoration(
                                              hintText: 'Team name',
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 12)))),
                                  const SizedBox(width: 6),
                                  Expanded(
                                      child: TextField(
                                          controller: controllers[index][1],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                              hintText: 'Place',
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12)))),
                                  const SizedBox(width: 6),
                                  Expanded(
                                      child: TextField(
                                          controller: controllers[index][2],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                              hintText: 'Kills',
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12)))),
                                  IconButton(
                                      tooltip: 'Enter player kills',
                                      onPressed: () async {
                                        final corrected =
                                            await _editPlayerKills(
                                          controllers[index][0].text,
                                          playerKills[index],
                                        );
                                        if (corrected != null) {
                                          setSheetState(() =>
                                              playerKills[index] = corrected);
                                        }
                                      },
                                      icon: const Icon(Icons.edit_note_rounded,
                                          size: 19)),
                                  IconButton(
                                      tooltip: 'Remove row',
                                      onPressed: () => setSheetState(() {
                                            for (final controller
                                                in controllers[index]) {
                                              controller.dispose();
                                            }
                                            controllers.removeAt(index);
                                            playerKills.removeAt(index);
                                          }),
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18)),
                                ]),
                              )),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                      label: 'Complete',
                      onPressed: () => Navigator.pop(sheetContext, true)),
                ]),
              ))),
    );
    final output = accepted == true
        ? List.generate(
            controllers.length,
            (index) => ScoreEntry(
                  teamName: controllers[index][0].text.trim(),
                  placement:
                      int.tryParse(controllers[index][1].text) ?? index + 1,
                  kills: int.tryParse(controllers[index][2].text) ?? 0,
                  matchNumber: _matchNumber,
                  slotNumber: _slotForTeam(controllers[index][0].text.trim()),
                  playerKills: playerKills[index],
                )).where((entry) => entry.teamName.isNotEmpty).toList()
        : null;
    for (final row in controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    return output;
  }

  int? _slotForTeam(String name) {
    for (final slot in _lobbySlots) {
      if (slot.teamName.toLowerCase() == name.toLowerCase())
        return slot.slotNumber;
    }
    for (final team in _tournament.teams) {
      if (team.name.toLowerCase() == name.toLowerCase()) return team.slotNumber;
    }
    return null;
  }

  Future<List<PlayerKill>?> _editPlayerKills(
    String teamName,
    List<PlayerKill> initial,
  ) async {
    final slot = _lobbySlots
        .where((item) => item.teamName.toLowerCase() == teamName.toLowerCase())
        .firstOrNull;
    final roster = initial.isNotEmpty
        ? initial
        : (slot?.playerNames ?? const <String>[])
            .map((name) => PlayerKill(playerName: name, kills: 0))
            .toList();
    final names = List.generate(
        4,
        (index) => TextEditingController(
            text: index < roster.length ? roster[index].playerName : ''));
    final kills = List.generate(
        4,
        (index) => TextEditingController(
            text: index < roster.length ? '${roster[index].kills}' : '0'));
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Player kills · $teamName'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                          4,
                          (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Expanded(
                                      flex: 3,
                                      child: TextField(
                                          controller: names[index],
                                          decoration: InputDecoration(
                                              labelText:
                                                  'Player ${index + 1}'))),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: TextField(
                                          controller: kills[index],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                              labelText: 'Kills'))),
                                ]),
                              )))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Apply'))
              ],
            ));
    final result = accepted == true
        ? List.generate(
                4,
                (index) => PlayerKill(
                    playerName: names[index].text.trim(),
                    kills: int.tryParse(kills[index].text) ?? 0))
            .where((row) => row.playerName.isNotEmpty)
            .toList()
        : null;
    for (final controller in [...names, ...kills]) {
      controller.dispose();
    }
    return result;
  }

  Future<bool> _confirmSaveAll(List<ScoreEntry> rows) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Save all results?'),
          content: Text(
              '${rows.length} reviewed teams will be saved to Match $_matchNumber. Existing results for this match will be replaced; other matches remain unchanged.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Review again')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save All')),
          ],
        ),
      ) ??
      false;

  Future<void> _addManualScore() async {
    final teamController = TextEditingController();
    final placeController = TextEditingController(text: '1');
    final killsController = TextEditingController(text: '0');
    final result = await showDialog<ScoreEntry>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Add match result'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: teamController,
                    decoration: const InputDecoration(labelText: 'Team name')),
                const SizedBox(height: 9),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: placeController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Placement'))),
                  const SizedBox(width: 9),
                  Expanded(
                      child: TextField(
                          controller: killsController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Kills')))
                ])
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      final name = teamController.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(
                          context,
                          ScoreEntry(
                              teamName: name,
                              placement:
                                  int.tryParse(placeController.text) ?? 1,
                              kills: int.tryParse(killsController.text) ?? 0));
                    },
                    child: const Text('Add'))
              ],
            ));
    teamController.dispose();
    placeController.dispose();
    killsController.dispose();
    if (result != null) {
      final entry = result.copyWith(
          matchNumber: _matchNumber, slotNumber: _slotForTeam(result.teamName));
      if (await _confirmSaveAll([entry]) && mounted) _saveStandings([entry]);
    }
  }

  void _saveStandings(List<ScoreEntry> rows) {
    final scoredRows = rows
        .map((entry) => entry.copyWith(
            matchNumber: _matchNumber,
            totalPoints: _tournament.pointSystem
                .pointsFor(entry.placement, entry.kills)))
        .toList();
    final allMatches = [
      ..._tournament.standings
          .where((entry) => entry.matchNumber != _matchNumber),
      ...scoredRows,
    ]..sort((a, b) {
        final matchOrder = a.matchNumber.compareTo(b.matchNumber);
        return matchOrder != 0
            ? matchOrder
            : b.totalPoints.compareTo(a.totalPoints);
      });
    setState(() {
      _tournament = _tournament.copyWith(standings: allMatches);
      if (_autoIncrementMatch) _matchNumber++;
    });
    context.read<TournamentStore>().update(_tournament);
  }

  Future<void> _shareTournament() async {
    final json = TournamentCodec.toJson(_tournament);
    await Share.shareXFiles([
      XFile.fromData(Uint8List.fromList(utf8.encode(json)),
          name: 'pointcalc-tournament.json', mimeType: 'application/json')
    ], text: '${_tournament.name} tournament data');
  }

  Future<void> _addTeam() async {
    await Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (_) => TeamCardBuilderScreen(
                existingTeams: _tournament.teams,
                onSave: (team) {
                  _tournament =
                      _tournament.copyWith(teams: [..._tournament.teams, team]);
                  context.read<TournamentStore>().update(_tournament);
                })));
    if (mounted) setState(() {});
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.accentLight, size: 18),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 8,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
      ]));
}

class _StandingsPoster extends StatelessWidget {
  const _StandingsPoster(
      {required this.tournament,
      required this.rows,
      required this.selectedMatch});
  final Tournament tournament;
  final List<ScoreEntry> rows;
  final int selectedMatch;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceRaised,
                  AppColors.surface,
                  AppColors.background
                ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.accentLight)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(tournament.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${tournament.pointSystem.game}  ·  OFFICIAL STANDINGS',
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700))
                ]))
          ]),
          const SizedBox(height: 16),
          const Row(children: [
            SizedBox(width: 24, child: Text('#', style: _headerStyle)),
            Expanded(child: Text('TEAM', style: _headerStyle)),
            SizedBox(
                width: 22,
                child: Text('MP',
                    textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(
                width: 22,
                child: Text('W',
                    textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(
                width: 27,
                child: Text('POS',
                    textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(
                width: 27,
                child: Text('K',
                    textAlign: TextAlign.center, style: _headerStyle)),
            SizedBox(
                width: 36,
                child: Text('PTS',
                    textAlign: TextAlign.right, style: _headerStyle)),
          ]),
          const Divider(color: AppColors.outline, height: 14),
          ...List.generate(rows.length, (index) {
            final entry = rows[index];
            final teamMatches = tournament.standings
                .where((score) =>
                    score.teamName == entry.teamName &&
                    (selectedMatch == 0 || score.matchNumber == selectedMatch))
                .toList();
            final positionPoints = teamMatches.fold<int>(0, (sum, score) {
              final placement = score.placement;
              return sum +
                  (placement > 0 &&
                          placement <=
                              tournament.pointSystem.positionPoints.length
                      ? tournament.pointSystem.positionPoints[placement - 1]
                      : 0);
            });
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  SizedBox(
                      width: 24,
                      child: Text('${index + 1}'.padLeft(2, '0'),
                          style: TextStyle(
                              color:
                                  index == 0 ? AppColors.mint : AppColors.muted,
                              fontWeight: FontWeight.w800))),
                  Expanded(
                      child: Text(entry.teamName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 22,
                      child: Text('${teamMatches.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted))),
                  SizedBox(
                      width: 22,
                      child: Text(
                          '${teamMatches.where((score) => score.placement == 1).length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted))),
                  SizedBox(
                      width: 27,
                      child: Text('$positionPoints',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted))),
                  SizedBox(
                      width: 27,
                      child: Text('${entry.kills}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted))),
                  SizedBox(
                      width: 36,
                      child: Text('${entry.totalPoints}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: AppColors.accentLight,
                              fontWeight: FontWeight.w800))),
                ]));
          }),
          const Divider(color: AppColors.outline, height: 18),
          const Align(
              alignment: Alignment.centerRight,
              child: Text('POINT TABLE  ·  ALL GAMES',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w700))),
        ]),
      );

  static const _headerStyle = TextStyle(
      color: AppColors.muted,
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1);
}
