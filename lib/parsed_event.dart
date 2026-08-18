class ParsedEvent {
  final String title;
  final DateTime? start;
  final DateTime? end;
  final String? location;
  final String rawText;

  const ParsedEvent({
    this.title = '',
    this.start,
    this.end,
    this.location,
    this.rawText = '',
  });
}
