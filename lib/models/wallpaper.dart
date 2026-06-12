class Wallpaper {
  final String id;
  final String title;
  final String author;
  final String url;
  final String category;
  final String resolvedUrl;

  Wallpaper({
    required this.id,
    required this.title,
    required this.author,
    required this.url,
    required this.category,
    String? resolvedUrl,
  }) : resolvedUrl = resolvedUrl ?? url;

  factory Wallpaper.fromJson(Map<String, dynamic> json, String category) {
    final id = json['id'];
    final url = json['url'];
    if (id == null || url == null) throw const FormatException('Missing id or url');
    return Wallpaper(
      id: id.toString(),
      title: json['title']?.toString() ?? 'Untitled',
      author: json['author']?.toString() ?? 'Unknown',
      url: url.toString(),
      category: category,
    );
  }
}
