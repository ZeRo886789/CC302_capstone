import 'package:flutter/material.dart';

import '../widgets/arcade_panel.dart';
import '../widgets/pixel_text.dart';

/// A widget displaying an empty state with a message.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ArcadePanel(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [PixelText(message, height: 12, color: Colors.white)],
          ),
        ),
      ),
    );
  }
}
