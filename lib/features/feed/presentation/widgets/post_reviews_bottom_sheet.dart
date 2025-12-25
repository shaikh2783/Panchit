import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/data/models/post_review.dart';
import 'package:snginepro/features/feed/data/models/post_review_stats.dart';
import 'package:snginepro/features/feed/domain/reviews_repository.dart';

class PostReviewsBottomSheet extends StatefulWidget {
  const PostReviewsBottomSheet({super.key, required this.post, this.onCountChanged});

  final Post post;
  final ValueChanged<int>? onCountChanged;

  @override
  State<PostReviewsBottomSheet> createState() => _PostReviewsBottomSheetState();
}
class _PostReviewsBottomSheetState extends State<PostReviewsBottomSheet> {
  late ReviewsRepository _reviewsRepo;
  late AuthNotifier _auth;

  final List<PostReview> _reviews = [];
  ReviewStats? _stats;
  int _count = 0;
  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _pageSize = 15;

  // Add review form
  int _rating = 0;
  final TextEditingController _reviewCtrl = TextEditingController();
  bool _isSubmitting = false;

  // Reply state
  int? _replyingToId;
  final TextEditingController _replyCtrl = TextEditingController();
  bool _isReplySubmitting = false;

  @override
  void initState() {
    super.initState();
    _reviewsRepo = context.read<ReviewsRepository>();
    _auth = context.read<AuthNotifier>();
    _count = widget.post.reviewsCount;
    _loadInitial();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  bool get _isOwner {
    final authorId = int.tryParse(widget.post.authorId ?? '');
    final current = int.tryParse(_auth.currentUser?['user_id']?.toString() ?? '');
    return authorId != null && current != null && authorId == current;
  }

  int get _currentUserId => int.tryParse(_auth.currentUser?['user_id']?.toString() ?? '') ?? 0;

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadStats(),
        _loadPage(reset: true),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _reviewsRepo.getStats(postId: widget.post.id);
      if (mounted && stats != null) {
        setState(() {
          _stats = stats;
          _count = stats.total;
        });
      }
    } catch (_) {
      // ignore stats errors silently
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isMoreLoading) return;
    if (reset) {
      _offset = 0;
      _hasMore = true;
      _reviews.clear();
    }
    if (!_hasMore) return;

