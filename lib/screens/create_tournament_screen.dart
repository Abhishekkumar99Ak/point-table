import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _tourneyNameController = TextEditingController();
  bool isRoundRobin = false;
  String selectedGame = 'BGMI'; // BGMI या Free Fire

  // टीम जोड़ने के लिए स्टेट
  bool showTeamStep = false;
  late TabController _tabController;
  final TextEditingController _teamNameController = TextEditingController();
  int currentSlot = 1;
  int playerCount = 4;
  List<Map<String, dynamic>> enteredTeams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tourneyNameController.dispose();
    _teamNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          // 1. हेडर ग्रेडिएंट
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 16, right: 20, bottom: 28),
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (showTeamStep) {
                      setState(() => showTeamStep = false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Let's",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      showTeamStep ? 'Add Teams' : 'Create tourney',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. सफ़ेद कंटेनर बॉडी
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: showTeamStep ? _buildTeamsView() : _buildCreateTourneyView(),
            ),
          ),
        ],
      ),
    );
  }

  // व्यू 1: टूर्नामेंट नाम और पॉइंट सिस्टम सेट करना
  Widget _buildCreateTourneyView() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        // टूर्नामेंट नाम इनपुट
        TextField(
          controller: _tourneyNameController,
          decoration: InputDecoration(
            hintText: 'Enter Tourney Name',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // पॉइंट सिस्टम बटन
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showPointSystemBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEADADA)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppTheme.primaryMaroon, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Point system ($selectedGame)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Round Robin टॉगल
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF7F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEADADA)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Round Robin',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              ),
              Switch(
                value: isRoundRobin,
                activeColor: AppTheme.primaryMaroon,
                onChanged: (val) => setState(() => isRoundRobin = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // GO बटन
        ElevatedButton(
          onPressed: () {
            if (_tourneyNameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter tournament name')),
              );
              return;
            }
            _showHowTeamsJoinBottomSheet(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryMaroon,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GO',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // बॉटम शीट 1: How do teams join?
  void _showHowTeamsJoinBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'How do teams join?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: AppTheme.softPinkChip, shape: BoxShape.circle),
                child: const Icon(Icons.link, color: AppTheme.primaryMaroon),
              ),
              title: const Text('Open registration (via link)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Players register their own team details', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => showTeamStep = true);
              },
            ),
            const Divider(color: AppTheme.dividerLine),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: AppTheme.softPinkChip, shape: BoxShape.circle),