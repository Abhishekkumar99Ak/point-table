import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'create_tournament_screen.dart';
import 'scoreboard_screen.dart';
import 'poster_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // टूर्नामेंट कार्ड एक्सपैंड रखने के लिए इंडेक्स (शुरुआत में पहला खुला रख सकते हैं)
  int? expandedIndex = 0;

  // टूर्नामेंट्स लिस्ट
  List<Map<String, dynamic>> tournaments = [
    {
      'id': '01',
      'name': '6pm',
      'teamsCount': 12,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Pointcalc हेडर ग्रेडिएंट
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 32),
                decoration: const BoxDecoration(
                  gradient: AppTheme.headerGradient,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pointcalc',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 26,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // प्रोफाइल एवटार
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'A',
                        style: TextStyle(
                          color: AppTheme.primaryMaroon,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. सफ़ेद राउंडेड बॉडी कंटेनर
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    children: [
                      // Quick Actions हेडिंग
                      const Row(
                        children: [
                          Text('| ', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(
                            'Quick Actions',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 4 सर्कुलर बटन्स
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickActionItem(Icons.style_outlined, 'Create\nTeam card'),
                          _buildQuickActionItem(Icons.download_outlined, 'Import\nTourney'),
                          _buildQuickActionItem(Icons.badge_outlined, 'Import\nTeam card'),
                          _buildQuickActionItem(Icons.merge_type, 'Merge\nTourney'),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // All Tournaments हेडिंग
                      const Row(
                        children: [
                          Text('| ', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(
                            'All Tournaments',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // टूर्नामेंट्स लिस्ट (Accordion)
                      if (tournaments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No tournaments yet. Click + Create below.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      else
                        ...List.generate(tournaments.length, (index) {
                          final item = tournaments[index];
                          final isExpanded = expandedIndex == index;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF7F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF0E4E4)),
                            ),
                            child: Column(
                              children: [
                                // मुख्य रो (टैप करने पर एक्सपैंड होता है)
                                InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      expandedIndex = isExpanded ? null : index;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        // स्लॉट बैज 01
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.softPinkChip,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            item['id'] ?? '01',
                                            style: const TextStyle(
                                              color: AppTheme.primaryMaroon,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // टूर्नामेंट नाम और टीम्स काउंट
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'] ?? 'Tournament',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Total teams: ${item['teamsCount'] ?? 12}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // डिलीट आइकन
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.deleteRed, size: 22),
                                          onPressed: () {
                                            setState(() {
                                              tournaments.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // एक्सपैंड होने पर दिखने वाले 8 पिल बटन्स
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 14, top: 4),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildPillButton(
                                          label: 'Calculate',
                                          isOutlined: true,
                                          onTap: () => _showSetupCalculateDialog(context, item['name']),
                                        ),
                                        _buildPillButton(
                                          label: 'Tables',
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const PosterEditorScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        _buildPillButton(label: 'Warheads', onTap: () {}),
                                        _buildPillButton(label: 'Fraggers', onTap: () {}),
                                        _buildPillButton(label: 'Team poster', onTap: () {}),
                                        _buildPillButton(label: 'Slot list', onTap: () {}),
                                        _buildPillButton(label: 'Certificate', onTap: () {}),
                                        _buildSoftPillButton(icon: Icons.share_outlined, label: 'Share', onTap: () {}),
                                        _buildSoftPillButton(icon: Icons.edit_outlined, label: 'Edit', onTap: () {}),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 90), // नीचे फ्लोटिंग बटन के लिए जगह
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. नीचे दाईं तरफ फ्लोटिंग बटन्स (... और + Create)
          Positioned(
            bottom: 24,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 3 डॉट्स स्पीड डायल बटन
                GestureDetector(
                  onTap: () => _showSpeedDialBottomSheet(context),
                  child: Container(
                    width: 50,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.softPinkChip,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon)),
                  ),
                ),
                const SizedBox(height: 10),
                // + Create बटन (सीधे CreateTournamentScreen पर जाता है, बिना पासवर्ड के)
                ElevatedButton.icon(
                  onPressed: () async {
                    final newTourney = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateTournamentScreen(),
                      ),
                    );
                    if (newTourney != null && newTourney is Map<String, dynamic>) {
                      setState(() {
                        tournaments.add(newTourney);
                      });
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // क्विक एक्शन बटन विजेट
  Widget _buildQuickActionItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppTheme.softPinkChip,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryMaroon, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppTheme.textDark, height: 1.2),
        ),
      ],
    );
  }

  // मैरून पिल बटन
  Widget _buildPillButton({required String label, bool isOutlined = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : AppTheme.primaryMaroon,
          borderRadius: BorderRadius.circular(20),
          border: isOutlined ? Border.all(color: AppTheme.primaryMaroon) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isOutlined ? AppTheme.primaryMaroon : Colors.white,
          ),
        ),
      ),
    );
  }

  // सॉफ्ट पिंक शेयर / एडिट बटन
  Widget _buildSoftPillButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.softPinkChip,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryMaroon),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
            ),
          ],
        ),
      ),
    );
  }

  // 3-डॉट्स स्पीड डायल बॉटम शीट
  void _showSpeedDialBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.backup_outlined, color: AppTheme.primaryMaroon),
              title: const Text('Backup & Restore'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined, color: AppTheme.primaryMaroon),
              title: const Text('Import custom design'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined, color: AppTheme.primaryMaroon),
              title: const Text('Tournament from Excel/CSV'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // सेटअप कैलकुलेट डायलॉग (Setup calculate)
  void _showSetupCalculateDialog(BuildContext context, String? tourneyName) {
    int positionOption = 0; // 0 = Auto increment, 1 = Auto decrement
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFFDFBFB),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.settings_outlined, color: Colors.brown.shade400, size: 24),
                      const SizedBox(height: 6),
                      const Text('Setup calculate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: '1'),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Match number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Multiplier',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: const Text('1'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use the multiplier to increase the points for this match. For example, a multiplier of 2 doubles the points.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Change position by', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      RadioListTile<int>(
                        value: 0,
                        groupValue: positionOption,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.primaryMaroon,
                        title: const Text('Auto increment', style: TextStyle(fontSize: 13)),
                        onChanged: (val) => setDialogState(() => positionOption = val!),
                      ),
                      RadioListTile<int>(
                        value: 1,
                        groupValue: positionOption,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.primaryMaroon,
                        title: const Text('Auto decrement', style: TextStyle(fontSize: 13)),
                        onChanged: (val) => setDialogState(() => positionOption = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Scoreboard / AI Calculator स्क्रीन पर भेजें
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScoreboardScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}