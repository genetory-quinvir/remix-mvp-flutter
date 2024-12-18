import 'dart:typed_data';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:html' as html;
import '../result/result_view.dart';
import '../common/common_default_widget.dart';

class ExtractView extends StatefulWidget {
  const ExtractView({super.key, required this.videoList, required this.musicFileList});

  final List<XFile> videoList;
  final List<XFile> musicFileList;

  @override 
  State<ExtractView> createState() => _ExtractViewState();
}

class _ExtractViewState extends State<ExtractView> {

  bool isProcessing = false;
  String? errorMessage;
  double progress = 0;
  double? totalDuration;  // 전체 처리 시간
  double? currentTime;  

  String? videoUrl;  // 생성된 비디오 URL 저장
  bool isCompleted = false;  // 처리 완료 상태

  FFmpeg? ffmpeg;
  bool isLoaded = false;
  bool keepOriginalAudio = false;  // 원본 오디오 유지 여부

  @override
  void initState() {
    super.initState();

    print('widget.videoList: ${widget.videoList}');
    print('widget.musicFileList: ${widget.musicFileList}');

    loadFFmpeg();
  }

  @override
  void dispose() {
    if (videoUrl != null) {
      html.Url.revokeObjectUrl(videoUrl!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultLayout(child: buildExtractView()),
    );
  }
}

extension ExtractViewFFMPEGExtension on _ExtractViewState {

  void _onLogHandler(dynamic log) {  // LogParam 대신 dynamic 사용
    String message = log.message ?? '';
    
    // Duration 정보 파싱
    if (message.contains('Duration:')) {
      // Duration: 00:00:09.00 형식에서 시간 추출
      RegExp durationRegex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})');
      Match? match = durationRegex.firstMatch(message);
      
      if (match != null) {
        int hours = int.parse(match.group(1)!);
        int minutes = int.parse(match.group(2)!);
        int seconds = int.parse(match.group(3)!);
        int milliseconds = int.parse(match.group(4)!) * 10;
        
        totalDuration = (hours * 3600 + minutes * 60 + seconds) * 1000 + milliseconds.toDouble();
        print('총 처리 시간: ${totalDuration}ms');
      }
    }
    
