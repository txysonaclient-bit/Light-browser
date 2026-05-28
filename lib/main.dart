import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/browser_state.dart';
import 'screens/browser_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'features/ad_blocker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ad blocker
  AdBlocker().initialize();

  // Lock to portrait + landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => BrowserState(),
      child: const LightBrowserApp(),
    ),
  );
}

class LightBrowserApp extends StatelessWidget {
  const LightBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrowserState>();

    return MaterialApp(
      title: 'Light Browser',
      debugShowCheckedModeBanner: false,
      theme: LightTheme.light(),
      darkTheme: LightTheme.dark(),
      themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const BrowserScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
