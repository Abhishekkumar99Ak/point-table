import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pointcalc_models.dart';
import '../services/bulk_team_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class TeamCardBuilderScreen extends StatefulWidget {
  const TeamCardBuilderScreen(
      {super.key,
      this.onSave,
      this.initialName = '',
      this.initialPlayers = const [],
      this.initialLogoPath,
      this.existingTeams = const []});
  final ValueChanged<TeamCard>? onSave;
  final String initialName;
  final List<String> initialPlayers;
  final String? initialLogoPath;
  final List<TeamCard> existingTeams;

  @override
  State<TeamCardBuilderScreen> createState() => _TeamCardBuilderScreenState();
}

class _TeamCardBuilderScreenState extends State<TeamCardBuilderScreen> {
  late final TextEditingController _teamName;
  late final List<TextEditingController> _players;
  late final List<String?> _photoPaths;
  final _bulkController = TextEditingController();
  final _tagsController = TextEditingController();
  late final List<TeamCard> _enteredTeams;
  var _activeTab = 0;
  String? _logoPath;
  bool _showHowTo = false;

  @override
  void initState() {
    super.initState();
    _teamName = TextEditingController(text: widget.initialName);
    _enteredTeams = List.of(widget.existingTeams);
    _players = widget.initialPlayers.isEmpty
        ? [TextEditingController()]
        : widget.initialPlayers
            .map((name) => TextEditingController(text: name))
            .toList();
    _photoPaths = List<String?>.filled(_players.length, null);
    _logoPath = widget.initialLogoPath;
  }

