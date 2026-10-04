class NewsArticle {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String? image;
  final String? imageUrl;
  final String status;
  final String? publishedAt;
  final int createdBy;
  final String? authorName;
  final String? createdAt;

  NewsArticle({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.image,
    this.imageUrl,
    this.status = 'draft',
    this.publishedAt,
    required this.createdBy,
    this.authorName,
    this.createdAt,
  });

  bool get isPublished => status == 'published';

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? json['creator'] as Map<String, dynamic>?;

    return NewsArticle(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      publishedAt: json['published_at']?.toString(),
      createdBy: int.tryParse(json['created_by']?.toString() ?? '') ?? 0,
      authorName: author?['name']?.toString() ?? json['author_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'content': content,
      'image': image,
      'status': status,
      'published_at': publishedAt,
    };
  }
}
