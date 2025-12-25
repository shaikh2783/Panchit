import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import '../../data/models/watch_item.dart';
import '../../domain/watch_repository.dart';

class WatchPage extends StatefulWidget {
  const WatchPage({super.key});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  final ScrollController _scrollController = ScrollController();
  List<WatchItem> _items = [];
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _country;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(initial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _load({bool initial = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (initial) {
        _offset = 0;
        _hasMore = true;
        _items.clear();
      }
    });

    try {
      final repo = context.read<WatchRepository>();
      final response = await repo.fetchWatch(offset: _offset, limit: _limit, country: _country);
      setState(() {
        if (initial) {
          _items = response.items.toList();
        } else {
          _items.addAll(response.items);
        }
        _hasMore = response.hasMore;
        _offset = _items.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error'.tr}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final repo = context.read<WatchRepository>();
      final response = await repo.fetchWatch(offset: _offset, limit: _limit, country: _country);
      setState(() {
        _items.addAll(response.items);
        _hasMore = response.hasMore;
        _offset = _items.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error'.tr}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  void _chooseCountry() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _country ?? '');
        return AlertDialog(
          title: Text('filter_by_country_title'.tr),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'e.g., US, EG'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr)),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('apply_button'.tr)),
          ],
        );
      },
    );
    if (result != null) {
      setState(() => _country = result.isEmpty ? null : result);
      _load(initial: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.read<AppConfig>();

    return Scaffold(
      appBar: AppBar(
        title: Text('watch_page_title'.tr),
        actions: [
          IconButton(icon: const Icon(Iconsax.global), onPressed: _chooseCountry),
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: () => _load(initial: true)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(initial: true),
        child: _isLoading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final item = _items[index];
                  final thumbUri = appConfig.mediaAsset(item.thumbnail);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: item.thumbnail.isNotEmpty ? NetworkImage(thumbUri.toString()) : null,
                        child: item.thumbnail.isEmpty ? const Icon(Iconsax.video_square) : null,
                      ),
                      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [item.country, item.duration].where((e) => e.trim().isNotEmpty).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Iconsax.play_circle),
                      onTap: () {
                        // TODO: Navigate to detailed watch view or play
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
