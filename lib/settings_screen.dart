import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'calendar_service.dart';
import 'settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final Future<void> Function(ThemeMode) onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.initialThemeMode,
    required this.onThemeModeChanged,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _calendarService = CalendarService();
  final _settingsService = SettingsService();
  List<Calendar> _calendars = [];
  String? _selectedCalendarId;
  int _durationMinutes = 60;
  late ThemeMode _themeMode;
  static const _durationOptions = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _load();
  }

  Future<void> _load() async {
    final calendars = await _calendarService.getCalendars();
    final savedId = await _settingsService.getDefaultCalendarId();
    final duration = await _settingsService.getDefaultDurationMinutes();
    if (!mounted) return;
    setState(() {
      _calendars = calendars;
      _selectedCalendarId =
          savedId ?? (calendars.isNotEmpty ? calendars.first.id : null);
      _durationMinutes = duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Default Calendar'),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCalendarId,
                  items: _calendars
                      .where((c) => c.id != null)
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.name ?? c.id!)))
                      .toList(),
                  onChanged: (id) async {
                    if (id == null) return;
                    await _settingsService.setDefaultCalendarId(id);
                    setState(() => _selectedCalendarId = id);
                  },
                ),
                const SizedBox(height: 24),
                const Text('Theme'),
                DropdownButton<ThemeMode>(
                  isExpanded: true,
                  value: _themeMode,
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text('Dark')),
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text('System default')),
                  ],
                  onChanged: (mode) async {
                    if (mode == null) return;
                    await widget.onThemeModeChanged(mode);
                    setState(() => _themeMode = mode);
                  },
                ),
                const SizedBox(height: 24),
                const Text('Default duration (when no end time is found)'),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _durationMinutes,
                  items: _durationOptions
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text('$m minutes')))
                      .toList(),
                  onChanged: (minutes) async {
                    if (minutes == null) return;
                    await _settingsService.setDefaultDurationMinutes(minutes);
                    setState(() => _durationMinutes = minutes);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
