import 'package:flutter/material.dart';
import 'package:snginepro/features/feed/data/models/post_audio.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_audio_widget.dart';
/// مثال لاختبار PostAudioWidget
void main() {
  runApp(const AudioTestApp());
}
class AudioTestApp extends StatelessWidget {
  const AudioTestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Widget Test',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const AudioTestPage(),
    );
  }
}
class AudioTestPage extends StatelessWidget {
  const AudioTestPage({super.key});
  @override
  Widget build(BuildContext context) {
    // بيانات وهمية للاختبار
    final testAudio = PostAudio(
      audioId: '1',
      postId: '343',
      source: 'sounds/2025/11/sngine_a76d4949a670070346cf83be10f3472a.mp3',
      views: 1,
      title: 'Sample Audio File',
      duration: const Duration(minutes: 3, seconds: 45),
      size: 2500000, // 2.5 MB
      fileExtension: 'mp3',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Widget Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'PostAudioWidget Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // اختبار الـ Widget الأساسي
            PostAudioWidget(
              audio: testAudio,
              authorName: 'Panchit',
              mediaResolver: (String path) {
                return Uri.parse('https://www.panchit.com/content/uploads/$path');
              },
              showWaveform: true,
              showProgress: true,
              autoPlay: false,
            ),
            const SizedBox(height: 30),
            // اختبار بدون waveform
            const Text(
              'Without Waveform',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            PostAudioWidget(
              audio: testAudio.copyWith(
                title: 'Audio without waveform',
                fileExtension: 'wav',
              ),
              authorName: 'Test User',
              mediaResolver: (String path) {
                return Uri.parse('https://www.panchit.com/content/uploads/$path');
              },
              showWaveform: false,
              showProgress: true,
              autoPlay: false,
            ),
            const SizedBox(height: 30),
            // اختبار بصيغة مختلفة
            const Text(
              'Different Format (M4A)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            PostAudioWidget(
              audio: testAudio.copyWith(
                title: 'M4A Audio File',
                fileExtension: 'm4a',
                duration: const Duration(minutes: 1, seconds: 30),
                size: 1200000,
              ),
              authorName: 'Another User',
              mediaResolver: (String path) {
                return Uri.parse('https://www.panchit.com/content/uploads/$path');
              },
              showWaveform: true,
              showProgress: true,
              autoPlay: false,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}