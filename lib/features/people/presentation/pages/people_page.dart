import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';
import 'package:snginepro/features/friends/presentation/widgets/add_friend_button.dart';
import 'package:snginepro/features/friends/data/models/friendship_model.dart';
import '../../data/models/person.dart';
import '../../domain/people_repository.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final ScrollController _scrollController = ScrollController();
  List<Person> _people = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
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

  Future<void> _load() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _offset = 0;
      _hasMore = true;
      _people.clear();
    });

    try {
      final repo = context.read<PeopleRepository>();
      final response = await repo.fetchPeople(offset: _offset, random: false);
      setState(() {
        _people = response.people.toList();
        _hasMore = response.hasMore;
        _offset = _people.length;
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
      final repo = context.read<PeopleRepository>();
      final response = await repo.fetchPeople(offset: _offset, random: true);
      setState(() {
        _people.addAll(response.people);
        _hasMore = response.hasMore;
        _offset = _people.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error'.tr}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = context.read<AppConfig>();

    return Scaffold(
      appBar: AppBar(
        title: Text('people_page_title'.tr),
        actions: [
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _people.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.people, size: 80, color: theme.colorScheme.primary.withOpacity(0.3)),
                        const SizedBox(height: 12),
                         Text('no_people_found'.tr),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _people.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _people.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final p = _people[index];
                      final avatarUri = appConfig.mediaAsset(p.picture);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(avatarUri.toString()),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (p.verified)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(Iconsax.verify, color: theme.colorScheme.primary, size: 18),
                                ),
                              if (p.subscribed)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Iconsax.crown, color: theme.colorScheme.secondary, size: 18),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            p.userName.isNotEmpty ? '@${p.userName}' : 'ID: ${p.userId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                       
                              const SizedBox(width: 8),
                              AddFriendButton(
                                userId: int.tryParse(p.userId) ?? 0,
                                initialStatus: FriendshipStatus.none,
                                size: AddFriendButtonSize.small,
                                style: AddFriendButtonStyle.outlined,
                                showText: false,
                              ),
                            ],
                          ),
                          onTap: () {
                            if (p.userName.isNotEmpty) {
                              Get.to(() => ProfilePage(username: p.userName));
                            } else {
                              final id = int.tryParse(p.userId);
                              if (id != null && id > 0) {
                                Get.to(() => ProfilePage(userId: id));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cannot open profile: missing identifier')),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
