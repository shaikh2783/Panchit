// import 'package:flutter/material.dart';
// import '../features/feed/data/models/post_audio.dart';
// import '../features/feed/presentation/widgets/post_audio_widget.dart';

// void main() {
//   runApp(const RealAudioTestApp());
// }

// class RealAudioTestApp extends StatelessWidget {
//   const RealAudioTestApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Real Audio Player Test',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         brightness: Brightness.light,
//       ),
//       darkTheme: ThemeData(
//         brightness: Brightness.dark,
//         primarySwatch: Colors.blue,
//       ),
//       home: const AudioTestPage(),
//     );
//   }
// }

// class AudioTestPage extends StatelessWidget {
//   const AudioTestPage({super.key});

//   // محلل URI للملفات الصوتية - يستخدم ملفات عامة للاختبار
//   Uri _resolveAudioUri(String source) {
//     if (source.startsWith('http')) {
//       return Uri.parse(source);
//     }
//     // إضافة URL أساسي إذا كان المسار نسبي
//     return Uri.parse('https://commondatastorage.googleapis.com/codeskulptor-assets/$source');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Real Audio Player Test'),
//         elevation: 0,
//         backgroundColor: Theme.of(context).primaryColor,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'اختبار مشغل الصوت الحقيقي',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
            
//             const Text(
//               'هذا المشغل يدعم تشغيل الملفات الصوتية الفعلية باستخدام audioplayers',
//               style: TextStyle(fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),

//             // ملف MP3 تجريبي
//             _buildAudioCard(
//               'Sample Music',
//               'https://commondatastorage.googleapis.com/codeskulptor-assets/Erase.mp3',
//               const Duration(seconds: 30),
//               'MP3',
//               1024 * 200, // 200KB
//             ),
//             const SizedBox(height: 20),

//             // ملف OGG تجريبي  
//             _buildAudioCard(
//               'Sample Soundtrack',
//               'https://commondatastorage.googleapis.com/codeskulptor-assets/Epoq-Lepidoptera.ogg',
//               const Duration(seconds: 45),
//               'OGG',
//               1024 * 500, // 500KB
//             ),
//             const SizedBox(height: 20),

//             // ملف محلي (سيفشل في التحميل - لاختبار معالجة الأخطاء)
//             _buildAudioCard(
//               'Local File (Error Test)',
//               '/local/file/does-not-exist.mp3',
//               const Duration(seconds: 60),
//               'MP3',
//               1024 * 1024, // 1MB
//             ),

//             const SizedBox(height: 40),
//             const Text(
//               'ملاحظات:\n'
//               '• استخدام مكتبة audioplayers بدلاً من just_audio لسهولة الإعداد\n'
//               '• زر التشغيل يعرض حالة التحميل أثناء تحميل الملف\n'
//               '• رسالة خطأ تظهر إذا فشل التحميل\n'
//               '• يمكن إعادة المحاولة بالضغط على زر التشغيل\n'
//               '• التحكم الحقيقي في التشغيل والإيقاف',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAudioCard(
//     String title,
//     String source,
//     Duration duration,
//     String format,
//     int sizeBytes,
//   ) {
//     final audio = PostAudio(
//       id: title.hashCode.toString(),
//       source: source,
//       title: title,
//       duration: duration,
//       fileSize: sizeBytes,
//       fileExtension: format.toLowerCase(),
//       views: 0,
//     );

//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: PostAudioWidget(
//           audio: audio,
//           authorName: 'مختبر الصوت',
//           mediaResolver: _resolveAudioUri,
//           showWaveform: true,
//           showProgress: true,
//           autoPlay: false,
//         ),
//       ),
//     );
//   }
// }