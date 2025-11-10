import 'package:hive/hive.dart';

part 'post.g.dart';

@HiveType(typeId: 10)
class Post {
  Post({
    required this.id,
    required this.title,
    required this.link,
    required this.featuredMedia,
    this.imageUrl,
  });

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String link;

  @HiveField(3)
  final int featuredMedia;

  @HiveField(4)
  String? imageUrl;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: (json['title']?['rendered'] as String?) ?? '',
      link: (json['link'] as String?) ?? '',
      featuredMedia: (json['featured_media'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'link': link,
      'featured_media': featuredMedia,
      'imageUrl': imageUrl,
    };
  }
}
