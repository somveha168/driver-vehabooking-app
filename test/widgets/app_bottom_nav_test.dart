import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/core/widgets/app_bottom_nav.dart';

void main() {
  const items = [
    AppNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    AppNavItem(icon: Icons.event_note_outlined, selectedIcon: Icons.event_note, label: 'Booking'),
    AppNavItem(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'Guide'),
    AppNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  testWidgets('renders all destinations and reports taps', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: 0,
            onTap: (i) => tapped = i,
            items: items,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Guide'));
    expect(tapped, 2);
  });

  testWidgets('shows the selected icon for the active destination', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: (_) {}, items: items),
        ),
      ),
    );

    expect(find.byIcon(Icons.home), findsOneWidget); // active = filled
    expect(find.byIcon(Icons.event_note_outlined), findsOneWidget); // inactive = outline
  });
}
