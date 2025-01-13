import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoFinished = false;
  bool _isVideoInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('Splash Screen başlatılıyor...');
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('Video controller oluşturuluyor...');
      _controller =
          VideoPlayerController.asset('assets/videos/splash_video.mp4');

      print('Video yükleniyor...');
      await _controller.initialize();

      if (!mounted) return;

      _controller.setLooping(false);
      _controller.setVolume(1.0);

      setState(() {
        _isVideoInitialized = true;
        print('Video başarıyla yüklendi');
      });

      _controller.addListener(() {
        final position = _controller.value.position;
        final duration = _controller.value.duration;

        if (position >= duration) {
          if (!_isVideoFinished && mounted) {
            setState(() {
              _isVideoFinished = true;
              print('Video tamamlandı, ana sayfaya yönlendiriliyor...');
            });
          }
        }
      });

      await _controller.play();
      print('Video oynatılmaya başlandı');
    } catch (e) {
      print('Video yükleme hatası: $e');
      setState(() {
        _errorMessage = 'Video yüklenirken bir hata oluştu: $e';
        _isVideoFinished = true;
      });
    }
  }

  @override
  void dispose() {
    print('Video controller kapatılıyor...');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideoFinished) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideoInitialized && _errorMessage.isEmpty)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          if (!_isVideoInitialized && _errorMessage.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Video Yükleniyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          if (_errorMessage.isNotEmpty)
            Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
