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
}
