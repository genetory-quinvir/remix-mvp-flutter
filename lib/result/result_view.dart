import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../common/common_default_widget.dart';
import '../common/common_rounded_button.dart';
import 'dart:html' as html;

class ResultView extends StatefulWidget {
  const ResultView({super.key, required this.videoData});
  final Uint8List? videoData;

  @override
  _ResultViewState createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 160),
        color: Colors.white,
        child: Column(
          children: [
            _buildTitle(),
            SizedBox(height: 24),
            _buildVideoPlayer(),
            SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // 비디오 초기화
  Future<void> _initializeVideo() async {
    final blob = html.Blob([widget.videoData]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer(url).then((_) {
        if (mounted) setState(() => _isPlaying = true);
      }).catchError((error) {
        print('Error initializing player: $error');
        if (mounted) setState(() => _isPlaying = false);
      });
    });
  }

  // 플레이어 초기화
  Future<void> _initializePlayer(String videoUrl) async {
    try {
      await _disposeControllers();
      await _setupNewControllers(videoUrl);
      _setupVideoListener();
    } catch (e) {
      print('Error initializing player: $e');
      rethrow;
    }
  }

  // 기존 컨트롤러 정리
  Future<void> _disposeControllers() async {
    if (_chewieController != null) {
      await _chewieController!.pause();
      _chewieController!.dispose();
      _chewieController = null;
    }
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  // 새 컨트롤러 설정
  Future<void> _setupNewControllers(String videoUrl) async {
    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController!.initialize();
    
    if (!mounted) return;

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoController!.value.aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
    );
  }

  // 비디오 리스너 설정
  void _setupVideoListener() {
    _videoController!.addListener(() {
      if (_videoController!.value.position >= _videoController!.value.duration) {
        if (mounted) setState(() => _isPlaying = false);
      }
    });
  }

  // UI 위젯들
  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('영상 제작이 완료', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        Text('되었어요 🎉', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: 640,
      height: 480,
      color: Colors.black,
      child: _chewieController != null 
        ? Chewie(controller: _chewieController!)
        : const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFf36303),
            ),
          ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CommonRoundedButton(
            title: '다시 제작하기',
            bgColor: Colors.grey[200]!,
            titleColor: Colors.grey[600]!,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 12),
          CommonRoundedButton(
            title: '다운로드 받기',
            bgColor: Colors.grey[200]!,
            titleColor: Colors.grey[600]!,
            onTap: _downloadVideo,
          ),
          SizedBox(width: 12),
          CommonRoundedButton(
            title: '피드에 공유하기',
            bgColor: Color(0xFFf36303),
            titleColor: Colors.white,
            onTap: _showShareDialog,
          ),
        ],
      ),
    );
  }

  // 액션 메서드들
  void _downloadVideo() {
    final blob = html.Blob([widget.videoData]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'merged_video.mp4')
      ..click();
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text('피드에 공유하기', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('아직 준비중입니다.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}