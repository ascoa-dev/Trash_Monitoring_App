import 'package:flutter/material.dart';

class MediaModel {
  MediaModel({required this.id, required this.sourceUrl});

  final int id;
  final String sourceUrl;

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    final src =
        json['source_url'] as String? ??
        (json['media_details']?['sizes']?['full']?['source_url'] as String?) ??
        (json['media_details']?['sizes']?['thumbnail']?['source_url']
            as String?) ??
        (json['media_details']?['sizes']?['medium']?['source_url']
            as String?) ??
        '';
    debugPrint('[Media URL] $src');
    return MediaModel(id: json['id'] as int, sourceUrl: src);
  }
}
