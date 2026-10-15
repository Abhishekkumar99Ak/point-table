import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/pointcalc_models.dart';
import '../services/admin_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _nameController = TextEditingController();
  var _pointSystem = const PointSystem();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        appBar: AppBar(
            title: const Text('New tournament'),
            backgroundColor: Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Create a tournament',
                style: GoogleFonts.dancingScript(
                    color: AppColors.accentLight,
                    fontSize: 30,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Set up your lobby and scoring rules.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 30),
            const SectionLabel('Tournament name'),
            const SizedBox(height: 10),
            TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    hintText: 'Enter Tourney Name',
                    prefixIcon: Icon(Icons.flag_outlined))),
            const SizedBox(height: 23),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: AppColors.outline)),
              child: SwitchListTile.adaptive(
                value: _pointSystem.roundRobin,
                activeTrackColor: AppColors.accentLight,
                title: const Text('Round Robin',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Every team plays each round',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                onChanged: (value) => setState(() =>
                    _pointSystem = _pointSystem.copyWith(roundRobin: value)),
              ),
            ),
            const Spacer(),
            PrimaryButton(label: 'GO', onPressed: _continueSetup),
          ]),
        ),
      );

  Future<void> _continueSetup() async {
    if (!await requireAdmin(context) || !mounted) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Give your tournament a name to continue.')));
      return;
    }
    final points = await Navigator.push<PointSystem>(
        context,
        MaterialPageRoute(
            builder: (_) => PointSystemScreen(initial: _pointSystem)));
    if (!mounted || points == null) return;
    final registration = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => const _JoiningSheet(),
    );
    if (!mounted || registration == null) return;
    final tournament = Tournament(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      pointSystem: points,
    );
    context.read<TournamentStore>().add(tournament);
    Navigator.pop(context, tournament);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(registration
            ? 'Open registration is ready for $name.'
            : '$name created. Add teams whenever you are ready.')));
  }
}

class PointSystemScreen extends StatefulWidget {
  const PointSystemScreen({super.key, required this.initial});
  final PointSystem initial;

  @override
  State<PointSystemScreen> createState() => _PointSystemScreenState();
}

class _PointSystemScreenState extends State<PointSystemScreen> {
  static const _games = ['BGMI', 'FreeFire', 'More'];
  late String _game = widget.initial.game;
  late int _kills = widget.initial.killPoints;
  late List<int> _positions = List.of(widget.initial.positionPoints);

  @override
  Widget build(BuildContext context) => AppScaffold(
        appBar: AppBar(
            title: const Text('Point system'),
            backgroundColor: Colors.transparent),
        child: Column(children: [
          Expanded(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                children: [
                  const Text('Choose your rules',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Tune scoring to match your lobby.',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 21),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _games
                          .map((game) => _GameChip(
                              game: game,
                              selected: game == 'More'
                                  ? !['BGMI', 'FreeFire'].contains(_game)
                                  : _game == game,
                              onTap: () async {
                                String? moreGame;
                                if (game == 'More') {
                                  final selected = await showModalBottomSheet<
                                          String>(
                                      context: context,
                                      backgroundColor: AppColors.surface,
                                      builder: (context) => SafeArea(
                                          child: ListView(
                                              shrinkWrap: true,
                                              padding: const EdgeInsets.all(16),
                                              children: [
                                                'COD Mobile',
                                                'Apex Legends',
                                                'Custom'
                                              ]
                                                  .map((option) => ListTile(
                                                      title: Text(option),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                              context, option)))
                                                  .toList())));
                                  moreGame = selected;
                                  if (selected == null || !mounted) return;
                                } else {
                                  moreGame = game;
                                }
                                setState(() {
                                  _game = moreGame!;
                                  if (_game == 'FreeFire')
                                    _positions = [
                                      10,
                                      6,
                                      5,
                                      4,
                                      3,
                                      2,
                                      1,
                                      0,
                                      0,
                                      0
                                    ];
                                  if (_game == 'BGMI')
                                    _positions = [
                                      12,
                                      9,
                                      8,
                                      7,
                                      6,
                                      5,
                                      4,
                                      3,
                                      2,
                                      1
                                    ];
                                });
                              }))
                          .toList()),
                  const SizedBox(height: 23),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.outline)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Kills point',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                _PointBadge('$_kills pt')
                              ]),
                          Slider(
                              value: _kills.toDouble(),
                              min: 0,
                              max: 5,
                              divisions: 5,
                              label: '$_kills',
                              onChanged: (value) =>
                                  setState(() => _kills = value.round())),
                          const SizedBox(height: 1),
                          const SectionLabel('Position points'),
                          const SizedBox(height: 5),
                          ...List.generate(
                              _positions.length,
                              (index) => _PositionSlider(
                                    rank: index + 1,
                                    value: _positions[index],
                                    onChanged: (value) => setState(() =>
                                        _positions[index] = value.round()),
                                  )),
                        ]),
                  ),
                  const SizedBox(height: 10),
                  const Text('All values can be changed at any time.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ]),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: PrimaryButton(
                  label: 'Continue',
                  onPressed: () => Navigator.pop(
                      context,
                      PointSystem(
                          game: _game,
                          killPoints: _kills,
                          positionPoints: List.unmodifiable(_positions),
                          roundRobin: widget.initial.roundRobin)))),
        ]),
      );
}

