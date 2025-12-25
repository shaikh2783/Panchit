class CreatePostRequest {
  CreatePostRequest({
    this.message,
    this.handle = 'me',
    this.privacy = 'public',
    this.photos,
    this.video,
    this.album,
    this.reel,
    this.reelThumbnail,
    this.audio,
    this.file,
    this.pollOptions,
    this.feeling,
    this.coloredPattern,
    this.offer,
    this.job,
    this.scheduleDate,
    this.pageId,
    this.groupId,
    this.eventId,
    this.forAdult = false, // 🆕 محتوى للبالغين
  });

  final String? message;
  final String handle; // me, page_id, group_id, event_id
  final String privacy; // public, friends, private
  final List<PhotoData>? photos; // List of photo objects with source and blur
  final Map<String, dynamic>? video; // Video data object from upload response
  final AlbumData? album;
  final Map<String, dynamic>? reel; // Reel data object
  final String? reelThumbnail; // Reel thumbnail URL
  final AudioData? audio;
  final FileData? file;
  final List<String>? pollOptions;
  final FeelingData? feeling;
  final int? coloredPattern;
  final OfferData? offer;
  final JobData? job;
  final String? scheduleDate;
  final String? pageId;
  final String? groupId;
  final String? eventId;
  final bool forAdult; // 🆕 محتوى للبالغين (سيُطبق blur تلقائياً)

  Map<String, dynamic> toJson() {
    
    final json = <String, dynamic>{
      'privacy': privacy,
    };

    if (pageId != null) {
      // Send pageId as integer for in_page parameter
      final pageIdInt = int.tryParse(pageId!) ?? 0;
      json['in_page'] = pageIdInt;
    }
    if (groupId != null) {
      // Simple approach - just use in_group
      final groupIdInt = int.tryParse(groupId!) ?? 0;
      json['in_group'] = groupIdInt;
    }
    if (eventId != null) {
      // Send eventId as integer for in_event parameter
      final eventIdInt = int.tryParse(eventId!) ?? 0;
      json['in_event'] = eventIdInt;
    }

    if (message != null && message!.isNotEmpty) {
      json['message'] = message;
    }

    if (photos != null && photos!.isNotEmpty) {
      json['photos'] = photos!.map((p) => p.toJson()).toList();
      json['post_type'] = 'photos'; // Set post type for photos
    }

    if (video != null) {
      json['video'] = video;
      json['post_type'] = 'video'; // Set post type for video
      json['category_id'] = '1'; // Add category_id at root level for video posts
    }

    if (album != null) {
      json['album'] = album!.toJson();
      json['post_type'] = 'album';
    }

    if (reel != null) {
      json['reel'] = reel;
      json['post_type'] = 'reel';
      if (reelThumbnail != null) {
        json['reel_thumbnail'] = reelThumbnail;
      }
    }

    if (audio != null) {
      json['audio'] = audio!.toJson();
      json['post_type'] = 'audio';
    }

    if (file != null) {
      json['file'] = file!.toJson();
      json['post_type'] = 'file';
    }

    if (pollOptions != null && pollOptions!.isNotEmpty) {
      json['poll_options'] = pollOptions;
      json['post_type'] = 'poll';
    }

    if (feeling != null) {
      // Use the new API format for feelings
      json['feeling_action'] = feeling!.action;
      json['feeling_value'] = feeling!.value;
    }

    if (coloredPattern != null && coloredPattern! > 0) {
      json['colored_pattern'] = coloredPattern;
    }

    if (offer != null) {
      json['offer'] = offer!.toJson();
    }

    if (job != null) {
      json['job'] = job!.toJson();
    }

    if (scheduleDate != null) {
      json['schedule_date'] = scheduleDate;
    }

    // 🆕 إضافة for_adult
    if (forAdult) {
      json['for_adult'] = 1; // سيُطبق blur تلقائياً على جميع الصور
    }

    // Set default post_type if not already set
    if (!json.containsKey('post_type')) {
      json['post_type'] = 'text'; // Default to text post
    }

    return json;
  }
}

class PhotoData {
  PhotoData({
    required this.source,
    this.size,
    this.extension,
    this.blur = 0,
  });

  final String source;
  final int? size;
  final String? extension;
  final int blur;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'source': source,
      'blur': blur, // Always include blur field (0 or 1)
    };
    if (size != null) json['size'] = size;
    if (extension != null) json['extension'] = extension;
    return json;
  }
}

class AlbumData {
  AlbumData({
    required this.title,
    required this.photos,
  });

  final String title;
  final List<PhotoData> photos;

  Map<String, dynamic> toJson() => {
        'title': title,
        'photos': photos.map((p) => p.toJson()).toList(),
      };
}

class AudioData {
  AudioData({required this.source});

  final String source;

  Map<String, dynamic> toJson() => {'source': source};
}

class FileData {
  FileData({
    required this.source,
    required this.name,
    required this.size,
  });

  final String source;
  final String name;
  final int size;

  Map<String, dynamic> toJson() => {
        'source': source,
        'name': name,
        'size': size,
      };
}

class FeelingData {
  FeelingData({
    required this.action,
    required this.value,
  });

  final String action;
  final String value;

  Map<String, dynamic> toJson() => {
        'action': action,
        'value': value,
      };
}

class OfferData {
  OfferData({
    required this.title,
    required this.price,
    required this.currency,
    required this.category,
    required this.location,
    this.description,
  });

  final String title;
  final String price;
  final String currency;
  final String category;
  final String location;
  final String? description;

  Map<String, dynamic> toJson() => {
        'title': title,
        'price': price,
        'currency': currency,
        'category': category,
        'location': location,
        if (description != null) 'description': description,
      };
}

class JobData {
  JobData({
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.category,
    this.salaryRange,
    this.description,
  });

  final String title;
  final String company;
  final String location;
  final String type;
  final String category;
  final String? salaryRange;
  final String? description;

  Map<String, dynamic> toJson() => {
        'title': title,
        'company': company,
        'location': location,
        'type': type,
        'category': category,
        if (salaryRange != null) 'salary_range': salaryRange,
        if (description != null) 'description': description,
      };
}

class CreatePostResponse {
  CreatePostResponse({
    required this.status,
    this.message,
    this.postId,
    this.postData,
  });

  final String status;
  final String? message;
  final int? postId;
  final Map<String, dynamic>? postData;

  bool get isSuccess => status == 'success';

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    // Extract post data from response
    final data = json['data'];
    final postData = data is Map<String, dynamic> ? data['post'] : null;
    
    return CreatePostResponse(
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String?,
      postId: postData?['post_id'] as int?,
      postData: postData is Map<String, dynamic> ? postData : null,
    );
  }
}
