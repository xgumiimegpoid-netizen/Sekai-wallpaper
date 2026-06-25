import 'package:hive/hive.dart';

part 'wallpaper.g.dart';

@HiveType(typeId: 0)
class Wallpaper {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String url;

  @HiveField(4)
  final String category;

  @HiveField(5)
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'url': url,
        'category': category,
      };
}
