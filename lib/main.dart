import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/pointcalc_models.dart';
import 'services/admin_access_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tournaments = TournamentStore();
  final adminAccess = AdminAccessController();
  await Future.wait([tournaments.load(), adminAccess.load()]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tournaments),
        ChangeNotifierProvider.value(value: adminAccess),
      ],
      child: const PointcalcApp(),
    ),
  );
}

class PointcalcApp extends StatelessWidget {
  const PointcalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Point Table',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
