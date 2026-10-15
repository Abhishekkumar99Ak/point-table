import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'poster_editor_screen.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  final ImagePicker _picker = ImagePicker();

  // अपलोड की गई इमेजेस
  List<XFile> lobbyImages = [];
  List<XFile> resultImages = [];

  bool rememberLobby = false;

  // फेज़ 1: AI अपलोड स्क्रीन, फेज़ 2: Search Any स्क्रीन
  bool isReviewPhase = false;
  int currentImageIndex = 0;

  // डमी डिटेक्टेड स्लॉट्स
  List<Map<String, dynamic>> detectedSlots = [
    {'slot': 'Slot 01', 'name': 'RC MAGNETO', 'kills': 4, 'pos': 1},
    {'slot': 'Slot 02', 'name': 'AGP KRISH', 'kills': 2, 'pos': 2},
    {'slot': 'Slot 03', 'name': 'V4', 'kills': 16, 'pos': 3},
  ];

  // 1. मल्टी-इमेज पिकर लॉबी के लिए
  Future<void> _pickLobbyImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        lobbyImages = images;
      });
    }
  }

  // 2. मल्टी-इमेज पिकर रिजल्ट स्कोरबोर्ड्स के लिए
  Future<void> _pickResultImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        resultImages = images;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: isReviewPhase ? _buildSearchAnyView() : _buildPointcalcAIView(),
    );
  }

  // ==========================================
  // VIEW 1: POINTCALC AI UPLOAD SCREEN
  // ==========================================
  Widget _buildPointcalcAIView() {
    return Column(
      children: [
        // हेडर ग्रेडिएंट
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 28),
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Pointcalc AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48), // बैलेंस के लिए
            ],
          ),
        ),

        // बॉडी कंटेनर
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // YouTube बैनर
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4F4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0DDDD)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.play_circle_fill, color: AppTheme.primaryMaroon, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'New to PointCalc AI? Tap to watch a quick tutorial on YouTube.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 1. STEP 1: Lobby Screenshots Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEFE8E8)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppTheme.softPinkChip,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text('1', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Lobby Screenshots',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Make sure the screenshot is taken when all players are alive for the best accuracy',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 14),

                      // स्लॉट कार्ड्स (Horizontal Scroll)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: detectedSlots.length + 1,
                          itemBuilder: (ctx, idx) {
                            if (idx == detectedSlots.length) {
                              return GestureDetector(
                                onTap: _pickLobbyImages,
                                child: Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F6F6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryMaroon, size: 26),
                                      SizedBox(height: 4),
                                      Text('Add Lobby\n(Multi)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppTheme.textDark)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final slot = detectedSlots[idx];
                            return Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E222A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      slot['name'],
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(slot['slot'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppTheme.softPinkChip, borderRadius: BorderRadius.circular(6)),
                                          child: const Text('Update', style: TextStyle(fontSize: 9, color: AppTheme.primaryMaroon)),
                                        ),
                                        const Icon(Icons.delete_outline, size: 16, color: AppTheme.deleteRed),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Remember lobby row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remember lobby', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                    Switch(
                      value: rememberLobby,
                      activeColor: AppTheme.primaryMaroon,
                      onChanged: (val) {
                        setState(() => rememberLobby = val);
                        if (val) {
                          _showRememberLobbyBottomSheet(context);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. STEP 2: Result Screenshots Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEFE8E8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: AppTheme.softPinkChip, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Text('2', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          const Text('Result Screenshots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Make sure the screenshot is taken without any overlays, and confirm that the kill count is accurate.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 14),

                      // टीम रो प्रीव्यू (V4 आदि)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFFDF8F8), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.softPinkChip, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('03', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                                const SizedBox(width: 10),
                                const Text('V4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.softPinkChip, borderRadius: BorderRadius.circular(8)),
                              child: const Text('16 pts', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Upload all screenshots बटन
                      OutlinedButton.icon(
                        onPressed: _pickResultImages,
                        icon: const Icon(Icons.arrow_upward, color: AppTheme.primaryMaroon, size: 18),
                        label: Text(
                          resultImages.isEmpty ? 'Upload all screenshots' : '${resultImages.length} Screenshots Selected',
                          style: const TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: Color(0xFFDABABA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Complete बटन (यह सीधे रिव्यू और सेव फ्लो पर ले जाता है)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isReviewPhase = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMaroon,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Important Notes
                const Text('Important Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                _bulletNote('Screenshots must be clear and unedited.'),
                _bulletNote('Avoid overlays (chat bubble, volume control, status bar etc.).'),
                _bulletNote('Upload full screenshots, not cropped parts.'),
                _bulletNote('The game language should be set to English.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: SEARCH ANY & REVIEW SCREEN
  // ==========================================
  Widget _buildSearchAnyView() {
    return Column(
      children: [
        // हेडर ग्रेडिएंट
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => isReviewPhase = false),
                  ),
                  const Text('Search Any', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _headerPill(Icons.auto_awesome, 'Try AI'),
                  const SizedBox(width: 8),
                  _headerPill(Icons.computer, 'Use PC'),
                ],
              ),
            ],
          ),
        ),

        // बॉडी
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // नेविगेशन बार और Save
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          onPressed: () {
                            if (currentImageIndex > 0) setState(() => currentImageIndex--);
                          },
                        ),
                        const Icon(Icons.image_outlined, color: AppTheme.primaryMaroon),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () {
                            if (currentImageIndex < detectedSlots.length - 1) setState(() => currentImageIndex++);
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.undo, size: 16, color: AppTheme.primaryMaroon),
                          label: const Text('UNDO', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showSaveAllDialog(context),
                          icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                          label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // स्क्रीनशॉट प्रीव्यू एरिया
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EFEF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 54, color: Colors.blue.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'Detected: ${detectedSlots[currentImageIndex]['name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Kills & Position
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: '${detectedSlots[currentImageIndex]['kills']}'),
                        decoration: InputDecoration(
                          labelText: 'Kills',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Position',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${detectedSlots[currentImageIndex]['pos']}'),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DIALOGS & BOTTOM SHEETS
  // ==========================================

  // 1. Remember this lobby बॉटम शीट
  void _showRememberLobbyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: const Color(0xFFFFF7F7),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: AppTheme.softPinkChip, shape: BoxShape.circle),
                child: const Icon(Icons.bookmark, color: AppTheme.primaryMaroon, size: 26),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('Remember this lobby', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ),
            const Center(
              child: Text('12 slots, reused for the next matches', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ),
            const SizedBox(height: 16),

            // स्पार्कल इन्फो कार्ड
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.primaryMaroon, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'When you press Complete, this lobby is saved for the tournament. For the next matches just upload result screenshots.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // वॉर्निंग कार्ड
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFDF0F0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF7D6D6))),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.deleteRed, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use with care: If a team substitutes or renames players, upload fresh screenshots.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE0C4C4)),
                    ),
                    child: const Text('Not now', style: TextStyle(color: AppTheme.primaryMaroon)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('✓ Turn on', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. Save All कन्फर्मेशन डायलॉग
  void _showSaveAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Save All', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to save all changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // डायलॉग बंद
              // सीधे स्टैंडिंग्स पोस्टर स्क्रीन पर जाएँ
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PosterEditorScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon),
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // हेल्पर्स
  static Widget _bulletNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppTheme.primaryMaroon),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
        ],
      ),
    );
  }

  static Widget _headerPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}