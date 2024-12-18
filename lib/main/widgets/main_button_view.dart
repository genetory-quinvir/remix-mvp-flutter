import 'package:flutter/material.dart';
import '../../common/common_rounded_button.dart';

class MainButtonView extends StatelessWidget {  // StatefulWidget -> StatelessWidget
  const MainButtonView({
    super.key, 
    this.didReset, 
    this.didExtract, 
    this.canExtract = false,
  });

  final VoidCallback? didReset;
  final VoidCallback? didExtract;
  final bool canExtract;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CommonRoundedButton(
            title: '초기화하기',
            bgColor: const Color.fromRGBO(238, 238, 238, 1),
            titleColor: Colors.black,
            onTap: didReset,
          ),
          const SizedBox(width: 12),
          CommonRoundedButton(
            title: '리믹스 영상 추출하기',
            bgColor: const Color(0xFFf36303),
            titleColor: Colors.white,
            isDisabled: !canExtract,
            onTap: didExtract,
          ),
        ],
      ),
    );
  }
}