  @override
  void dispose() {
    _teamName.dispose();
    _bulkController.dispose();
    _tagsController.dispose();
    for (final controller in _players) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        appBar: AppBar(
            title: const Text('Team card'),
            backgroundColor: Colors.transparent),
        child: Column(children: [
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                        value: 0,
                        label: Text('Add'),
                        icon: Icon(Icons.group_add_outlined)),
                    ButtonSegment(
                        value: 1,
                        label: Text('Entered'),
                        icon: Icon(Icons.groups_outlined)),
                  ],
                  selected: {_activeTab},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      setState(() => _activeTab = selection.first),
                ),
                const SizedBox(height: 14),
                if (_activeTab == 1) ...[
                  const SectionLabel('Active slots'),
                  const SizedBox(height: 8),
                  if (_enteredTeams.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(28),
                        child: Text('No teams entered yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted)))
                  else
                    ..._enteredTeams.map((team) => ListTile(
                          leading: CircleAvatar(
                              backgroundColor: AppColors.surfaceRaised,
                              child: Text(
                                  (team.slotNumber ?? 0)
                                      .toString()
                                      .padLeft(2, '0'),
                                  style: const TextStyle(
                                      color: AppColors.accentLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800))),
                          title: Text(team.name),
                          subtitle: Text(
                              [
                                '${team.players.length} players',
                                if (team.tags.isNotEmpty) team.tags.join(' · '),
                              ].join(' · '),
                              style: const TextStyle(color: AppColors.muted)),
                        )),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.outline)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bulk team entry',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          const Text(
                              'Paste one team per line. Optional slot prefixes: 01, 02, 03.',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 11)),
                          const SizedBox(height: 9),
                          TextField(
                              controller: _bulkController,
                              minLines: 2,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                  hintText:
                                      '01 Nova Five\nLunar Wolves\n03 Frost Unit')),
                          const SizedBox(height: 9),
                          SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                  onPressed: _addBulkTeams,
                                  icon: const Icon(Icons.playlist_add_rounded),
                                  label:
                                      const Text('Add lines to slots 1–12'))),
                        ]),
                  ),
                  const SizedBox(height: 13),
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: ExpansionTile(
                      initiallyExpanded: _showHowTo,
                      onExpansionChanged: (value) =>
                          setState(() => _showHowTo = value),
                      leading: const Icon(Icons.info_outline_rounded,
                          color: AppColors.accentLight),
                      title: const Text('How it works',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      children: const [
                        Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                                'Add your team identity and player names, then share the card with your squad.',
                                style: TextStyle(color: AppColors.muted)))
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.outline)),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              AppColors.accent.withValues(alpha: 0.2),
                          backgroundImage: _logoPath == null
                              ? null
                              : FileImage(File(_logoPath!)),
                          child: _logoPath == null
                              ? const Icon(Icons.shield_outlined,
                                  color: AppColors.accentLight)
                              : null),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Text('Your Team',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17))),
                      Text(
                          '${_players.where((controller) => controller.text.trim().isNotEmpty).length} players',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12))
                    ]),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Team details'),
                  const SizedBox(height: 11),
                  Row(children: [
                    InkWell(
                        onTap: () async {
                          final image = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 85);
                          if (image != null && mounted)
                            setState(() => _logoPath = image.path);
                        },
                        child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                                color: AppColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(color: AppColors.outline)),
                            child: _logoPath == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            color: AppColors.accentLight),
                                        SizedBox(height: 4),
                                        Text('Logo',
                                            style: TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 10))
                                      ])
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(File(_logoPath!),
                                        fit: BoxFit.cover)))),
                    const SizedBox(width: 11),
                    Expanded(
                        child: TextField(
                            controller: _teamName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                labelText: 'Team Name',
                                hintText: 'Enter Clan name'))),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'e.g. invited, regional, substitute'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionLabel('Player details'),
                        TextButton.icon(
                            onPressed: _addPlayer,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add player'))
                      ]),
                  const SizedBox(height: 4),
                  ...List.generate(
                      _players.length, (index) => _playerTile(index)),
                ],
              ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                  label:
                      _activeTab == 1 ? 'Add another team' : 'Add team & share',
                  icon: _activeTab == 1
                      ? Icons.add_rounded
                      : Icons.ios_share_rounded,
                  onPressed: _activeTab == 1
                      ? () => setState(() => _activeTab = 0)
                      : _shareCard)),
        ]),
      );

  Widget _playerTile(int index) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline)),
        child: Row(children: [
          Text('Player ${index + 1}',
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: _players[index],
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      hintText: 'Player name',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12)))),
          IconButton(
              tooltip: 'Add player photo',
              onPressed: () async {
                final image = await ImagePicker()
                    .pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (image != null && mounted)
                  setState(() => _photoPaths[index] = image.path);
              },
              icon: Icon(
                  _photoPaths[index] == null
                      ? Icons.add_a_photo_outlined
                      : Icons.check_circle_rounded,
                  color: AppColors.accentLight)),
          if (_players.length > 1)
            IconButton(
                tooltip: 'Remove player',
                onPressed: () => setState(() {
                      _players.removeAt(index).dispose();
                      _photoPaths.removeAt(index);
                    }),
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.muted)),
        ]),
      );

  int? get _nextSlot {
    final occupied =
        _enteredTeams.map((team) => team.slotNumber).whereType<int>().toSet();
    for (var slot = 1; slot <= 12; slot++) {
      if (!occupied.contains(slot)) return slot;
    }
    return null;
  }

  void _addPlayer() {
    if (_players.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A team card supports four player slots.')));
      return;
    }
    setState(() {
      _players.add(TextEditingController());
      _photoPaths.add(null);
    });
  }

  void _addBulkTeams() {
    final assigned = BulkTeamParser.parse(
      _bulkController.text,
      existingTeams: _enteredTeams,
    );
    if (assigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('No valid, unassigned team names or slots were found.')));
      return;
    }
    for (final team in assigned) {
      widget.onSave?.call(team);
    }
    setState(() {
      _enteredTeams.addAll(assigned);
      _bulkController.clear();
      _activeTab = 1;
    });
  }

  Future<void> _shareCard() async {
    final name = _teamName.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a team name before sharing.')));
      return;
    }
    final players = List.generate(
            _players.length,
            (index) => TeamPlayer(
                name: _players[index].text.trim(),
                photoPath: _photoPaths[index]))
        .where((player) => player.name.isNotEmpty)
        .toList();
    final slot = _nextSlot;
    if (slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All 12 tournament slots are assigned.')));
      return;
    }
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    final card = TeamCard(
        name: name,
        players: players,
        slotNumber: slot,
        logoPath: _logoPath,
        tags: tags);
    widget.onSave?.call(card);
    setState(() {
      _enteredTeams.add(card);
      _activeTab = 1;
    });
    final roster = players.isEmpty
        ? 'Roster to be announced'
        : players.map((player) => '• ${player.name}').join('\n');
    await Share.share('$name\n$roster', subject: '$name team card');
  }
}
