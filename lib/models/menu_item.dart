class MenuItem {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? 'No description',
      imageUrl: json['image'],
    );
  }
}
