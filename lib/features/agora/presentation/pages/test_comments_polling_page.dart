import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/live_comments_bloc.dart';
import '../../data/api_service/live_stream_api_service.dart';
import '../../../../core/network/api_client.dart';

/// صفحة اختبار الـ polling للتعليقات
class TestCommentsPollingPage extends StatefulWidget {
  final String liveId;
  
  const TestCommentsPollingPage({Key? key, required this.liveId}) : super(key: key);

  @override
  State<TestCommentsPollingPage> createState() => _TestCommentsPollingPageState();
}

class _TestCommentsPollingPageState extends State<TestCommentsPollingPage> {
  late LiveCommentsBloc _commentsBloc;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commentsBloc = LiveCommentsBloc(
      apiService: LiveStreamApiService(context.read<ApiClient>()),
    );
    
    // تحميل التعليقات وبدء الـ polling
    _commentsBloc.add(LoadLiveComments(postId: widget.liveId));
    _commentsBloc.add(StartLiveCommentsPolling(postId: widget.liveId));

  }

  @override
  void dispose() {
    _commentsBloc.add(StopLiveCommentsPolling());
    _commentsBloc.close();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعليقات البث: ${widget.liveId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _commentsBloc.add(RefreshLiveComments(postId: widget.liveId));
            },
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _commentsBloc,
        child: Column(
          children: [
            // مؤشر الحالة
            BlocBuilder<LiveCommentsBloc, LiveCommentsState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Icon(
                        state is LiveCommentsLoaded 
                          ? Icons.sync 
                          : state is LiveCommentsLoading 
                            ? Icons.sync 
                            : Icons.sync_disabled,
                        color: state is LiveCommentsLoaded 
                          ? Colors.green 
                          : state is LiveCommentsLoading 
                            ? Colors.orange
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state is LiveCommentsLoaded 
                          ? 'تحديث تلقائي نشط (${state.comments.length} تعليق)'
                          : state is LiveCommentsLoading 
                            ? 'جاري التحديث...'
                            : state is LiveCommentsError
                              ? 'خطأ: ${state.message}'
                              : 'غير متصل',
                        style: TextStyle(
                          color: state is LiveCommentsLoaded 
                            ? Colors.green.shade700
                            : state is LiveCommentsLoading 
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // قائمة التعليقات
            Expanded(
              child: BlocBuilder<LiveCommentsBloc, LiveCommentsState>(
                builder: (context, state) {
                  if (state is LiveCommentsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is LiveCommentsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'خطأ في تحميل التعليقات',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _commentsBloc.add(LoadLiveComments(postId: widget.liveId));
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state is LiveCommentsLoaded) {
                    if (state.comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, 
                                 size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد تعليقات بعد',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'كن أول من يعلق!',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      reverse: true,
                      itemCount: state.comments.length,
                      itemBuilder: (context, index) {
                        final comment = state.comments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                comment.userName.isNotEmpty 
                                  ? comment.userName[0].toUpperCase()
                                  : '?',
                              ),
                            ),
                            title: Text(comment.userName),
                            subtitle: Text(comment.text),
                            trailing: Text(
                              comment.timestamp.toString().split(' ')[1].split('.')[0], // عرض الوقت فقط
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        );
                      },
                    );
                  }
                  
                  return const Center(child: Text('جاري التحضير...'));
                },
              ),
            ),
            
            // حقل إضافة تعليق
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'اكتب تعليق...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addComment,
                    child: const Text('إرسال'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      _commentsBloc.add(AddLiveComment(
        postId: widget.liveId,
        text: text,
      ));
      _commentController.clear();
    }
  }
}

/// دالة لفتح صفحة الاختبار
void openTestCommentsPolling(BuildContext context, String liveId) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => TestCommentsPollingPage(liveId: liveId),
    ),
  );
}