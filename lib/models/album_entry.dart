class AlbumEntry {
  final String id;
  final String title;
  final String note;
  final List<String> imagePaths;
  final DateTime date;

  const AlbumEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.imagePaths,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'imagePaths': imagePaths.join('|'),
      'date': date.toIso8601String(),
    };
  }

  factory AlbumEntry.fromMap(Map<String, dynamic> map) {
    try {
      return AlbumEntry(
        id: map['id'] as String,
        title: map['title'] as String,
        note: map['note'] as String? ?? '',
        imagePaths: (map['imagePaths'] as String).split('|'),
        date: DateTime.parse(map['date'] as String),
      );
    } catch (e) {
      print('AlbumEntry oluşturma hatası: $e');
      print('Hatalı veri: $map');
      rethrow;
    }
  }

  AlbumEntry copyWith({
    String? id,
    String? title,
    String? note,
    List<String>? imagePaths,
    DateTime? date,
  }) {
    return AlbumEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      imagePaths: imagePaths ?? List.from(this.imagePaths),
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          note == other.note &&
          _listEquals(imagePaths, other.imagePaths) &&
          date == other.date;

  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      note.hashCode ^
      imagePaths.hashCode ^
      date.hashCode;

  @override
  String toString() {
    return 'AlbumEntry(id: $id, title: $title, note: $note, imagePaths: $imagePaths, date: $date)';
  }
}
