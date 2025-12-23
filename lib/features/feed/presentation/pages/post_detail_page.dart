import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/domain/posts_repository.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_card.dart';
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final int postId;
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}
class _PostDetailPageState extends State<PostDetailPage> {
  Post? _post;
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadPost();
  }
  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = context.read<PostsRepository>();
      final postData = await repository.fetchPost(widget.postId);
      setState(() {
        _post = Post.fromJson(postData);
        _isLoading = false;
      });
    } catch (e) {
      String errorMessage = 'Failed to load post: $e';
      // Check if it's a 404 error (Post not found)
      if (e.toString().contains('Post not found') || 
          e.toString().contains('404') ||
          e.toString().contains('"status":"error"') && e.toString().contains('"message":"Post not found"')) {
        errorMessage = 'Post not found on this page or has been deleted';
      }
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }
  void _handleReactionChanged(String postId, String reaction) async {
    if (_post == null) return;
    setState(() {
      _post = _post!.copyWithReaction(reaction);
    });
    try {
      final postsRepository = context.read<PostsRepository>();
      await postsRepository.reactToPost(int.parse(postId), reaction);
    } catch (e) {
      // إعادة التحميل في حالة الخطأ
      _loadPost();
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title:  Text('post_details'.tr),
        elevation: 0,
      ),
      body: _buildBody(isDark),
    );
  }
  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [Colors.grey[50]!, Colors.grey[100]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.grey.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.blue[400]! : Colors.blue[600]!,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'loading_post'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return _buildErrorState(isDark);
    }
    if (_post == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [Colors.grey[50]!, Colors.grey[100]!],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Card(
              elevation: isDark ? 8 : 4,
              shadowColor: isDark ? Colors.black54 : Colors.grey.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey[800]!, Colors.grey[850]!],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey[50]!],
                      ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDark
                            ? [Colors.purple[700]!, Colors.purple[800]!]
                            : [Colors.purple[300]!, Colors.purple[400]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'post_not_available'.tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'requested_post_not_found'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                            ? [Colors.blue[600]!, Colors.blue[700]!]
                            : [Colors.blue[500]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        label:  Text(
                          'go_back'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPost,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PostCard(
          post: _post!,
          onReactionChanged: _handleReactionChanged,
        ),
      ),
    );
  }
  Widget _buildErrorState(bool isDark) {
    final isPostNotFound = _error!.contains('post_not_found_or_deleted'.tr);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark 
            ? [Colors.grey[900]!, Colors.grey[850]!]
            : [Colors.grey[50]!, Colors.grey[100]!],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Card(
            elevation: isDark ? 8 : 4,
            shadowColor: isDark ? Colors.black54 : Colors.grey.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isDark 
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[800]!, Colors.grey[850]!],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey[50]!],
                    ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Icon Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isPostNotFound
                        ? LinearGradient(
                            colors: isDark 
                              ? [Colors.orange[700]!, Colors.orange[800]!]
                              : [Colors.orange[300]!, Colors.orange[400]!],
                          )
                        : LinearGradient(
                            colors: isDark 
                              ? [Colors.red[700]!, Colors.red[800]!]
                              : [Colors.red[300]!, Colors.red[400]!],
                          ),
                      boxShadow: [
                        BoxShadow(
                          color: (isPostNotFound ? Colors.orange : Colors.red).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isPostNotFound ? Icons.search_off_rounded : Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Main Error Message
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isPostNotFound) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.orange[800] : Colors.orange[50])?.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.orange[600]! : Colors.orange[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: isDark ? Colors.orange[300] : Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'post_deleted_by_author_or_admin'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.orange[200] : Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                              ? [Colors.blue[600]!, Colors.blue[700]!]
                              : [Colors.blue[500]!, Colors.blue[600]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          label: const Text(
                            'Go Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24, 
                              vertical: 14
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (!isPostNotFound) ...[
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: OutlinedButton.icon(
                            onPressed: _loadPost,
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                            label: Text(
                              'try_again'.tr,
                              style: TextStyle(
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24, 
                                vertical: 14
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
