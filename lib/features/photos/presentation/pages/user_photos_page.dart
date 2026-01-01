import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/services/user_photos_service.dart';
import '../../data/models/user_photo.dart';
import 'photo_viewer_page.dart';
import 'package:get/get.dart';

class UserPhotosPage extends StatelessWidget {
  final String? username;

  const UserPhotosPage({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final service = UserPhotosService(apiClient);

    return Scaffold(
      appBar: AppBar(title: Text('photos_page_title'.tr)),
      body: UserPhotosGrid(username: username, service: service),
    );
  }
}

class UserPhotosGrid extends StatefulWidget {
  final String? username;
  final UserPhotosService service;

  const UserPhotosGrid({super.key, this.username, required this.service});

  @override
  State<UserPhotosGrid> createState() => _UserPhotosGridState();
}

class _UserPhotosGridState extends State<UserPhotosGrid> {
  List<UserPhoto> _photos = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  int _totalCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPhotos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadPhotos();
    }
  }

  Future<void> _loadPhotos() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await widget.service.getUserPhotos(
        username: widget.username,
        page: _currentPage,
        limit: 20,
      );
      final newPhotos = result['photos'] as List<UserPhoto>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      setState(() {
        _photos.addAll(newPhotos);
        _hasMore = pagination['has_more'] == true;
        
        final total = pagination['total'];
        if (total != null) {
          _totalCount = int.tryParse(total.toString()) ?? _totalCount;
        }
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading photos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_photos.isEmpty) {
      return const Center(child: Text('No photos found'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.photo, size: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 6),
              Text(
                'Showing ${_photos.length}${_totalCount > 0 ? ' of $_totalCount' : ''} photos',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: _photos.length + (_isLoading ? 1 : 0) + ((_hasMore && !_isLoading) ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _photos.length && _isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (index == _photos.length + (_isLoading ? 1 : 0) && _hasMore && !_isLoading) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: _loadPhotos,
                      icon: const Icon(Icons.expand_more),
                      label: Text('load_more_button'.tr),
                    ),
                  ),
                );
              }

              final photo = _photos[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerPage(
                          photos: _photos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: photo.source,
                          child: CachedNetworkImage(
                            imageUrl: photo.source,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        if (photo.isBlurred)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.blur_on, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
