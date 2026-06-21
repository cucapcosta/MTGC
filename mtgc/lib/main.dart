import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'pages/auth_gate.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

/// Lets scrollables (e.g. the booster carousel) be dragged with mouse and
/// trackpad too, not just touch. Flutter excludes those by default on desktop.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTG Collector',
      theme: buildAppTheme(),
      scrollBehavior: const AppScrollBehavior(),
      home: const AuthGate(),
    );
  }
}
