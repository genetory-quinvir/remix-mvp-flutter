import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class CommonTopView extends StatelessWidget {  // StatefulWidget -> StatelessWidget
  const CommonTopView({
    super.key,
    required this.title,
    required this.canClose,
    this.onBack,
  });

  final String title;
  final bool canClose;
  final VoidCallback? onBack;

  static const double _height = 50.0;
  static const double _leftPadding = 16.0;
  static const double _titleFontSize = 16.0;
  static const double _iconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: _leftPadding),
      color: Colors.white,
      width: double.infinity,
      height: _height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: _titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (canClose)
            SizedBox(
              width: _height,  // 정사각형 버튼을 위해 height와 동일하게
              height: _height,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  FluentIcons.dismiss_24_regular,
                  size: _iconSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}