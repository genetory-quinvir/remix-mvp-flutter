
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../common/common_default_widget.dart';
import '../common/common_top_view.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class PreviewView extends StatefulWidget {
  const PreviewView({
    super.key, 
    required this.video, 
    required this.allVideoList
  });

  final XFile video;
  final List<XFile> allVideoList;

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  XFile? _selectedFile;
  final Map<String, String> _thumbnailCache = {};
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.video;
    _initializeSelectedVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(child: _buildMainView());
  }

  // 비디오 초기화 관련 메서드
  Future<void> _initializeSelectedVideo() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer(_selectedFile!).then((_) {
        if (mounted) setState(() => _isPlaying = true);
      }).catchError((error) {
        print('비디오 초기화 오류: $error');
        if (mounted) setState(() => _isPlaying = false);
      });
    });
  }

  Future<void> _initializePlayer(XFile video) async {
    try {
      await _disposeCurrentControllers();
      await _setupNewControllers(video);
      _setupVideoListener();
    } catch (e) {
      print('플레이어 초기화 오류: $e');
      rethrow;
    }
  }

  Future<void> _disposeCurrentControllers() async {
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

  Future<void> _setupNewControllers(XFile video) async {
    final bytes = await video.readAsBytes();
    final blob = web.Blob([bytes] as JSArray<web.BlobPart>);
    final url = web.URL.createObjectURL(blob);
    
    _videoController = VideoPlayerController.network(url);
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

  void _setupVideoListener() {
    _videoController!.addListener(() {
      if (_videoController!.value.position >= _videoController!.value.duration) {
        if (mounted) setState(() => _isPlaying = false);
      }
    });
  }

  // 썸네일 관련 메서드
  Future<String?> _generateThumbnail(XFile video) async {
    try {
      final bytes = await video.readAsBytes();
      final blob = web.Blob([bytes] as JSArray<web.BlobPart>);
      final url = web.URL.createObjectURL(blob);
      
      final videoElement = web.HTMLVideoElement()
        ..src = url
        ..preload = 'auto'
        ..style.position = 'fixed'
        ..style.opacity = '0';
      
      web.document.body?.append(videoElement);
      await videoElement.onLoadedData.first;
      
      final canvas = web.HTMLCanvasElement()
        ..width = videoElement.videoWidth
        ..height = videoElement.videoHeight;
      canvas.context2D.drawImage(videoElement, 0, 0);
      
      videoElement.remove();
      web.URL.revokeObjectURL(url);
      
      return canvas.toDataUrl('image/jpeg', 0.75);
    } catch (e) {
      print('썸네일 생성 오류: $e');
      return null;
    }
  }

  // 이벤트 핸들러
  void _handleVideoSelect(XFile video) async {
    try {
      await _initializePlayer(video);
      setState(() {
        _selectedFile = video;
        _isPlaying = true;
      });
    } catch (e) {
      print('비디오 선택 오류: $e');
      setState(() {
        _selectedFile = video;
        _isPlaying = false;
      });
    }
  }

  // UI 빌더 메서드
  Widget _buildMainView() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 200, vertical: 160),
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          CommonTopView(
            title: 'Preview',
            canClose: true,
            onBack: () => Navigator.pop(context),
          ),
          _buildVideoPlayer(),
          _buildVideoList(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12),
        color: Colors.black,
        child: _selectedFile != null 
          ? _buildVideoPlayerContent()
          : Center(
              child: Text('선택된 비디오가 없습니다',
                style: TextStyle(color: Colors.white)),
            ),
      ),
    );
  }

  Widget _buildVideoPlayerContent() {
    if (_videoController?.value.isInitialized ?? false) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: _chewieController != null 
          ? Chewie(controller: _chewieController!)
          : _buildLoadingIndicator(),
      );
    }
    return _buildLoadingIndicator();
  }

  Widget _buildVideoList() {
    return Container(
      margin: EdgeInsets.all(12),
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.allVideoList.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (_, index) => InkWell(
          onTap: () => _handleVideoSelect(widget.allVideoList[index]),
          child: _buildVideoThumbnail(widget.allVideoList[index]),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(XFile video) {
    if (_thumbnailCache.containsKey(video.path)) {
      return _buildThumbnailContent(video, _thumbnailCache[video.path]!);
    }

    return FutureBuilder<String?>(
      future: _generateThumbnail(video).then((thumbnail) {
        if (thumbnail != null) {
          _thumbnailCache[video.path] = thumbnail;
        }
        return thumbnail;
      }),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return _buildThumbnailContent(video, snapshot.data!);
        }
        return _buildLoadingIndicator();
      },
    );
  }

  Widget _buildThumbnailContent(XFile video, String thumbnailUrl) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 160,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedFile == video 
                ? Color(0xFFf36303) 
                : Colors.transparent,
              width: 4,
            ),
          ),
          child: Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
          ),
        ),
        _buildPlayButton(small: true),
      ],
    );
  }

  Widget _buildPlayButton({bool small = false}) {
    return Container(
      width: small ? 40 : 100,
      height: small ? 40 : 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(56),
      ),
      child: Icon(
        FluentIcons.play_24_filled,
        size: small ? 24 : 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        color: Color(0xFFf36303),
      ),
    );
  }
}