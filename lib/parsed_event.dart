class ParsedEvent {
  String title;
  DateTime? start;
  DateTime? end;
  String? location;
  String rawText;

  ParsedEvent({
    this.title = '',
    this.start,
    this.end,
    this.location,
    this.rawText = '',
  });

  bool get titleMissing => title.isEmpty;
  bool get dateMissing => start == null;
  bool get locationMissing => location == null || location!.isEmpty;
}
