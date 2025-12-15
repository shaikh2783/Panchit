// import 'package:flutter/material.dart';
// import '../lib/features/agora/presentation/pages/live_stream_viewer_page.dart';

// /// مثال لاختبار صفحة مشاهدة البث المباشر
// /// 
// /// 🎯 هذا المثال يُظهر كيفية استخدام LiveStreamViewerPage
// /// مع معرف القناة الحقيقي والتوكن المطلوب.

// void main() {
//   runApp(MaterialApp(
//     title: 'Live Stream Test',
//     theme: ThemeData.dark(),
//     home: const LiveStreamTestPage(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

// class LiveStreamTestPage extends StatelessWidget {
//   const LiveStreamTestPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // شعار البث المباشر
//               Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   gradient: RadialGradient(
//                     colors: [
//                       Colors.red.withValues(alpha: 0.8),
//                       Colors.red.withValues(alpha: 0.3),
//                     ],
//                   ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.red.withValues(alpha: 0.3),
//                       blurRadius: 20,
//                       spreadRadius: 5,
//                     ),
//                   ],
//                 ),
//                 child: const Icon(
//                   Icons.play_arrow,
//                   color: Colors.white,
//                   size: 60,
//                 ),
//               ),
              
//               const SizedBox(height: 32),
              
//               // العنوان
//               const Text(
//                 'Live Stream Viewer Test',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
              
//               const SizedBox(height: 16),
              
//               const Text(
//                 'اختبار مشاهدة البث المباشر الاحترافي',
//                 style: TextStyle(
//                   color: Colors.white70,
//                   fontSize: 16,
//                 ),
//               ),
              
//               const SizedBox(height: 48),
              
//               // زر بدء المشاهدة
//               ElevatedButton.icon(
//                 onPressed: () => _startLiveStream(context),
//                 icon: const Icon(Icons.video_call),
//                 label: const Text('Join Live Stream'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 16,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   elevation: 5,
//                 ),
//               ),
              
//               const SizedBox(height: 24),
              
//               // معلومات الاختبار
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 32),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: Colors.white.withValues(alpha: 0.2),
//                   ),
//                 ),
//                 child: const Column(
//                   children: [
//                     Text(
//                       '🧪 Test Configuration',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Channel: test-channel-123\n'
//                       'Token: Generated for testing\n'
//                       'Features: Chat, Reactions, Controls',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: 12,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _startLiveStream(BuildContext context) {
//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) {
//           return LiveStreamViewerPage(
//             channelName: 'test-channel-123',
//             token: 'test-token-for-demo', // في الواقع، احصل على التوكن من الخادم
//             broadcasterName: 'محمد أحمد',
//             uid: 12345,
//             viewersCount: 1234,
//             thumbnailUrl: 'https://picsum.photos/400/300?random=1',
//             broadcasterAvatar: 'https://picsum.photos/100/100?random=2',
//             isVerified: true,
//           );
//         },
//         transitionDuration: const Duration(milliseconds: 400),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return SlideTransition(
//             position: animation.drive(
//               Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).chain(
//                 CurveTween(curve: Curves.easeOut),
//               ),
//             ),
//             child: child,
//           );
//         },
//       ),
//     );
//   }
// }