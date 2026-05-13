import 'package:carreras_antoine/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens the main operations sections', (tester) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(const CarrerasAntoineApp());
    await tester.pumpAndSettle();

    expect(find.text('Daily operations'), findsOneWidget);

    await tester.tap(find.text('Workflows'));
    await tester.pumpAndSettle();
    expect(find.text('Operational records'), findsOneWidget);

    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    expect(find.text('Team and assets'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings and privacy'), findsOneWidget);
    expect(find.text(supportEmail), findsOneWidget);
  });

  testWidgets('creates a procurement request locally', (tester) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(const CarrerasAntoineApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('record_title_field')),
      'Replace loading straps',
    );
    await tester.enterText(
      find.byKey(const Key('record_owner_field')),
      'Ops desk',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Main yard');

    await tester.ensureVisible(find.byKey(const Key('save_record_button')));
    await tester.tap(find.byKey(const Key('save_record_button')));
    await tester.pumpAndSettle();

    expect(find.text('Operational records'), findsOneWidget);
    expect(find.text('Replace loading straps'), findsOneWidget);
  });
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
  });
}
