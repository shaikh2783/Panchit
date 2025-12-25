import 'blog_author.dart';

class BlogPost {
  final int postId;
  final String title;
  final String cover;
  final int categoryId;
  final String categoryName;
  final String textHtml;
  final String textSnippet;
  final List<String> tags;
  final String createdTime;
  final BlogAuthor author;
  final bool iOwner;

  const BlogPost({
    required this.postId,
    required this.title,
    required this.cover,
    required this.categoryId,
    required this.categoryName,
    required this.textHtml,
    required this.textSnippet,
    required this.tags,
    required this.createdTime,
    required this.author,
    this.iOwner = false,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final List<String> tags;
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    } else if (rawTags is String) {
      tags = rawTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else {
      tags = const [];
    }

    return BlogPost(
      postId: json['post_id'] is String
          ? int.tryParse(json['post_id']) ?? 0
          : (json['post_id'] ?? 0) as int,
      title: (json['title'] ?? '').toString(),
      cover: (json['cover'] ?? '').toString(),
      categoryId: json['category_id'] is String
          ? int.tryParse(json['category_id']) ?? 0
          : (json['category_id'] ?? 0) as int,
      categoryName: (json['category_name'] ?? '').toString(),
      textHtml: (json['text'] ?? '').toString(),
      textSnippet: (json['text_snippet'] ?? '').toString(),
      tags: tags,
      createdTime: (json['created_time'] ?? '').toString(),
      author: BlogAuthor.fromJson(json['author'] as Map<String, dynamic>),
      iOwner: json['i_owner'] == true || json['i_owner'] == '1' || json['i_owner'] == 1,
    );
  }
}
