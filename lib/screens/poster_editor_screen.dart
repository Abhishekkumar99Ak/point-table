import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pointcalc_models.dart';
import '../services/admin_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class PosterEditorScreen extends StatefulWidget {
  const PosterEditorScreen(
      {super.key, required this.tournament, this.mode = 'Team poster'});

  final Tournament tournament;
  final String mode;

  @override
  State<PosterEditorScreen> createState() => _PosterEditorScreenState();
}

class _PosterEditorScreenState extends State<PosterEditorScreen> {
  final _capture = ScreenshotController();
  final _searchController = TextEditingController();
  final _picker = ImagePicker();
  String _game = '';
  late String _mode = widget.mode;
  String _style = 'Premium';
  String _query = '';
  String _organiser = 'Organiser Name';
  String _event = '';
  String _week = 'Week 00';
  String _instagram = '@instagram';
  String _youtube = 'YouTube channel';
  String _whatsapp = 'WhatsApp group';
  int _palette = 0;
  double _hue = 0;
  double _saturation = 1;
  double _brightness = 1;
  double _contrast = 1;
  String? _backgroundPath;
  int _selectedMatch = 0;
  bool _sortByKills = false;
  bool _busy = false;

  static const _games = [
    'Free Fire',
    'BGMI',
    'PUBG',
    'Call Of Duty',
    'Valorant',
    'Apex Legends',
    'Custom',
  ];
  static const _palettes = [
    [Color(0xFF112936), Color(0xFF05151C), Color(0xFF37C8DB)],
    [Color(0xFF2C2B19), Color(0xFF11140D), Color(0xFFD1C064)],
    [Color(0xFF281938), Color(0xFF100B1D), Color(0xFFCC83FF)],
    [Color(0xFF3A1C20), Color(0xFF170A14), Color(0xFFFF7A57)],
  ];

