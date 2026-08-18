import 'package:flutter/material.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'home_screen.dart';
import 'settings_service.dart';

void main() {
  tzdata.initializeTimeZones();
  runApp(const CalscanApp());
}

class CalscanApp extends StatefulWidget {
  const CalscanApp({super.key});

  @override
  State<CalscanApp> createState() => _CalscanAppState();
}

class _CalscanAppState extends State<CalscanApp> {
  final _settingsService = SettingsService();
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await _settingsService.getThemeMode();
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    await _settingsService.setThemeMode(mode);
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalScan',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: HomeScreen(
        currentThemeMode: _themeMode,
        onThemeModeChanged: _updateThemeMode,
      ),
    );
  }
}
