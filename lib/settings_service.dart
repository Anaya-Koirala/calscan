import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCalendarId = 'default_calendar_id';
const _kReminderMinutes = 'reminder_minutes';
const _kDurationMinutes = 'default_duration_minutes';
const _kThemeMode = 'theme_mode';
const _defaultReminderMinutes = 15;
const _defaultDurationMinutes = 60;

class SettingsService {
  Future<String?> getDefaultCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCalendarId);
  }

  Future<void> setDefaultCalendarId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCalendarId, id);
  }

  Future<int> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kReminderMinutes) ?? _defaultReminderMinutes;
  }

  Future<void> setReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderMinutes, minutes);
  }

  Future<int> getDefaultDurationMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDurationMinutes) ?? _defaultDurationMinutes;
  }

  Future<void> setDefaultDurationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDurationMinutes, minutes);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kThemeMode,
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        });
  }
}