  @override
  void initState() {
    super.initState();
    _game = _gameLabel(widget.tournament.pointSystem.game);
    _event = widget.tournament.name;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color get _accent => _adjustedColors[2];
  List<Color> get _adjustedColors => _palettes[_palette].map((color) {
        final hsl = HSLColor.fromColor(color);
        final lightness =
            (0.5 + ((hsl.lightness * _brightness) - 0.5) * _contrast)
                .clamp(0.0, 1.0);
        return hsl
            .withHue((hsl.hue + _hue + 360) % 360)
            .withSaturation((hsl.saturation * _saturation).clamp(0.0, 1.0))
            .withLightness(lightness)
            .toColor();
      }).toList();

  List<ScoreEntry> get _filteredStandings {
    final query = _query.trim().toLowerCase();
    var rows = List<ScoreEntry>.of(widget.tournament.standings.where(
        (entry) => _selectedMatch == 0 || entry.matchNumber == _selectedMatch));
    if (_sortByKills || _mode == 'Fraggers' || _mode == 'Warheads') {
      rows.sort((a, b) => b.kills.compareTo(a.kills));
    } else {
      rows.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    }
    if (_mode == 'Warheads') rows = rows.take(3).toList();
    if (query.isNotEmpty)
      rows = rows
          .where((row) => row.teamName.toLowerCase().contains(query))
          .toList();
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded)),
        title: Text(_mode, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
              tooltip: 'Edit poster text',
              onPressed: _editDetails,
              icon: const Icon(Icons.tune_rounded)),
          const SizedBox(width: 6),
        ],
      ),
      child: Column(children: [
        _filterChips(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Screenshot(
                  controller: _capture,
                  child: RepaintBoundary(
                    child: _PosterCanvas(
                      tournament: widget.tournament,
                      mode: _mode,
                      rows: _filteredStandings,
                      game: _game,
                      organiser: _organiser,
                      event: _event,
                      week: _week,
                      instagram: _instagram,
                      youtube: _youtube,
                      whatsapp: _whatsapp,
                      colors: _adjustedColors,
                      backgroundPath: _backgroundPath,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _styleAndActions(),
      ]),
    );
  }

  Widget _filterChips() => SizedBox(
        height: 59,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _FilterChip(
                icon: Icons.search_rounded,
                title: 'Search',
                onTap: _searchTeams),
            _FilterChip(
                icon: Icons.palette_outlined,
                title: 'Color',
                onTap: _chooseColor),
            _FilterChip(
                icon: Icons.wallpaper_outlined,
                title: 'Background',
                onTap: _chooseBackground),
            _FilterChip(
                icon: Icons.filter_list_rounded,
                title: 'Match',
                onTap: _chooseMatch),
            _FilterChip(
                icon: Icons.sort_rounded,
                title: _sortByKills ? 'Sort: Kills' : 'Sort: Points',
                onTap: () => setState(() => _sortByKills = !_sortByKills)),
            _FilterChip(
                icon: Icons.sports_esports_outlined,
                title: 'Game logo',
                onTap: _chooseGame),
            _FilterChip(
                icon: Icons.dashboard_customize_outlined,
                title: 'Poster type',
                onTap: _chooseMode),
          ],
        ),
      );

  Widget _styleAndActions() => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.96),
            border: const Border(top: BorderSide(color: AppColors.outline))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('TEMPLATE',
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const Spacer(),
            for (final style in ['Premium', 'Free', 'Custom'])
              Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                      label: Text(style),
                      selected: _style == style,
                      onSelected: (_) => setState(() => _style = style),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selectedColor: _accent.withValues(alpha: 0.2),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                          color: _style == style ? _accent : AppColors.outline),
                      labelStyle: TextStyle(
                          fontSize: 11,
                          color: _style == style ? _accent : AppColors.text,
                          fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                        onPressed: _busy ? null : _download,
                        icon: _busy
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.download_rounded),
                        label: Text(_busy ? 'Saving...' : 'Download'),
                        style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w800))))),
            const SizedBox(width: 10),
            SizedBox(
                width: 52,
                height: 52,
                child: IconButton.filled(
                    tooltip: 'Share poster',
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.ios_share_rounded),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceRaised,
                        foregroundColor: _accent,
                        side: BorderSide(
                            color: _accent.withValues(alpha: 0.5))))),
          ]),
        ]),
      );

  Future<void> _searchTeams() async {
    _searchController.text = _query;
    final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Search teams'),
                content: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Team name')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context, _searchController.text),
                      child: const Text('Apply'))
                ]));
    if (result != null) setState(() => _query = result);
  }

  Future<void> _chooseColor() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
                  child: SingleChildScrollView(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Poster color',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 15),
                      Wrap(
                          spacing: 12,
                          children: List.generate(
                              _palettes.length,
                              (index) => InkWell(
                                    onTap: () {
                                      setState(() => _palette = index);
                                      setSheetState(() {});
                                    },
                                    child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _palettes[index][0],
                                            border: Border.all(
                                                color: _palettes[index][2],
                                                width: 2)),
                                        child: _palette == index
                                            ? Icon(Icons.check_rounded,
                                                color: _adjustedColors[2])
                                            : null),
                                  ))),
                      _colorSlider('Hue', _hue, -180, 180, (value) {
                        _hue = value;
                        setState(() {});
                        setSheetState(() {});
                      }, valueLabel: '${_hue.round()}°'),
                      _colorSlider('Saturation', _saturation, 0, 2, (value) {
                        _saturation = value;
                        setState(() {});
                        setSheetState(() {});
                      }, valueLabel: '${(_saturation * 100).round()}%'),
                      _colorSlider('Brightness', _brightness, 0.4, 1.6,
                          (value) {
                        _brightness = value;
                        setState(() {});
                        setSheetState(() {});
                      }, valueLabel: '${(_brightness * 100).round()}%'),
                      _colorSlider('Contrast', _contrast, 0.5, 1.5, (value) {
                        _contrast = value;
                        setState(() {});
                        setSheetState(() {});
                      }, valueLabel: '${(_contrast * 100).round()}%'),
                    ],
                  )),
                ),
              )),
    );
  }

  Widget _colorSlider(String label, double value, double min, double max,
          ValueChanged<double> onChanged,
          {required String valueLabel}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(valueLabel,
                style: const TextStyle(color: AppColors.muted, fontSize: 11))
          ]),
          Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged),
        ],
      );

  Future<void> _chooseBackground() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (image != null && mounted) setState(() => _backgroundPath = image.path);
  }

  Future<void> _chooseMatch() async {
    final matches = widget.tournament.standings
        .map((entry) => entry.matchNumber)
        .toSet()
        .toList()
      ..sort();
    final selected = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: AppColors.surface,
        builder: (context) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: const Text('Overall standings'),
                  trailing: _selectedMatch == 0
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(context, 0)),
              ...matches.map((match) => ListTile(
                  title: Text('Match $match'),
                  trailing: _selectedMatch == match
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(context, match))),
            ])));
    if (selected != null) setState(() => _selectedMatch = selected);
  }

  Future<void> _chooseMode() async {
    const modes = [
      'Standing Tables',
      'Team poster',
      'Warheads',
      'Fraggers',
      'Slot list',
      'Certificate'
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: modes
                  .map((mode) => ListTile(
                      title: Text(mode),
                      trailing: _mode == mode
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.accentLight)
                          : null,
                      onTap: () => Navigator.pop(context, mode)))
                  .toList())),
    );
    if (selected != null) setState(() => _mode = selected);
  }

  Future<void> _chooseGame() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 17),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Game logo',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800))),
                const SizedBox(height: 14),
                Flexible(
                    child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.12,
                        children: _games
                            .map((game) => _GameTile(
                                game: game,
                                selected: _game == game,
                                onTap: () => Navigator.pop(context, game)))
                            .toList())),
              ]))),
    );
    if (selected != null) {
      setState(() {
        _game = selected;
        if (selected == 'Free Fire') _palette = 0;
        if (['BGMI', 'PUBG'].contains(selected)) _palette = 1;
      });
    }
  }

  Future<void> _editDetails() async {
    final controllers = [
      TextEditingController(text: _organiser),
      TextEditingController(text: _event),
      TextEditingController(text: _week),
      TextEditingController(text: _instagram),
      TextEditingController(text: _youtube),
      TextEditingController(text: _whatsapp),
    ];
    final accepted = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (context) => SafeArea(
            child: Padding(
                padding: EdgeInsets.fromLTRB(
                    18, 20, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Poster details',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: controllers[0],
                      decoration:
                          const InputDecoration(labelText: 'Organiser name')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: controllers[1],
                      decoration:
                          const InputDecoration(labelText: 'Event name')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: controllers[2],
                      decoration: const InputDecoration(labelText: 'Week')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: controllers[3],
                      decoration:
                          const InputDecoration(labelText: 'Instagram')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: controllers[4],
                      decoration: const InputDecoration(labelText: 'YouTube')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: controllers[5],
                      decoration: const InputDecoration(labelText: 'WhatsApp')),
                  const SizedBox(height: 14),
                  PrimaryButton(
                      label: 'Apply details',
                      onPressed: () => Navigator.pop(context, true)),
                ]))));
    if (accepted == true && mounted) {
      setState(() {
        _organiser = controllers[0].text.trim();
        _event = controllers[1].text.trim();
        _week = controllers[2].text.trim();
        _instagram = controllers[3].text.trim();
        _youtube = controllers[4].text.trim();
        _whatsapp = controllers[5].text.trim();
      });
    }
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<Uint8List?> _renderPoster() => _capture.capture(
      pixelRatio: 3.0, delay: const Duration(milliseconds: 80));

  Future<void> _download() async {
    if (!await requireAdmin(context) || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = await _renderPoster();
      if (bytes == null)
        throw StateError('Poster image could not be rendered.');
      var hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) hasAccess = await Gal.requestAccess(toAlbum: true);
      if (!hasAccess) throw StateError('Gallery access was not granted.');
      await Gal.putImageBytes(bytes, album: 'Pointcalc');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Poster saved to your gallery.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save poster: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (!await requireAdmin(context) || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = await _renderPoster();
      if (bytes == null)
        throw StateError('Poster image could not be rendered.');
      await Share.shareXFiles([
        XFile.fromData(bytes,
            name: 'pointcalc-poster.png', mimeType: 'image/png')
      ], text: '$_event · $_game');
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not share poster: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _gameLabel(String game) => switch (game.toLowerCase()) {
        'freefire' || 'free fire' => 'Free Fire',
        'bgmi' => 'BGMI',
        'pubg' => 'PUBG',
        'cod mobile' || 'call of duty' => 'Call Of Duty',
        _ => game,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
          avatar: Icon(icon, size: 16, color: AppColors.accentLight),
          label: Text(title),
          onPressed: onTap,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.outline),
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)));
}

