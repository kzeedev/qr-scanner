class SavedScan {
  final String id;
  final String content;
  final DateTime timestamp;
  final String? name;

  SavedScan({
    required this.id,
    required this.content,
    required this.timestamp,
    this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'name': name,
      };

  factory SavedScan.fromJson(Map<String, dynamic> json) => SavedScan(
        id: json['id'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        name: json['name'] as String?,
      );
}
