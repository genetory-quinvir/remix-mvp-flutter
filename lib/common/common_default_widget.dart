import 'package:flutter/material.dart';

class DefaultLayout extends StatelessWidget {
  const DefaultLayout({
    super.key,
    required this.child,
  });

  final Widget child;
  static const double _fixedWidth = 1200.0;
  static const double _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: _getContainerWidth(constraints),
            alignment: Alignment.center,
            child: Container(
              width: _fixedWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  double _getContainerWidth(BoxConstraints constraints) {
    return constraints.maxWidth > _fixedWidth 
        ? constraints.maxWidth 
        : _fixedWidth;
  }
}