class _GameTile extends StatelessWidget {
  const _GameTile(
      {required this.game, required this.selected, required this.onTap});
  final String game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.16)
          : AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: selected
                          ? AppColors.accentLight
                          : AppColors.outline)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GameMark(game: game, size: 34),
                    const SizedBox(height: 8),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(game,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: selected
                                    ? AppColors.accentLight
                                    : AppColors.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w700))),
                  ]))));
}

class _PosterCanvas extends StatelessWidget {
  const _PosterCanvas(
      {required this.tournament,
      required this.mode,
      required this.rows,
      required this.game,
      required this.organiser,
      required this.event,
      required this.week,
      required this.instagram,
      required this.youtube,
      required this.whatsapp,
      required this.colors,
      required this.backgroundPath});
  final Tournament tournament;
  final String mode;
  final List<ScoreEntry> rows;
  final String game;
  final String organiser;
  final String event;
  final String week;
  final String instagram;
  final String youtube;
  final String whatsapp;
  final List<Color> colors;
  final String? backgroundPath;

  @override
  Widget build(BuildContext context) {
    final accent = colors[2];
    final backgroundImage = _PosterArtwork.backgroundFor(game);
    return AspectRatio(
      aspectRatio: 0.705,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(fit: StackFit.expand, children: [
          DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors[0], colors[1]]))),
          if (backgroundPath != null)
            Image.file(File(backgroundPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink())
          else
            Image.network(backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink()),
          DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                Colors.black.withValues(alpha: 0.62),
                Colors.black.withValues(alpha: 0.52),
                colors[1].withValues(alpha: 0.97)
              ]))),
          Positioned(
              top: -40,
              right: -45,
              child: Container(
                  width: 185,
                  height: 185,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: accent.withValues(alpha: 0.16), width: 24)))),
          Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 13),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    organiser.isEmpty
                                        ? 'ORGANISER NAME'
                                        : organiser.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: accent,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5)),
                                const SizedBox(height: 7),
                                Text(
                                    event.isEmpty
                                        ? tournament.name.toUpperCase()
                                        : event.toUpperCase(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        height: 0.98,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(
                                    '${mode.toUpperCase()}  ·  ${week.toUpperCase()}',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2)),
                              ])),
                          const SizedBox(width: 9),
                          _GameMark(game: game, size: 48),
                        ]),
                    const SizedBox(height: 13),
                    Row(children: [
                      Expanded(
                          child: _MiniLabel(
                              text: game.toUpperCase(), color: accent)),
                      const SizedBox(width: 5),
                      Expanded(
                          child: _MiniLabel(
                              text: 'OFFICIAL POINT TABLE', color: accent))
                    ]),
                    const SizedBox(height: 8),
                    Expanded(
                      child: switch (mode) {
                        'Certificate' => _certificate(accent),
                        'Slot list' || 'Team poster' => _teamSlots(accent),
                        'Warheads' => _warheads(accent),
                        _ => _standingsTable(accent),
                      },
                    ),
                    const SizedBox(height: 9),
                    Row(children: [
                      Expanded(
                          child: _Social(
                              icon: Icons.camera_alt_rounded, text: instagram)),
                      const SizedBox(width: 5),
                      Expanded(
                          child: _Social(
                              icon: Icons.play_circle_fill_rounded,
                              text: youtube)),
                      const SizedBox(width: 5),
                      Expanded(
                          child: _Social(
                              icon: Icons.chat_rounded, text: whatsapp)),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('POINTCALC',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.8)),
                          const Text('ALL TOOLS UNLOCKED',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1))
                        ]),
                  ])),
        ]),
      ),
    );
  }

  Widget _standingsTable(Color accent) {
    final maxRows = mode == 'Warheads'
        ? 3
        : mode == 'Fraggers'
            ? 4
            : 12;
    final displayRows = rows.take(maxRows).toList();
    final blankCount = (maxRows - displayRows.length).clamp(0, maxRows);
    return Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accent.withValues(alpha: 0.45))),
        child: Column(children: [
          const Row(children: [
            SizedBox(width: 25, child: Text('#', style: _tableHeader)),
            Expanded(child: Text('TEAM NAME', style: _tableHeader)),
            SizedBox(
                width: 38,
                child: Text('K',
                    textAlign: TextAlign.center, style: _tableHeader)),
            SizedBox(
                width: 45,
                child: Text('TOTAL',
                    textAlign: TextAlign.right, style: _tableHeader))
          ]),
          const Divider(height: 10, color: Colors.white24),
          ...List.generate(
              displayRows.length,
              (index) => _ScoreLine(
                  rank: index + 1, row: displayRows[index], accent: accent)),
          ...List.generate(
              blankCount,
              (index) => _EmptyScoreLine(
                  rank: displayRows.length + index + 1, accent: accent)),
        ]));
  }

  Widget _teamSlots(Color accent) => GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 2.2,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(12, (index) {
          final team = index < tournament.teams.length
              ? tournament.teams[index].name
              : 'OPEN SLOT';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withValues(alpha: 0.4))),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text((index + 1).toString().padLeft(2, '0'),
                  style: TextStyle(
                      color: accent, fontSize: 8, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(team.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w700)),
            ]),
          );
        }),
      );

  Widget _certificate(Color accent) {
    final champion = rows.isNotEmpty ? rows.first.teamName : 'Champion team';
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.4)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.workspace_premium_rounded, color: accent, size: 50),
        const SizedBox(height: 16),
        Text('CERTIFICATE OF ACHIEVEMENT',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: accent, fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        const Text('AWARDED TO',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(champion.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(
            'For outstanding performance at ${event.isEmpty ? tournament.name : event}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 26),
        Text(organiser.toUpperCase(),
            style: TextStyle(
                color: accent, fontSize: 9, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _warheads(Color accent) {
    final leaders = rows.take(3).toList();
    if (leaders.isEmpty) {
      return const Center(
          child: Text('No match results yet',
              style: TextStyle(color: Colors.white70, fontSize: 12)));
    }
    return Column(
      children: List.generate(leaders.length, (index) {
        final row = leaders[index];
        final team = tournament.teams
            .where(
                (item) => item.name.toLowerCase() == row.teamName.toLowerCase())
            .firstOrNull;
        final photoPath = team?.players
                .where((player) => player.photoPath != null)
                .firstOrNull
                ?.photoPath ??
            team?.logoPath;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: accent.withValues(alpha: index == 0 ? 0.85 : 0.4),
                    width: index == 0 ? 1.5 : 1)),
            child: Row(children: [
              Text('${index + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                      color: accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              ClipOval(
                child: SizedBox(
                  width: 43,
                  height: 43,
                  child: photoPath == null
                      ? ColoredBox(
                          color: accent.withValues(alpha: 0.18),
                          child: Center(
                              child: Text(
                                  row.teamName.characters.first.toUpperCase(),
                                  style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18))))
                      : Image.file(
                          File(photoPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => ColoredBox(
                              color: accent.withValues(alpha: 0.18),
                              child: Center(
                                  child: Icon(Icons.person_rounded,
                                      color: accent))),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(row.teamName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('${row.kills} FINISHES · ${row.totalPoints} POINTS',
                        style: TextStyle(
                            color: accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w800)),
                  ])),
              if (row.playerKills.isNotEmpty)
                Text(
                    row.playerKills
                        .reduce((a, b) => a.kills >= b.kills ? a : b)
                        .playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 8)),
            ]),
          ),
        );
      }),
    );
  }

  static const _tableHeader = TextStyle(
      color: Colors.white60,
      fontSize: 7,
      fontWeight: FontWeight.w900,
      letterSpacing: 1);
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine(
      {required this.rank, required this.row, required this.accent});
  final int rank;
  final ScoreEntry row;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.2),
      child: Row(children: [
        SizedBox(
            width: 25,
            child: Text(rank.toString().padLeft(2, '0'),
                style: TextStyle(
                    color: rank == 1 ? accent : Colors.white60,
                    fontSize: 8,
                    fontWeight: FontWeight.w900))),
        Expanded(
            child: Text(row.teamName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800))),
        SizedBox(
            width: 38,
            child: Text('${row.kills}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.w700))),
        SizedBox(
            width: 45,
            child: Text('${row.totalPoints}',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: accent, fontSize: 9, fontWeight: FontWeight.w900))),
      ]));
}

