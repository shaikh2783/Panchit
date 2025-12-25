import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/services/user_photos_service.dart';
import '../../data/models/user_album.dart';
import 'album_photos_page.dart';

class UserAlbumsPage extends StatelessWidget {
  final String? username;

  const UserAlbumsPage({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final service = UserPhotosService(apiClient);

    return Scaffold(
      appBar: AppBar(title: Text('albums_page_title'.tr)),
      body: UserAlbumsGrid(username: username, service: service),
    );
  }
}

class UserAlbumsGrid extends StatefulWidget {
  final String? username;
  final UserPhotosService service;

  const UserAlbumsGrid({super.key, this.username, required this.service});

  @override
  State<UserAlbumsGrid> createState() => _UserAlbumsGridState();
}

class _UserAlbumsGridState extends State<UserAlbumsGrid> {
  List<UserAlbum> _albums = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAlbums();
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
      _loadAlbums();
    }
  }

  Future<void> _loadAlbums() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await widget.service.getUserAlbums(
        username: widget.username,
        page: _currentPage,
        limit: 20,
      );
      final newAlbums = result['albums'] as List<UserAlbum>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      setState(() {
        _albums.addAll(newAlbums);
        _hasMore = pagination['has_more'] == true;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading albums: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_albums.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_albums.isEmpty) {
      return const Center(child: Text('No albums found'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _albums.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _albums.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final album = _albums[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumPhotosPage(album: album),
              ),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: album.cover != null
                      ? CachedNetworkImage(
                          imageUrl: album.cover!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Iconsax.folder_2, size: 48),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${album.photosCount} photos',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
