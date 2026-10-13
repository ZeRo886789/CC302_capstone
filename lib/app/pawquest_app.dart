import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../screens/main_menu.dart';

class PawQuestApp extends StatelessWidget {
  const PawQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: GameColors.background,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GameColors.background,
      ),
      home: const MainMenuScreen(),
    );
  }
}
