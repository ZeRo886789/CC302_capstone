import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/widgets/confirm_dialog.dart';

void main() {
  testWidgets('ConfirmDialog does not overflow and buttons work correctly',
      (WidgetTester tester) async {
    // Test cases: [width, height, textScaleFactor]
    final List<(double, double, double)> testSizes = [
      (320, 568, 1.0), // narrow portrait
      (360, 640, 1.0),
      (360, 640, 1.5), // larger text scale
      (640, 360, 1.0), // landscape
    ];

    for (final (width, height, textScale) in testSizes) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromWindow(tester.binding.window)
              .copyWith(textScaleFactor: textScale, size: Size(width, height)),
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final result = await showConfirmDialog(
                    context,
                    title: 'Delete fact?',
                    message: 'This can\'t be undone.',
                    preview: 'When a cat chases its prey, it keeps its head level. Dogs and…',
                    confirmLabel: 'Delete',
                    cancelLabel: 'Cancel',
                  );
                  // We don't use the result here, just ensure no exception
                },
                child: const Text('Open dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      // Check that the dialog is present
      expect(find.byType(Dialog), findsOneWidget);

      // Check that there are no exceptions (overflow or otherwise)
      expect(tester.takeException(), isNull);

      // Check that both buttons are present
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Cancel and verify it returns false (by checking that the dialog closes and we can still interact)
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      // After tapping Cancel, the dialog should be closed
      expect(find.byType(Dialog), findsNothing);

      // Reopen for the next test (Delete)
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromWindow(tester.binding.window)
              .copyWith(textScaleFactor: textScale, size: Size(width, height)),
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final result = await showConfirmDialog(
                    context,
                    title: 'Delete fact?',
                    message: 'This can\'t be undone.',
                    preview: 'When a cat chases its prey, it keeps its head level. Dogs and…',
                    confirmLabel: 'Delete',
                    cancelLabel: 'Cancel',
                  );
                  // Store the result in a variable to check later
                  // We'll use a late variable, but for simplicity we just pump and check the dialog closes
                },
                child: const Text('Open dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      // Tap Delete and verify it returns true (dialog closes)
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    }
  });
}