    setState(() => _isMoreLoading = true);
    try {
      final items = await _reviewsRepo.getReviews(
        postId: widget.post.id,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _reviews.addAll(items);
          _hasMore = items.length >= _pageSize;
          _offset += items.length;
        });
      }
    } finally {
      if (mounted) setState(() => _isMoreLoading = false);
    }
  }

  Future<void> _addReview() async {
    if (_isOwner) return;
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('review_rating_required'.tr)),
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final review = _reviewCtrl.text.trim();
      final newReview = await _reviewsRepo.addReview(
        postId: widget.post.id,
        rating: _rating,
        review: review.isEmpty ? null : review,
      );
      if (!mounted) return;

      setState(() {
        _reviews.insert(0, newReview);
        _rating = 0;
        _reviewCtrl.clear();
        _stats = null; // force reload stats
        _count += 1;
      });
      await _loadStats();
      widget.onCountChanged?.call(_count);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('review_added_success'.tr)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteReview(PostReview review) async {
    try {
      await _reviewsRepo.deleteReview(reviewId: review.id);
      if (!mounted) return;
      setState(() {
        _reviews.removeWhere((r) => r.id == review.id);
        _stats = null; // refresh stats after delete
      });
      if (_count > 0) _count -= 1;
      widget.onCountChanged?.call(_count);
      await _loadStats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('review_deleted_success'.tr)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('review_delete_failed'.tr)),
        );
      }
    }
  }

  Future<void> _replyToReview(PostReview review) async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isReplySubmitting = true);
    try {
      await _reviewsRepo.replyToReview(reviewId: review.id, reply: text);
      if (!mounted) return;
      setState(() {
        final idx = _reviews.indexWhere((r) => r.id == review.id);
        if (idx != -1) {
          _reviews[idx] = _reviews[idx].copyWith(reply: text, replyTime: DateTime.now().toIso8601String());
        }
        _replyCtrl.clear();
        _replyingToId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('review_reply_success'.tr)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('review_reply_failed'.tr)),
        );
      }
    } finally {
      if (mounted) setState(() => _isReplySubmitting = false);
    }
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildRatingPicker() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(5, (index) {
          final star = index + 1;
          final isActive = star <= _rating;
          return IconButton(
            onPressed: _isOwner ? null : () => setState(() => _rating = star),
            icon: Icon(
              isActive ? Iconsax.star : Iconsax.star_1,
              color: isActive ? Colors.amber : Colors.grey,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAddReviewCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.star, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('add_review_title'.tr, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 10,),
                if (_isOwner)
                  Expanded(
                    child: Chip(
                      padding: EdgeInsets.all(5),
                      label: Text('review_owner_cannot_rate'.tr, style: Theme.of(context).textTheme.labelSmall,maxLines: 2,overflow: TextOverflow.ellipsis,),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRatingPicker(),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewCtrl,
              maxLines: 3,
              maxLength: 1000,
              enabled: !_isOwner,
              decoration: InputDecoration(
                hintText: 'add_review_placeholder'.tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isOwner || _isSubmitting ? null : _addReview,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Iconsax.send_2),
                label: Text('submit_review'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();
    Widget bar(String label, ReviewStatsBucket b) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 32, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
            Expanded(
              child: LinearProgressIndicator(
                value: b.percentage / 100,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 24,
              child: Text('${b.count}', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('reviews_stats_title'.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stats.average.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('average_rating'.tr, style: Theme.of(context).textTheme.bodySmall),
                        Text('total_reviews'.trParams({'count': stats.total.toString()}),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        bar('5★', stats.star5),
                        bar('4★', stats.star4),
                        bar('3★', stats.star3),
                        bar('2★', stats.star2),
                        bar('1★', stats.star1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canDelete(PostReview review) {
    final postOwnerId = int.tryParse(widget.post.authorId ?? '');
    return review.iOwn || (_currentUserId != 0 && postOwnerId == _currentUserId);
  }

  bool _canReply(PostReview review) {
    return review.canReply;
  }

  Widget _buildReviewTile(PostReview review) {
    final canDelete = _canDelete(review);
    final canReply = _canReply(review);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      review.userPicture.isNotEmpty ? NetworkImage(review.userPicture) : null,
                  child: review.userPicture.isEmpty ? const Icon(Iconsax.user, size: 18) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(review.userName.isNotEmpty ? review.userName : '${review.userFirstName} ${review.userLastName}'.trim(),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Text(review.timeFormatted, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            return Icon(
                              star <= review.rate ? Iconsax.star : Iconsax.star_1,
                              size: 16,
                              color: star <= review.rate ? Colors.amber : Colors.grey,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Iconsax.trash, size: 18),
                    onPressed: () => _deleteReview(review),
                  ),
              ],
            ),
            if (review.review.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.review),
            ],
            if (review.reply != null && review.reply!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.message, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(review.reply!)),
                  ],
                ),
              ),
            ],
            if (canReply) ...[
              const SizedBox(height: 8),
              if (_replyingToId == review.id)
                Column(
                  children: [
                    TextField(
                      controller: _replyCtrl,
                      decoration: InputDecoration(
                        hintText: 'add_reply_placeholder'.tr,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isReplySubmitting ? null : () => _replyToReview(review),
                        child: _isReplySubmitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text('submit_reply'.tr),
                      ),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _replyingToId = review.id;
                      _replyCtrl.text = review.reply ?? '';
                    });
                  },
                  icon: const Icon(Iconsax.message_edit, size: 16),
                  label: Text(review.reply == null ? 'add_reply'.tr : 'edit_reply'.tr),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _buildHandle(),
                Row(
                  children: [
                    Icon(Iconsax.star, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('post_reviews_title'.trParams({'count': _count.toString()}),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadInitial,
                      child: ListView(
                        controller: controller,
                        children: [
                          _buildStats(),
                          _buildAddReviewCard(),
                          const SizedBox(height: 8),
                          if (_reviews.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('no_reviews'.tr,
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            )
                          else ...[
                            ..._reviews.map(_buildReviewTile),
                            if (_isMoreLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_hasMore)
                              TextButton(
                                onPressed: _loadPage,
                                child: Text('load_more_reviews'.tr),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
