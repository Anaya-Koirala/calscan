import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'parsed_event.dart';
import 'calendar_service.dart';
import 'settings_service.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
const _reminderOptions = [-1, 0, 5, 10, 15, 30, 60, 120, 1440, 10080];

class ReviewScreen extends StatefulWidget {
  final ParsedEvent event;
  const ReviewScreen({super.key, required this.event});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  DateTime? _start;
  DateTime? _end;
  int _reminderMinutes = 15;
  final _calendarService = CalendarService();
  final _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.event.title);
    _location = TextEditingController(text: widget.event.location ?? '');
    _start = widget.event.start;
    _end = widget.event.end;
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final minutes = await _settingsService.getReminderMinutes();
    if (!mounted) return;
    setState(() {
      _reminderMinutes = _reminderOptions.contains(minutes) ? minutes : 15;
    });
  }

  bool get _titleMissing => _title.text.isEmpty;
  bool get _dateMissing => _start == null;
  bool get _locationMissing => _location.text.isEmpty;

  InputDecoration _decoration(String label, bool missing) => InputDecoration(
        labelText: label,
        filled: missing,
        fillColor: missing ? Colors.red.withValues(alpha: 0.08) : null,
        errorBorder:
            const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
      );

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _start = DateTime(picked.year, picked.month, picked.day,
          _start?.hour ?? 9, _start?.minute ?? 0);
    });
  }

  Future<void> _pickEndDate() async {
    final baseDate = _end ?? _start ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: baseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _end = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _end?.hour ?? _start?.hour ?? 10,
        _end?.minute ?? _start?.minute ?? 0,
      );
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final base = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          base != null ? TimeOfDay.fromDateTime(base) : TimeOfDay.now(),
    );
    if (picked == null) return;
    final day = isStart
        ? (_start ?? DateTime.now())
        : (_end ?? _start ?? DateTime.now());
    setState(() {
      final result =
          DateTime(day.year, day.month, day.day, picked.hour, picked.minute);
      if (isStart) {
        _start = result;
      } else {
        _end = result;
      }
    });
  }

  Future<void> _openDateTimeSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Date & time',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Starts on'),
                    trailing: Text(
                        _start == null ? 'Set date' : _formatDate(_start!)),
                    onTap: () async {
                      await _pickStartDate();
                      setSheetState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_available),
                    title: const Text('Ends on'),
                    trailing:
                        Text(_end == null ? 'Set date' : _formatDate(_end!)),
                    onTap: () async {
                      await _pickEndDate();
                      setSheetState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Starts'),
                    trailing: Text(_start == null
                        ? '--'
                        : TimeOfDay.fromDateTime(_start!).format(context)),
                    onTap: () async {
                      await _pickTime(isStart: true);
                      setSheetState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Ends'),
                    trailing: Text(_end == null
                        ? '--'
                        : TimeOfDay.fromDateTime(_end!).format(context)),
                    onTap: () async {
                      await _pickTime(isStart: false);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Done')),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_monthNames[d.month - 1]} ${d.day}';

  String _dateTimeLabel() {
    if (_start == null) return 'Set date & time';
    final startDate = _formatDate(_start!);
    final startTime = TimeOfDay.fromDateTime(_start!).format(context);
    if (_end == null) return '$startDate · $startTime';
    final endDate = _formatDate(_end!);
    final endTime = TimeOfDay.fromDateTime(_end!).format(context);
    if (_start!.year == _end!.year &&
        _start!.month == _end!.month &&
        _start!.day == _end!.day) {
      return '$startDate · $startTime – $endTime';
    }
    return '$startDate $startTime → $endDate $endTime';
  }

  String _reminderLabel(int minutes) {
    switch (minutes) {
      case -1:
        return 'None';
      case 0:
        return 'At time of event';
      case 5:
      case 10:
      case 15:
      case 30:
        return '$minutes minutes before';
      case 60:
        return '1 hour before';
      case 120:
        return '2 hours before';
      case 1440:
        return '1 day before';
      case 10080:
        return '1 week before';
      default:
        return '$minutes minutes before';
    }
  }

  ParsedEvent _currentEvent() => ParsedEvent(
        title: _title.text,
        start: _start,
        end: _end,
        location: _location.text,
        rawText: widget.event.rawText,
      );

  Future<void> _showRawOcrDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raw OCR'),
        content: SingleChildScrollView(
          child: SelectableText(widget.event.rawText),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: widget.event.rawText));
              if (!context.mounted) return;
              Navigator.pop(context);
              _showSnack('Copied');
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCalendar() async {
    var calendarId = await _settingsService.getDefaultCalendarId();
    if (calendarId == null) {
      final calendars = await _calendarService.getCalendars();
      if (calendars.isEmpty || calendars.first.id == null) {
        _showSnack('No calendar available');
        return;
      }
      calendarId = calendars.first.id!;
    }
    final defaultDuration = await _settingsService.getDefaultDurationMinutes();
    final eventId = await _calendarService.addEvent(
      _currentEvent(),
      calendarId: calendarId,
      reminderMinutes: _reminderMinutes,
      defaultDurationMinutes: defaultDuration,
    );
    if (eventId == null) {
      _showSnack('Could not add event');
      return;
    }
    if (!mounted) return;
    final id = calendarId;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Added to calendar'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => _calendarService.deleteEvent(id, eventId),
      ),
    ));
  }

  Future<void> _saveIcs() async {
    final defaultDuration = await _settingsService.getDefaultDurationMinutes();
    final bytes = Uint8List.fromList(
      utf8.encode(
        _calendarService.toIcs(
          _currentEvent(),
          defaultDurationMinutes: defaultDuration,
          reminderMinutes: _reminderMinutes,
        ),
      ),
    );
    final savedUri = await FilePicker.saveFile(
      fileName: 'event.ics',
      bytes: bytes,
    );
    if (savedUri == null) return;
    final filePath = savedUri.toFilePath();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Saved'),
      action: SnackBarAction(
        label: 'Open',
        onPressed: () async {
          final result = await OpenFilex.open(filePath);
          if (result.type != ResultType.done) {
            _showSnack('Could not open file');
          }
        },
      ),
    ));
  }

  Future<void> _share() async {
    final defaultDuration = await _settingsService.getDefaultDurationMinutes();
    final file = await _calendarService.saveIcsToFile(
      _currentEvent(),
      defaultDurationMinutes: defaultDuration,
      reminderMinutes: _reminderMinutes,
    );
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Event'),
        actions: [
          TextButton(
            onPressed: _showRawOcrDialog,
            child: const Text('Raw OCR'),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _title,
                  decoration: _decoration('Title', _titleMissing),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _openDateTimeSheet,
                  style: _dateMissing
                      ? OutlinedButton.styleFrom(foregroundColor: Colors.red)
                      : OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 10),
                    Text(_dateTimeLabel()),
                  ]),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _location,
                  decoration: _decoration('Location', _locationMissing),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                const Text('Alert'),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _reminderMinutes,
                  items: _reminderOptions
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(_reminderLabel(m))))
                      .toList(),
                  onChanged: (minutes) async {
                    if (minutes == null) return;
                    await _settingsService.setReminderMinutes(minutes);
                    if (!mounted) return;
                    setState(() => _reminderMinutes = minutes);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                    onPressed: _addToCalendar,
                    child: const Text('Add to Calendar')),
                const SizedBox(height: 8),
                OutlinedButton(
                    onPressed: _saveIcs, child: const Text('Save as .ics')),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _share, child: const Text('Share')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
