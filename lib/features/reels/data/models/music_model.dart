class Music {
  Music({
    this.id,
    this.categoryId,
    this.title,
    this.sound,
    this.duration,
    this.artist,
    this.image,
    this.postCount,
  });

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id'] ?? ''}'),
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse('${json['category_id'] ?? ''}'),
      title: json['title']?.toString(),
      sound: json['sound']?.toString(),
      duration: json['duration']?.toString(),
      artist: json['artist']?.toString(),
      image: json['image']?.toString(),
      postCount: json['post_count'] is int
          ? json['post_count']
          : int.tryParse('${json['post_count'] ?? ''}'),
    );
  }

  final int? id;
  final int? categoryId;
  final String? title;
  final String? sound;
  final String? duration;
  final String? artist;
  final String? image;
  final int? postCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'title': title,
        'sound': sound,
        'duration': duration,
        'artist': artist,
        'image': image,
        'post_count': postCount,
      };
}

class MusicCategory {
  MusicCategory({this.id, this.name, this.image});

  factory MusicCategory.fromJson(Map<String, dynamic> json) {
    return MusicCategory(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id'] ?? ''}'),
      name: json['name']?.toString(),
      image: json['image']?.toString(),
    );
  }

  final int? id;
  final String? name;
  final String? image;
}

class SelectedMusic {
  SelectedMusic({
    required this.music,
    required this.audioStartMS,
    required this.downloadedURL,
    this.endMilliSec,
  });

  final Music? music;
  final int audioStartMS;
  final String downloadedURL;
  final int? endMilliSec;

  Map<String, dynamic> toJson() => {
        'music': music?.toJson(),
        'downloadedURL': downloadedURL,
        'audioStartMS': audioStartMS,
        'endMilliSec': endMilliSec,
      };
}