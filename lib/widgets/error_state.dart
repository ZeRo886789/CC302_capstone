import 'package:flutter/material.dart';

import '../widgets/arcade_panel.dart';
import '../widgets/pixel_text.dart';

/// A widget displaying an error state with a message and a retry button.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ArcadePanel(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelText('Error: $message', height: 12, color: Colors.red),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.yellow,
                    side: const BorderSide(color: Colors.yellow, width: 2),
                  ),
                  child: const PixelText(
                    'RETRY',
                    height: 12,
                    color: Colors.yellow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
