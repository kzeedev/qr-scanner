import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrscanner/ui/features/scan/views/result_screen.dart';

void main() {
  testWidgets('ResultScreen renders editable dashboard preview field and triggers callbacks', (tester) async {
    String changedText = '';
    String savedValue = '';

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          barcodeValue: 'SCANNED_123',
          currentScannedValues: 'LINE1\nLINE2',
          onContentChanged: (val) {
            changedText = val;
          },
          onSave: (val) {
            savedValue = val;
          },
          onSaveWithSeparator: (_) {},
        ),
      ),
    );

    // Verify barcode value and EDITABLE badge are displayed
    expect(find.text('SCANNED_123'), findsOneWidget);
    expect(find.text('EDITABLE'), findsOneWidget);
    expect(find.text('2 lines'), findsOneWidget);

    // Verify the TextField contains initial currentScannedValues
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.controller?.text, 'LINE1\nLINE2');

    // Edit the preview field text
    await tester.enterText(textFieldFinder, 'LINE1\nLINE2\nLINE3');
    await tester.pump();

    expect(changedText, 'LINE1\nLINE2\nLINE3');
    expect(find.text('3 lines'), findsOneWidget);

    // Tap Save button
    final saveButtonFinder = find.byTooltip('Save');
    expect(saveButtonFinder, findsOneWidget);
    await tester.tap(saveButtonFinder);
    await tester.pump();

    expect(savedValue, 'SCANNED_123');
  });

  testWidgets('ResultScreen Save with Separator triggers onSaveWithSeparator', (tester) async {
    String savedWithSepValue = '';

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          barcodeValue: 'BARCODE_XYZ',
          currentScannedValues: '',
          onSave: (_) {},
          onSaveWithSeparator: (val) {
            savedWithSepValue = val;
          },
        ),
      ),
    );

    expect(find.text('BARCODE_XYZ'), findsOneWidget);

    // Tap Save with Separator
    final saveWithSepFinder = find.byTooltip('Save with Separator');
    expect(saveWithSepFinder, findsOneWidget);
    await tester.tap(saveWithSepFinder);
    await tester.pump();

    expect(savedWithSepValue, 'BARCODE_XYZ');
  });
}
