import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'main_video_list_view.dart';

class MainVideoListContainerView extends StatelessWidget {  // StatefulWidget -> StatelessWidget
  const MainVideoListContainerView({
    super.key,
    required this.videoList,
    this.didSelect,
  });

  final Map<String, List<XFile>> videoList;
  final Function(XFile?, int)? didSelect;

  static const double _spacing = 12.0;
  static const List<_SceneInfo> _scenes = [
    _SceneInfo(title: 'Scene 1', time: '00:00 - 00:03'),
    _SceneInfo(title: 'Scene 2', time: '00:03 - 00:06'),
    _SceneInfo(title: 'Scene 3', time: '00:06 - 00:09'),
    _SceneInfo(title: 'Scene 4', time: '00:09 - 00:12'),
    _SceneInfo(title: 'Scene 5', time: '00:12 - 00:15'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: _spacing),
          _buildSceneList(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      '영상 파일',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildSceneList() {
    return Row(
      children: _scenes.asMap().entries.map((entry) {
        final index = entry.key;
        final scene = entry.value;
        final sceneKey = 'scene${index + 1}';

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: MainVideoListView(
                  title: scene.title,
                  time: scene.time,
                  videoList: videoList[sceneKey] ?? [],
                  didSelect: (file) => didSelect?.call(file, index),
                ),
              ),
              if (index < _scenes.length - 1)
                const SizedBox(width: _spacing),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SceneInfo {
  const _SceneInfo({
    required this.title,
    required this.time,
  });

  final String title;
  final String time;
}