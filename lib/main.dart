import 'package:flutter/material.dart';
import 'package:remix_mvp/common/common_default_widget.dart';
import 'main/main_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      theme: ThemeData(
        fontFamily: 'NotoSansKR',
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: DefaultLayout(child: MainView()),
        // body: LayoutBuilder(
        //   builder: (context, constraints) {
        //     return SingleChildScrollView(
        //       scrollDirection: Axis.horizontal,
        //       child: Container(
        //         width: constraints.maxWidth > 1200 ? constraints.maxWidth : 1200,
        //         alignment: Alignment.center,
        //         child: Container(
        //           width: 1200,
        //           padding: EdgeInsets.symmetric(horizontal: 16),
        //           child: MainView(),
        //         ),
        //       ),
        //     );
        //   },
        // ),
      ),
    );
  }
}