class _GameChip extends StatelessWidget {
  const _GameChip(
      {required this.game, required this.selected, required this.onTap});
  final String game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(game),
          if (selected) ...[
            const SizedBox(width: 5),
            const Icon(Icons.check_rounded, size: 15)
          ]
        ]),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.accent.withValues(alpha: 0.25),
        backgroundColor: AppColors.surface,
        side:
            BorderSide(color: selected ? AppColors.accent : AppColors.outline),
        labelStyle: TextStyle(
            color: selected ? AppColors.accentLight : AppColors.text,
            fontWeight: FontWeight.w600),
      );
}

class _PositionSlider extends StatelessWidget {
  const _PositionSlider(
      {required this.rank, required this.value, required this.onChanged});
  final int rank;
  final int value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
            width: 34,
            child: Text('#$rank',
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w700))),
        Expanded(
            child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                label: '$value',
                onChanged: onChanged)),
        SizedBox(width: 43, child: _PointBadge('$value')),
      ]);
}

class _PointBadge extends StatelessWidget {
  const _PointBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9)),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.accentLight,
              fontSize: 12,
              fontWeight: FontWeight.w700)));
}

class _JoiningSheet extends StatelessWidget {
  const _JoiningSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.outline,
                            borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.17),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.workspace_premium_outlined,
                          color: AppColors.accentLight)),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text('How do teams join?',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)))
                ]),
                const SizedBox(height: 16),
                const Chip(
                    label: Text('eSports'),
                    avatar: Icon(Icons.sports_esports_rounded, size: 17),
                    backgroundColor: AppColors.surfaceRaised),
                const SizedBox(height: 8),
                _JoinOption(
                    title: 'Open registration',
                    detail: 'Let teams register for this tournament.',
                    badge: 'NEW',
                    icon: Icons.public_rounded,
                    onTap: () => Navigator.pop(context, true)),
                const SizedBox(height: 10),
                _JoinOption(
                    title: 'Manual',
                    detail: 'Enter team names yourself.',
                    icon: Icons.edit_note_rounded,
                    onTap: () => Navigator.pop(context, false)),
              ]),
        ),
      );
}

class _JoinOption extends StatelessWidget {
  const _JoinOption(
      {required this.title,
      required this.detail,
      required this.icon,
      required this.onTap,
      this.badge});
  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(children: [
                  Icon(icon, color: AppColors.accentLight),
                  const SizedBox(width: 13),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Text(title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Text(badge!,
                                style: const TextStyle(
                                    color: AppColors.mint,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800))
                          ]
                        ]),
                        const SizedBox(height: 4),
                        Text(detail,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12))
                      ])),
                  const Icon(Icons.arrow_forward_rounded, size: 18)
                ]))),
      );
}
