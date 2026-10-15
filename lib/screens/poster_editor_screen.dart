import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PosterEditorScreen extends StatefulWidget {
  const PosterEditorScreen({super.key});

  @override
  State<PosterEditorScreen> createState() => _PosterEditorScreenState();
}

class _PosterEditorScreenState extends State<PosterEditorScreen> {
  int selectedTabIndex = 0; // 0 = Overall, 1 = Match 1
  int selectedThemeType = 0; // 0 = Premium, 1 = Free, 2 = Custom

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141416), // ओरिजिनल डार्क लुक स्टैंडिंग्स टेबल के लिए
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Standing tables',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // 1. सर्च बार
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22242A),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                      Icon(Icons.info_outline, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. कस्टमाइज़ेशन पिल्स (Color, Background, More)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolPill(Icons.palette_outlined, 'Color'),
                    _buildToolPill(Icons.image_outlined, 'Background'),
                    _buildToolPill(Icons.settings_outlined, 'More'),
                  ],
                ),
                const SizedBox(height: 18),

                // 3. पोस्टर लाइव प्रीव्यू कार्ड (ग्रीन/ब्लैक स्क्रिम्स थीम)
                Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E599), // ब्राइट नियॉन ग्रीन बॉर्डर बैकग्राउंड
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E599).withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1014),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'SCRIMS',
                            style: TextStyle(
                              color: Color(0xFF00E599),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            color: Colors.white,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('RANK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                                Text('TEAM NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                                Text('WWCD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                                Text('PTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _tableRow('#1', 'TEAM SOUL', '2', '45'),
                          _tableRow('#2', 'GODLIKE', '1', '38'),
                          _tableRow('#3', 'TX ESPORTS', '1', '32'),
                          _tableRow('#4', 'REVENANT', '0', '26'),
                          _tableRow('#5', 'HYDRA', '0', '22'),
                          const SizedBox(height: 10),
                          const Text(
                            'POINTCALC STANDINGS',
                            style: TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. टैब्स (Overall standings vs Match 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStandingsTab(0, '✓ Overall standings'),
                    const SizedBox(width: 10),
                    _buildStandingsTab(1, 'Match 1'),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. रेडियो ऑप्शंस (Premium, Free, Custom)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRadioOption(0, 'Premium'),
                    const SizedBox(width: 12),
                    _buildRadioOption(1, 'Free'),
                    const SizedBox(width: 12),
                    _buildRadioOption(2, 'Custom'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 6. बॉटम डाउनलोड & शेयर बार
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1B1D22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Poster downloaded to gallery!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8DBFF), // सॉफ्ट पर्पल/व्हाइट बटन
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Download',
                      style: TextStyle(
                        color: Color(0xFF2C194D),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F36),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing standings poster...')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // विजेट्स
  Widget _buildToolPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF22242A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStandingsTab(int index, String title) {
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF332635) : const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF9E4B6C) : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(int value, String title) {
    final isSelected = selectedThemeType == value;
    return GestureDetector(
      onTap: () => setState(() => selectedThemeType = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? const Color(0xFFB57EDC) : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tableRow(String rank, String team, String wwcd, String pts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rank, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(team, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
          Text(wwcd, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(pts, style: const TextStyle(color: Color(0xFF00E599), fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}