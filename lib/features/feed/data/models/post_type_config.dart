import 'package:flutter/material.dart';

enum PostTypeOption {
  text,
  photos,
  album,
  video,
  reel,
  audio,
  file,
  poll,
  feeling,
  colored,
  offer,
  job,
}

class PostTypeConfig {
  const PostTypeConfig({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    this.description,
  });

  final PostTypeOption type;
  final String title;
  final IconData icon;
  final Color color;
  final String? description;

  static const List<PostTypeConfig> all = [
    PostTypeConfig(
      type: PostTypeOption.photos,
      title: 'Photos',
      icon: Icons.photo_library_outlined,
      color: Color(0xFF4CAF50),
      description: 'Upload Photos',
    ),
    PostTypeConfig(
      type: PostTypeOption.album,
      title: 'Album',
      icon: Icons.photo_album_outlined,
      color: Color(0xFF2196F3),
      description: 'Create Album',
    ),
    PostTypeConfig(
      type: PostTypeOption.video,
      title: 'Video',
      icon: Icons.videocam_outlined,
      color: Color(0xFFE91E63),
      description: 'Upload Video',
    ),
    PostTypeConfig(
      type: PostTypeOption.reel,
      title: 'Reel',
      icon: Icons.video_library_outlined,
      color: Color(0xFFFF5722),
      description: 'Upload Reel',
    ),
    PostTypeConfig(
      type: PostTypeOption.audio,
      title: 'Audio',
      icon: Icons.mic_outlined,
      color: Color(0xFF9C27B0),
      description: 'Voice Notes',
    ),
    PostTypeConfig(
      type: PostTypeOption.file,
      title: 'File',
      icon: Icons.attach_file_outlined,
      color: Color(0xFF607D8B),
      description: 'Upload File',
    ),
    PostTypeConfig(
      type: PostTypeOption.poll,
      title: 'Poll',
      icon: Icons.poll_outlined,
      color: Color(0xFF00BCD4),
      description: 'Create Poll',
    ),
    PostTypeConfig(
      type: PostTypeOption.feeling,
      title: 'Feelings',
      icon: Icons.sentiment_satisfied_alt_outlined,
      color: Color(0xFFFFC107),
      description: 'Feelings/Activity',
    ),
    PostTypeConfig(
      type: PostTypeOption.colored,
      title: 'Colored',
      icon: Icons.color_lens_outlined,
      color: Color(0xFFFF9800),
      description: 'Colored Posts',
    ),
    PostTypeConfig(
      type: PostTypeOption.offer,
      title: 'Offer',
      icon: Icons.local_offer_outlined,
      color: Color(0xFF8BC34A),
      description: 'Create Offer',
    ),
    PostTypeConfig(
      type: PostTypeOption.job,
      title: 'Job',
      icon: Icons.work_outline,
      color: Color(0xFF3F51B5),
      description: 'Create Job',
    ),
  ];

  // Get settings for a specific type
  static PostTypeConfig getConfig(PostTypeOption type) {
    return all.firstWhere(
      (config) => config.type == type,
      orElse: () => all.first,
    );
  }

  // Property to get label from title
  String get label => title;
}
