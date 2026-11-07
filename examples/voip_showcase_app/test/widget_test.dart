import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voip_showcase_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'VoipShowcaseApp renders workbench, triggers incoming calls, answers, and ends call',
    (WidgetTester tester) async {
      const channel = MethodChannel('dev.flutter.telecom/voip_call_engine');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initializeAndDrainColdStartBuffer':
            return <Map<String, Object?>>[];
          case 'getAudioRouteState':
            return <String, Object?>{
              'activeRoute': 'earpiece',
              'availableRoutes': <String>[
                'earpiece',
                'speaker',
                'bluetooth',
                'wiredHeadset',
              ],
              'isAudioSessionActive': false,
              'isMicrophoneMuted': false,
            };
          default:
            return null;
        }
      });

      await tester.pumpWidget(const VoipShowcaseApp());
      await tester.pumpAndSettle();

      expect(
        find.text('VoIP Call Lifecycle & Audio Workbench'),
        findsOneWidget,
      );
      expect(find.text('Incoming Call #1'), findsOneWidget);

      // Tap Incoming Call #1
      await tester.tap(find.text('Incoming Call #1'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Alice Yılmaz (Line 1) — INCOMINGRINGING'),
        findsOneWidget,
      );

      // Scroll to and tap Answer button on the ringing call
      final answerBtn = find.byTooltip('Answer & Connect Media');
      await tester.ensureVisible(answerBtn);
      await tester.pumpAndSettle();
      await tester.tap(answerBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Alice Yılmaz (Line 1) — CONNECTING'),
        findsOneWidget,
      );

      // Scroll to and tap End Call button
      final endBtn = find.byTooltip('End Call');
      await tester.ensureVisible(endBtn);
      await tester.pumpAndSettle();
      await tester.tap(endBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('No active calls. Trigger an incoming or outgoing call above.'),
        findsOneWidget,
      );
    },
  );
}
