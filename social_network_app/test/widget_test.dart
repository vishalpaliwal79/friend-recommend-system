import 'package:flutter_test/flutter_test.dart';
import 'package:social_network_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SocialNetworkApp());

    // Verify that our app starts
    expect(find.text('Friend Recommendation System'), findsOneWidget);
  });
}
