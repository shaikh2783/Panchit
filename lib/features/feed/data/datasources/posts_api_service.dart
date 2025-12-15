import 'dart:io';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/feed/data/models/create_post_request.dart';
import 'package:snginepro/features/feed/data/models/posts_response.dart';
import 'package:snginepro/features/feed/data/models/story.dart';
import 'package:snginepro/features/feed/data/models/upload_file_data.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:snginepro/main.dart';
// Internal representation of an upload attempt permutation
class _UploadAttempt {
  const _UploadAttempt({
    required this.endpoint,
    required this.typeValue,
    required this.contentType,
    this.includeExtras = true,
  });
  final String endpoint;
  final String typeValue;
  final http_parser.MediaType? contentType;
  final bool includeExtras;
}
class PostsApiService {
  PostsApiService(this._client);
  final ApiClient _client;
  Future<PostsResponse> fetchNewsfeed({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _client.get(
      configCfgP('newsfeed'),
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
        'include_ads': '1',
      },
    );
    final postsResponse = PostsResponse.fromJson(response, requestedLimit: limit);
    if (!postsResponse.isSuccess) {
      throw ApiException(
        postsResponse.message ?? 'Failed to fetch posts',
        details: response,
      );
    }
    // Debug: Show ALL post IDs to check for missing posts
    if (postsResponse.posts.isNotEmpty) {
      for (var i = 0; i < postsResponse.posts.length; i++) {
        final p = postsResponse.posts[i];
        final textPreview = p.text.length > 30 ? p.text.substring(0, 30) : p.text;
      }
      // Check for post ID 0 specifically
      final hasPostZero = postsResponse.posts.any((p) => p.id == 0);
      // Show oldest and newest posts in this batch
      if (postsResponse.posts.length > 1) {
        final oldest = postsResponse.posts.last;
        final newest = postsResponse.posts.first;
      }
    } else {
    }
    return postsResponse;
  }
  /// Fetch posts for a specific user
  Future<PostsResponse> fetchUserPosts({
    required int userId,
    int limit = 20,
    int offset = 0,
  }) async {
    // Use the dedicated endpoint with user_id parameter
    final response = await _client.get(
      configCfgP('user_posts'),
      queryParameters: {
        'user_id': userId.toString(),
        'scope': 'posts_profile',
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );
    if (response['data'] != null && response['data']['posts'] != null) {
    }
    final postsResponse = PostsResponse.fromJson(response);
    if (!postsResponse.isSuccess) {
      throw ApiException(
        postsResponse.message ?? 'Failed to fetch user posts',
        details: response,
      );
    }
    if (postsResponse.posts.isNotEmpty) {
    } else {
    }
    return postsResponse;
  }
  /// Fetch a single post by ID
  Future<Map<String, dynamic>> fetchPost(int postId) async {
    final response = await _client.get(
      configCfgP('posts_get'),
      queryParameters: {
        'post_id': '$postId',
      },
    );
    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to fetch post',
        details: response,
      );
    }
    final data = response['data'];
    if (data == null) {
      throw ApiException('Post not found', details: response);
    }
    return data as Map<String, dynamic>;
  }
  Future<void> reactToPost(int postId, String reaction) async {
    await _client.post(
      configCfgP('posts_react'),
      body: {
        'post_id': postId,
        'reaction': reaction,
      },
    );
  }
  Future<List<Story>> fetchStories() async {
    final response = await _client.get(
      configCfgP('stories'),
      queryParameters: {
        'format': 'both',
      },
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final storiesList = data['stories'];
      if (storiesList is List) {
        return storiesList
            .map((storyData) => Story.fromJson(storyData))
            .toList();
      }
    }
    if (data is List) {
      return data.map((storyData) => Story.fromJson(storyData)).toList();
    }
    return const [];
  }
  /// Upload file (photo, video, audio, document) to server
  /// Returns UploadedFileData with source, type, url, and optional thumb
  Future<UploadedFileData?> uploadFile(
    File file, {
    required FileUploadType type,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    try {
      final mediaType = _inferMediaType(file, type);
      final originalFileName = _basename(file.path);
      // Clean filename: remove special chars, keep only extension
      final ext = _getExtension(originalFileName);
      final cleanName = 'upload_${DateTime.now().millisecondsSinceEpoch}$ext';
      // Use official endpoint per new server documentation
      // Server expects plural form: photos, videos, audio, file
      final attempts = <_UploadAttempt>[];
      final pluralType = _pluralize(type.value);
      attempts.add(
        _UploadAttempt(
          endpoint: configCfgP('file_upload'),
          typeValue: pluralType, // photos, videos, audio, file
          contentType: mediaType,
          includeExtras: false, // Keep it minimal as per new docs
        ),
      );
      ApiException? lastError;
      int attemptNum = 0;
      for (final attempt in attempts) {
        attemptNum++;
        try {
          // Build minimal body as per new server docs
          final body = <String, String>{
            'type': attempt.typeValue,
          };
          final response = await _client.multipartPost(
            attempt.endpoint,
            body: body,
            filePath: file.path,
            fileFieldName: 'file',
            contentType: attempt.contentType,
            onProgress: onProgress,
            fileName: cleanName,
          );
          if (response['status'] == 'success' && response['data'] != null) {
            final data = response['data'];
            return UploadedFileData(
              source: data['source'],
              type: data['type'],
              url: data['url'],
              thumb: data['thumb'], // For videos
              name: data['name'], // For files
              size: data['size'], // For files
              blur: data['blur'] ?? 0,
              duration: data['duration'], // For videos
              width: data['width'], // For videos
              height: data['height'], // For videos
              extension: data['extension'], // File extension
              meta: data['meta'], // Additional metadata
            );
          } else {
          }
        } catch (e) {
          if (e is ApiException) {
            lastError = e;
            // Continue to next attempt
          } else {
            // Wrap non-API errors into ApiException for uniform handling
            lastError = ApiException('Upload failed: $e');
          }
        }
      }
      // If we reach here, all attempts failed
      if (lastError != null) throw lastError;
      return null; // Should not reach, but keeps analyzer happy
    } catch (e) {
      // If the backend responded with an image-specific validation error while uploading video/audio,
      // attempt a graceful fallback (some installs still use legacy path or ignore content-type).
      if (e is ApiException) {
        throw ApiException('Failed to upload file: ${e.message}', statusCode: e.statusCode, details: e.details);
      }
      throw ApiException('Failed to upload file: $e');
    }
  }
  /// Legacy method - kept for backward compatibility
  Future<String?> uploadPhoto(File photo) async {
    final result = await uploadFile(photo, type: FileUploadType.photo);
    return result?.source;
  }
  /// Determine proper MIME type for the given file and upload type
  http_parser.MediaType _inferMediaType(File file, FileUploadType type) {
    // Avoid bringing in extra deps; do simple extension check
    final path = file.path.toLowerCase();
    String ext = '';
    final dot = path.lastIndexOf('.');
    if (dot != -1 && dot < path.length - 1) {
      ext = path.substring(dot + 1);
    }
    switch (type) {
      case FileUploadType.photo:
        switch (ext) {
          case 'png':
            return http_parser.MediaType('image', 'png');
          case 'gif':
            return http_parser.MediaType('image', 'gif');
          case 'webp':
            return http_parser.MediaType('image', 'webp');
          case 'jpg':
          case 'jpeg':
          default:
            return http_parser.MediaType('image', 'jpeg');
        }
      case FileUploadType.video:
        switch (ext) {
          case 'mov':
            return http_parser.MediaType('video', 'quicktime');
          case 'avi':
            return http_parser.MediaType('video', 'x-msvideo');
          case 'webm':
            return http_parser.MediaType('video', 'webm');
          case 'm4v':
            return http_parser.MediaType('video', 'x-m4v');
          case 'mp4':
          default:
            return http_parser.MediaType('video', 'mp4');
        }
      case FileUploadType.audio:
        switch (ext) {
          case 'wav':
            return http_parser.MediaType('audio', 'wav');
          case 'ogg':
            return http_parser.MediaType('audio', 'ogg');
          case 'm4a':
            return http_parser.MediaType('audio', 'mp4');
          case 'mp3':
          default:
            return http_parser.MediaType('audio', 'mpeg');
        }
      case FileUploadType.file:
        switch (ext) {
          case 'pdf':
            return http_parser.MediaType('application', 'pdf');
          case 'txt':
            return http_parser.MediaType('text', 'plain');
          case 'zip':
            return http_parser.MediaType('application', 'zip');
          case 'rar':
            return http_parser.MediaType('application', 'x-rar-compressed');
          case 'doc':
            return http_parser.MediaType('application', 'msword');
          case 'docx':
            return http_parser.MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
          default:
            return http_parser.MediaType('application', 'octet-stream');
        }
    }
  }
  String _basename(String path) {
    if (path.isEmpty) return '';
    final idx = path.lastIndexOf('/');
    if (idx == -1) return path;
    return path.substring(idx + 1);
  }
  String _getExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) return '';
    return filename.substring(dot); // includes the dot
  }
  String _pluralize(String type) {
    switch (type) {
      case 'photo':
        return 'photos';
      case 'video':
        return 'videos';
      case 'audio':
        return 'audios';
      case 'file':
        return 'files';
      default:
        return type;
    }
  }
  /// Delete uploaded file before posting (cleanup)
  Future<bool> deleteUploadedFile(String source) async {
    try {
      final response = await _client.post(
        configCfgP('file_delete'),
        body: {'source': source},
      );
      return response['status'] == 'success';
    } catch (e) {
      return false;
    }
  }
  Future<void> createPost(
    String message, {
    List<String>? photoSources,
    int? coloredPattern,
    String? feelingAction,
    String? feelingValue,
  }) async {
    await _client.post(
      configCfgP('posts_base') + '/create',
      body: {
        'message': message,
        'publish_to': 'timeline',
        if (photoSources != null && photoSources.isNotEmpty)
          'photos': photoSources,
        if (coloredPattern != null)
          'colored_pattern': coloredPattern,
        if (feelingAction != null && feelingAction.isNotEmpty)
          'feeling_action': feelingAction,
        if (feelingValue != null && feelingValue.isNotEmpty)
          'feeling_value': feelingValue,
      },
    );
  }
  /// Create a post with full options support
  Future<CreatePostResponse> createPostAdvanced(CreatePostRequest request) async {
    // If it's a group post, try different endpoints
    if (request.groupId != null) {
      // Try endpoint 1: groups/{id}/create_post
      try {
        final response = await _client.post(
          configCfgP('groups_list') + '/${request.groupId}/create_post',
          body: request.toJson(),
        );
        final createResponse = CreatePostResponse.fromJson(response);
        if (createResponse.isSuccess) {
          return createResponse;
        }
      } catch (e) {
      }
      // Try endpoint 2: publisher (sometimes used for group posts)
      try {
        final response = await _client.post(
          configCfgP('posts_base') + '/publisher',
          body: request.toJson(),
        );
        final createResponse = CreatePostResponse.fromJson(response);
        if (createResponse.isSuccess) {
          return createResponse;
        }
      } catch (e) {
      }
    }
    // Fall back to main endpoint
    final response = await _client.post(
      configCfgP('posts_base') + '/create',
      body: request.toJson(),
    );
    final createResponse = CreatePostResponse.fromJson(response);
    if (!createResponse.isSuccess) {
      throw ApiException(
        createResponse.message ?? 'Failed to create post',
        details: response,
      );
    }
    return createResponse;
  }
}
// ✅ تم نقل configCfgP إلى main.dart - استيراد من هناك