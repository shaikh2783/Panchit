class WatchItem {
  const WatchItem({
    required this.id,
    required this.title,
    this.thumbnail = '',
    this.country = '',
    this.duration = '',
    this.description = '',
    this.url = '',
    this.type = '',
  });

  final String id;
  final String title;
  final String thumbnail;
  final String country;
  final String duration;
  final String description;
  final String url;
  final String type;

  factory WatchItem.fromJson(Map<String, dynamic> json) {
    String _s(Object? v) => v == null ? '' : v.toString();
    return WatchItem(
      id: _s(json['id'].toString().isNotEmpty ? json['id'] : (json['video_id'] ?? json['movie_id'] ?? json['watch_id'])),
      title: _s(json['title'] ?? json['name'] ?? json['video_title'] ?? json['movie_title']),
      thumbnail: _s(json['thumbnail'] ?? json['image'] ?? json['poster'] ?? json['cover']),
      country: _s(json['country'] ?? json['origin_country'] ?? json['region']),
      duration: _s(json['duration'] ?? json['length'] ?? json['runtime']),
      description: _s(json['description'] ?? json['summary'] ?? json['overview'] ?? json['plot']),
      url: _s(json['url'] ?? json['stream_url'] ?? json['video_url'] ?? json['watch_url']),
      type: _s(json['type'] ?? json['category'] ?? json['genre']),
    );
  }
}
