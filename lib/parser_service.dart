import 'package:chrono_dart/chrono_dart.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'parsed_event.dart';

final _dateRe = RegExp(r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})\b');
final _monthDateRe = RegExp(
    r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)[a-z]*\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s*(\d{4})?\b',
    caseSensitive: false);
const _months = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec'
];

ParsedEvent parseFlyerText(String rawText, List<TextBlock> blocks) {
  final title = _guessTitle(blocks);
  final (start, end) = _guessDateTime(rawText);
  final location = _guessLocation(rawText);
  return ParsedEvent(
      title: title,
      start: start,
      end: end,
      location: location,
      rawText: rawText);
}

String _guessTitle(List<TextBlock> blocks) {
  TextBlock? tallest;
  for (final b in blocks) {
    if (_dateRe.hasMatch(b.text) || Chrono.parseDate(b.text) != null) continue;
    if (tallest == null || b.boundingBox.height > tallest.boundingBox.height) {
      tallest = b;
    }
  }
  return tallest?.text ?? '';
}

(DateTime?, DateTime?) _guessDateTime(String rawText) {
  final ymd = _numericDate(rawText) ?? _monthNameDate(rawText);
  if (ymd == null) return (null, null);
  final (year, month, day) = ymd;
  final reference = DateTime(year, month, day, 9, 0);
  final parsed = Chrono.parse(rawText, ref: reference);
  for (final result in parsed) {
    final hasStartTime = result.start.get(Component.hour) != null;
    if (!hasStartTime) continue;

    final startTime = result.start.date().toLocal();
    final start = DateTime(year, month, day, startTime.hour, startTime.minute);
    final endComponent = result.end;
    if (endComponent == null || endComponent.get(Component.hour) == null) {
      return (start, null);
    }

    final endTime = endComponent.date().toLocal();
    return (
      start,
      DateTime(year, month, day, endTime.hour, endTime.minute),
    );
  }

  return (DateTime(year, month, day, 9, 0), null);
}

(int, int, int)? _numericDate(String rawText) {
  final m = _dateRe.firstMatch(rawText);
  if (m == null) return null;
  final month = int.parse(m.group(1)!);
  final day = int.parse(m.group(2)!);
  var year = int.parse(m.group(3)!);
  if (year < 100) year += 2000;
  return (year, month, day);
}

(int, int, int)? _monthNameDate(String rawText) {
  final m = _monthDateRe.firstMatch(rawText);
  if (m == null) return null;
  final month = _months.indexOf(m.group(1)!.toLowerCase().substring(0, 3)) + 1;
  final day = int.parse(m.group(2)!);
  final year =
      m.group(3) != null ? int.parse(m.group(3)!) : DateTime.now().year;
  return (year, month, day);
}

final _addressRe = RegExp(
    r'\b\d{1,5}\s[A-Za-z0-9.\s]{2,30}(St|Street|Ave|Avenue|Rd|Road|Blvd|Ln|Dr|Way|Pl|Ct)\b');
final _keywordRe = RegExp(r'\b(at |location:|venue:)', caseSensitive: false);

String? _guessLocation(String rawText) {
  final lines = rawText.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final m = _keywordRe.firstMatch(lines[i]);
    if (m == null) continue;
    final remainder = lines[i].substring(m.end).trim();
    if (remainder.isNotEmpty) return remainder;
    for (var j = i + 1; j < lines.length; j++) {
      if (lines[j].trim().isNotEmpty) return lines[j].trim();
    }
  }
  final addr = _addressRe.firstMatch(rawText);
  return addr?.group(0);
}
