import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import '../common/common_top_view.dart';
import '../extract/extract_view.dart';
import 'widgets/main_button_view.dart';
import 'widgets/main_sound_view.dart';
import 'widgets/main_video_list_container_view.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  static const double _verticalSpacing = 24.0;
  static const double _horizontalMargin = 200.0;
  static const double _topSpacing = 32.0;
  static const double _bottomSpacing = 48.0;

  final List<XFile> _musicFiles = [];
  final Map<String, List<XFile>> _videoList = {
    for (int i = 1; i <= 5; i++) 'scene$i': [],
  };

  bool get _canExtract => 
    _videoList.values.every((videos) => videos.isNotEmpty) && 
    _musicFiles.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          SizedBox(height: _topSpacing),
          Expanded(child: _buildContent()),
          SizedBox(height: _verticalSpacing),
          _buildFooter(),
          SizedBox(height: _bottomSpacing),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const CommonTopView(
      title: 'Hence Remix MVP',
      canClose: false,
    );
  }

  Widget _buildContent() {
    return Container( 
      margin: const EdgeInsets.symmetric(horizontal: _horizontalMargin),
      child: Column(
        children: [
          _buildSoundSection(),
          const SizedBox(height: _verticalSpacing),
          _buildVideoSection(),
        ],
      ),
    );
  }

  Widget _buildSoundSection() {
    return MainSoundView(
      didSelect: _handleSoundSelect,
    );
  }

  Widget _buildVideoSection() {
    return MainVideoListContainerView(
      videoList: _videoList,
      didSelect: _handleVideoSelect,
    );
  }

  Widget _buildFooter() {
    return MainButtonView(
      didReset: _showResetDialog,
      didExtract: _handleExtract,
      canExtract: _canExtract,
    );
  }

  void _handleSoundSelect(XFile? file) {
    setState(() {
      _musicFiles.clear();
      if (file != null) {
        _musicFiles.add(file);
      }
    });
  }

  void _handleVideoSelect(XFile? file, int index) {
    setState(() {
      final sceneKey = 'scene${index + 1}';
      _videoList[sceneKey] = file != null ? [file] : [];
    });
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text(
          '작업 초기화',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '모든 작업을 초기화 하시겠어요?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey[800],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: _handleReset,
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFFf36303)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleReset() {
    setState(() {
      _videoList.forEach((key, _) => _videoList[key] = []);
    });
    Navigator.pop(context);
  }

  void _handleExtract() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: ExtractView(
          videoList: _videoList.values
              .expand((videos) => videos)
              .toList(),
          musicFileList: _musicFiles,
        ),
      ),
    );
  }
}