class _EmptyScoreLine extends StatelessWidget {
  const _EmptyScoreLine({required this.rank, required this.accent});
  final int rank;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.2),
      child: Row(children: [
        SizedBox(
            width: 25,
            child: Text(rank.toString().padLeft(2, '0'),
                style: TextStyle(
                    color: accent.withValues(alpha: 0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w700))),
        const Expanded(
            child: Text('SLOT AVAILABLE',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 7,
                    fontWeight: FontWeight.w600))),
        const SizedBox(
            width: 38,
            child: Text('-',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 8))),
        const SizedBox(
            width: 45,
            child: Text('-',
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white30, fontSize: 8))),
      ]));
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(5)),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5)));
}

class _Social extends StatelessWidget {
  const _Social({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: Colors.white70, size: 10),
        const SizedBox(width: 3),
        Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 6,
                    fontWeight: FontWeight.w700)))
      ]);
}

class _GameMark extends StatelessWidget {
  const _GameMark({required this.game, required this.size});
  final String game;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isFreeFire = game == 'Free Fire';
    final mark = isFreeFire
        ? 'FREE\nFIRE MAX'
        : game == 'Call Of Duty'
            ? 'CALL OF\nDUTY'
            : game.toUpperCase();
    final colors = isFreeFire
        ? const [Color(0xFFFFCF43), Color(0xFFFF5538)]
        : const [Color(0xFFEDF2DB), Color(0xFF99B069)];
    return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(size * 0.2),
            border: Border.all(color: colors.last.withValues(alpha: 0.8))),
        child: Center(
            child: ShaderMask(
                shaderCallback: (rect) =>
                    LinearGradient(colors: colors).createShader(rect),
                child: Text(mark,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.19,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.1)))));
  }
}

abstract final class _PosterArtwork {
  static const _freeFireCharacterPlaceholder =
      'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=1400&q=90';
  static const _battleRoyaleCharacterPlaceholder =
      'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=1400&q=90';

  static String backgroundFor(String game) => game == 'Free Fire'
      ? _freeFireCharacterPlaceholder
      : _battleRoyaleCharacterPlaceholder;
}
