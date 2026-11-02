class RecordFolder {
  final String id;
  String name;

  RecordFolder({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory RecordFolder.fromJson(Map<String, dynamic> json) => RecordFolder(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );
}
