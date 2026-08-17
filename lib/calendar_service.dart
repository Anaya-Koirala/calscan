import 'dart:io';
import 'package:device_calendar/device_calendar.dart';
import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'parsed_event.dart';

class CalendarService {
  final _plugin = DeviceCalendarPlugin();
  static const _organizerEmail = '';

  Future<List<Calendar>> getCalendars() async {
    var perm = await _plugin.hasPermissions();
    if (perm.data != true) perm = await _plugin.requestPermissions();
    if (perm.data != true) return [];
    final result = await _plugin.retrieveCalendars();
    return result.data ?? [];
  }

  Future<String?> addEvent(
    ParsedEvent event, {
    required String calendarId,
    required int reminderMinutes,
    required int defaultDurationMinutes,
  }) async {
    final start = event.start;
    if (start == null) return null;
    final end =
        event.end ?? start.add(Duration(minutes: defaultDurationMinutes));
    final calEvent = Event(
      calendarId,
      title: event.title,
      start: tz.TZDateTime.from(start, tz.local),
      end: tz.TZDateTime.from(end, tz.local),
      location: event.location,
      reminders:
          reminderMinutes >= 0 ? [Reminder(minutes: reminderMinutes)] : null,
    );
    final result = await _plugin.createOrUpdateEvent(calEvent);
    return result?.data;
  }

  Future<void> deleteEvent(String calendarId, String eventId) async {
    await _plugin.deleteEvent(calendarId, eventId);
  }

  String toIcs(
    ParsedEvent event, {
    required int defaultDurationMinutes,
    required int reminderMinutes,
  }) {
    final start = event.start ?? DateTime.now();
    final end =
        event.end ?? start.add(Duration(minutes: defaultDurationMinutes));
    final invite = VCalendar.createEvent(
      start: start,
      organizerEmail: _organizerEmail,
      end: end,
      summary: event.title,
      location: event.location,
      productId: 'CalScan',
    );
    if (reminderMinutes >= 0) {
      final vEvent = invite.children.whereType<VEvent>().first;
      final alarm = VAlarm(parent: vEvent)
        ..action = AlarmAction.display
        ..description = 'Event reminder';
      if (reminderMinutes == 0) {
        alarm.triggerDate = start;
      } else {
        alarm.triggerRelativeDuration =
            IsoDuration(minutes: reminderMinutes, isNegativeDuration: true);
      }
      vEvent.children.add(alarm);
    }
    return invite.toString();
  }

  Future<File> saveIcsToFile(
    ParsedEvent event, {
    required int defaultDurationMinutes,
    required int reminderMinutes,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/event_${DateTime.now().millisecondsSinceEpoch}.ics';
    return File(path).writeAsString(
      toIcs(
        event,
        defaultDurationMinutes: defaultDurationMinutes,
        reminderMinutes: reminderMinutes,
      ),
    );
  }
}
