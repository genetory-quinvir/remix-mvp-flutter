import 'package:flutter/material.dart';

class CommonRoundedButton extends StatelessWidget {  // StatefulWidget -> StatelessWidget
  const CommonRoundedButton({
    super.key,
    required this.title,
    this.titleColor = Colors.white,
    this.bgColor = Colors.purple,
    this.isDisabled = false,
    this.onTap,
  });

  final String title;
  final Color titleColor;
  final Color bgColor;
  final bool isDisabled;
  final VoidCallback? onTap;

  static const double _minWidth = 120.0;
  static const double _height = 40.0;
  static const double _borderRadius = 8.0;
  static const double _horizontalPadding = 24.0;
  static const double _fontSize = 14.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: isDisabled ? null : onTap,  // 비활성화 시 onTap도 null 처리
      child: Container(
        constraints: const BoxConstraints(minWidth: _minWidth),
        height: _height,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: _fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    return isDisabled ? Colors.grey[200]! : bgColor;
  }

  Color _getTextColor() {
    return isDisabled ? Colors.grey[400]! : titleColor;
  }
}