    // 현재 처리 시간 파싱
    if (message.contains('time=')) {
      // time=00:00:03.02 형식에서 시간 추출
      RegExp timeRegex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2})\.(\d{2})');
      Match? match = timeRegex.firstMatch(message);
      
      if (match != null) {
        int hours = int.parse(match.group(1)!);
        int minutes = int.parse(match.group(2)!);
        int seconds = int.parse(match.group(3)!);
        int milliseconds = int.parse(match.group(4)!) * 10;
        
        currentTime = (hours * 3600 + minutes * 60 + seconds) * 1000 + milliseconds.toDouble();
        print('현재 처리 시간: ${currentTime}ms');
      }
    }
  }

  void onProgressHandler(ProgressParam progress) {
    if (totalDuration == null || currentTime == null) return;
    
    // 실제 처리 진행률 계산
    final progressRatio = (currentTime! / totalDuration!).clamp(0.0, 1.0);
    
    setState(() {
      this.progress = progressRatio;
    });
    
    final percentage = (progressRatio * 100).toStringAsFixed(1);
    print('처리 진행률: $percentage% (${(currentTime! / 1000).toStringAsFixed(1)}초 / ${(totalDuration! / 1000).toStringAsFixed(1)}초)');
  }

  Future<void> loadFFmpeg() async {
    ffmpeg = createFFmpeg(
      CreateFFmpegParam(
        log: true,
        corePath: "https://unpkg.com/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js",
      ),
    );

    ffmpeg?.setProgress(onProgressHandler);
    ffmpeg?.setLogger(_onLogHandler);  // 로그 핸들러 추가

    await ffmpeg?.load().then((_) {
      processVideos();
    });

    checkLoaded();
  }
  
  void checkLoaded() {
    setState(() {
      isLoaded = ffmpeg?.isLoaded() ?? false;
    });
  }

  Future<void> processVideos() async {
    try {
      setState(() {
        isProcessing = true;
        progress = 0;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        isProcessing = false;
        progress = 0;
      });
    }
      
      print('비디오 파일 수: ${widget.videoList.length}');
      print('음악 파일 수: ${widget.musicFileList.length}');

      // 비디오 파일들을 FFmpeg 파일시스템에 쓰기
      for (int i = 0; i < widget.videoList.length; i++) {
        final videoData = await widget.videoList[i].readAsBytes();
        print('비디오 $i 데이터 크기: ${videoData.length}');
        ffmpeg?.writeFile('video_$i.mp4', Uint8List.fromList(videoData));
      }

      // 음악 파일 쓰기
      final musicData = await widget.musicFileList[0].readAsBytes();
      print('음악 데이터 크기: ${musicData.length}');
      ffmpeg?.writeFile('music.mp3', Uint8List.fromList(musicData));

      // FFmpeg 명령어 생성
      List<String> command = [];
      
      String filterComplex = '';
      for (int i = 0; i < widget.videoList.length; i++) {
        command.addAll([
          '-ss', '0', 
          '-t', '3', 
          '-i', 'video_$i.mp4'
        ]);
        filterComplex += '[$i:v]scale=640:-2,fps=24[v$i];';
        if (keepOriginalAudio) {
          filterComplex += '[$i:a]volume=1[a$i];';  // 원본 오디오 처리
        }
      }
      
      // 음악 파일 추가 
      command.addAll(['-i', 'music.mp3']);
      
      filterComplex += '${List.generate(widget.videoList.length, (i) => '[v$i]').join('')}concat=n=${widget.videoList.length}:v=1:a=0[v];';

      if (keepOriginalAudio) {
        // 원본 오디오 연결
        filterComplex += '${List.generate(widget.videoList.length, (i) => '[a$i]').join('')}concat=n=${widget.videoList.length}:v=0:a=1[original_audio];';
        // 배경음악과 원본 오디오 믹싱
        filterComplex += '[original_audio][${widget.videoList.length}:a]amix=inputs=2:duration=longest[a]';
      } else {
        // 배경음악만 사용
        filterComplex += '[${widget.videoList.length}:a]aloop=loop=-1:size=2e+09[a]';
      }

      // 필터 복합체 설정
      command.addAll([
        '-filter_complex', filterComplex,
        '-map', '[v]',
        '-map', '[a]',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-threads', '1',
        '-b:v', '800k',
        '-crf', '28',
        '-profile:v', 'baseline',
        '-level', '3.0',
        '-t', '${widget.videoList.length * 3}',
        '-movflags', '+faststart',
        '-shortest',
        '-y',
        'output.mp4'
      ]);

      print('FFmpeg 명령어: ${command.join(' ')}');

      // 기존 출력 파일 제거
      try {
        ffmpeg?.writeFile('output.mp4', Uint8List(0));
      } catch (e) {
        print('기존 출력 파일 제거 중 오류: $e');
      }

      // FFmpeg 실행
      await ffmpeg?.run(command);
      print('FFmpeg 명령어 실행 완료');

      await Future.delayed(Duration(seconds: 1));

      // 출력 파일 처리
  try {
    final outputData = ffmpeg?.readFile('output.mp4');
    print('출력 파일 크기: ${outputData?.length}');

    // Blob URL 생성 및 저장
    final blob = html.Blob([outputData]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // 다운로드 링크 생성
    setState(() {
        isProcessing = false;
        progress = 1.0;
        videoUrl = url;  // URL 저장
        isCompleted = true;
      });

      showResultView(outputData);
    }
    catch (e) {
      print('출력 파일 처리 중 오류: $e');
      setState(() {
        isProcessing = false;
        errorMessage = e.toString();
      });
    }
    finally {
      try {
        for (int i = 0; i < widget.videoList.length; i++) {
          ffmpeg?.writeFile('video_$i.mp4', Uint8List(0));
        }
        ffmpeg?.writeFile('music.mp3', Uint8List(0));
        ffmpeg?.writeFile('output.mp4', Uint8List(0));
      } catch (e) {
        print('임시 파일 정리 중 오류: $e');
      }
    }
  }
}

extension ExtractViewEventExtension on _ExtractViewState {

  void showResultView(Uint8List? outputData) {
    Navigator.of(context).pop();

    showDialog(
      context: context,
      barrierColor: Colors.white,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: ResultView(videoData: outputData), // 결과를 보여줄 새로운 위젯
        );
      },
    );
  }

}

extension ExtractViewWidgetExtension on _ExtractViewState {

  Widget buildExtractView() {
    return Container(
      margin: EdgeInsets.only(top: 160, right: 200, bottom: 160, left: 200),
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Image.asset('assets/images/icon_blender.png'),
            ),
            SizedBox(height: 24),
            if (isProcessing) ...[
              CircularProgressIndicator(
                value: progress,
                color: Color(0xFFf36303),
              ),
              SizedBox(height: 16),
            ],
            if (errorMessage != null) ...[
              Text(
                '오류가 발생했습니다: $errorMessage',
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('지금 ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black, height: 1.8)),
                Text('영상을 제작하고', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black, height: 1.8)),
                Text(' 있어요!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black, height: 1.8)),
              ],
            ),
            Text('빨리 만들어 드릴게요 🔥', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black, height: 1.8)),
          ],
        ),
      ),
    );
  }

}