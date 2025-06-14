// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fl_openvpn_client/main.dart';
import 'package:fl_openvpn_client/providers/vpn_provider.dart';

void main() {
  testWidgets('OpenVPN Client app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OpenVpnClientApp());

    // Wait for initialization
    await tester.pump();

    // Verify that the app loads with the initialization screen
    expect(find.text('Initializing OpenVPN Client...'), findsOneWidget);

    // Wait for the app to initialize (this will fail in test environment, but that's expected)
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('VPN Provider initialization test', (WidgetTester tester) async {
    final vpnProvider = VpnProvider();

    // Test initial state
    expect(vpnProvider.isInitialized, false);
    expect(vpnProvider.configs, isEmpty);
    expect(vpnProvider.activeConfig, isNull);
    expect(vpnProvider.isConnected, false);
    expect(vpnProvider.canConnect, false);
  });
}
