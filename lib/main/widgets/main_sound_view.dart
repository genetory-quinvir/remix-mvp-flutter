import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:html' as html;  // html import 추가
import 'dart:math' show max, min, pi, sin, sqrt;

class MainSoundView extends StatefulWidget {
  const MainSoundView({super.key, this.didSelect});

  final Function(XFile?)? didSelect;

  @override
  State<MainSoundView> createState() => _MainSoundViewState();
}

class _MainSoundViewState extends State<MainSoundView> {

  List<XFile> musicFileList = [];
  List<double> waveformData = [];  // 파형 데이터 저장
  Map<String, AudioPlayer> audioPlayers = {};  // 오디오 플레이어 맵
  Map<String, String> audioUrls = {};  // URL 저장용 맵
  bool isPlaying = false;
  bool dragging = false;

  @override
  void dispose() {
    for (var player in audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildMainSoundView();
  }
}

extension MainSoundViewEventExtension on _MainSoundViewState {

void doStop() {
  if (musicFileList.isEmpty) return;
  
  final fileName = musicFileList[0].name;
  final player = audioPlayers[fileName];
  
  if (player != null) {
    try {
      player.stop();
      player.seek(Duration.zero);  // 재생 위치를 처음으로 되돌림
      
      setState(() {
        isPlaying = false;
      });
    } catch (e) {
      print('Error stopping audio: $e');
      setState(() {
        isPlaying = false;
      });
    }
  }
}

void doPlay() {
  if (musicFileList.isEmpty) return;
  
  final fileName = musicFileList[0].name;
  final player = audioPlayers[fileName];
  
  if (player != null) {
    try {
      if (isPlaying) {
        player.pause();
      } else {
        player.play();
      }

      setState(() {
        isPlaying = player.playing;
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
          isPlaying = false;
        }); 
      }
    }
  }
  
  String formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void doRemoveSound() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('음원 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),),
          content: Text('이 음원을 삭제하시겠습니까?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey[800]),),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                musicFileList = [];
                widget.didSelect?.call(null);
                setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text('확인', style: TextStyle(color: Color(0xFFf36303))),
            ),
          ],
        );
      },
    );
  }
}

extension MainSoundViewAudioExtension on _MainSoundViewState {

  Future<List<double>> extractWaveform(XFile file) async {
    try {
      final player = AudioPlayer();
      final bytes = await file.readAsBytes();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrl(blob);
      
      await player.setUrl(url);
      await player.load();
      
      final pcmData = await convertToPCM(bytes);
      final pointCount = 1500; // 15초 * 100포인트/초로 증가
      final duration = player.duration ?? Duration(seconds: 15);
      final maxDurationInSeconds = 15.0;
      
      // 실제 재생 시간이 15초보다 길 경우 15초만 사용
      final effectiveDuration = min(duration.inMilliseconds / 1000, maxDurationInSeconds);
      final effectivePointCount = (pointCount * (effectiveDuration / maxDurationInSeconds)).round();
      final samplesPerPoint = pcmData.length ~/ effectivePointCount;
      
      var samples = <double>[];
      
      for (var i = 0; i < effectivePointCount; i++) {
        var sum = 0.0;
        var count = 0;
        final start = i * samplesPerPoint;
        final end = min((i + 1) * samplesPerPoint, pcmData.length);
        
        for (var j = start; j < end; j++) {
          sum += pcmData[j] * pcmData[j];
          count++;
        }
        
        final rms = count > 0 ? sqrt(sum / count) : 0.0;
        samples.add(rms);
      }

      // 15초에 맞춰 샘플 수 조정
      while (samples.length < pointCount) {
        samples.add(0.2); // 부족한 부분은 최소값으로 채움
      }
      
      await player.dispose();
      html.Url.revokeObjectUrl(url);
      
      return samples;
      
    } catch (e) {
      print('Error extracting waveform: $e');
      return List.generate(1500, (index) => 0.5);
    }
  }
  
  Future<List<double>> convertToPCM(List<int> bytes) async {
    try {
      // 16비트 PCM으로 변환
      final pcmData = <double>[];
      for (var i = 0; i < bytes.length - 1; i += 2) {
        // 16비트 리틀 엔디안으로 읽기
        final sample = (bytes[i + 1] << 8) | bytes[i];
        // -1.0 ~ 1.0 범위로 정규화
        pcmData.add(sample / 32768.0);
      }
      return pcmData;
    } catch (e) {
      print('Error converting to PCM: $e');
      rethrow;
    }
  }
  
  Future<void> initWebAudio(XFile file) async {
    try {
      final player = AudioPlayer();
      final bytes = await file.readAsBytes();  
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrl(blob);
    
      audioUrls[file.name] = url;
      
      // 파형 데이터 추출
      final samples = await extractWaveform(file);
      print('samples: $samples');
      setState(() {
        waveformData = samples;  // 파형 데이터 저장
      });
      
      await player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      audioPlayers[file.name] = player;    
    } catch (e) {
      print('Error initializing web audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오디오 파일 초기화 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}

extension MainSoundViewWidgetExtension on _MainSoundViewState {

  Widget buildTitleView() {
    return Text('음성 파일', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey[400]), textAlign: TextAlign.left,); 
  }

  Widget buildSoundPlayView(String fileName) {
    final player = audioPlayers[fileName];

    return SizedBox(
      width: double.infinity,
      height: 120,
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: doStop,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
              ),
              width: 32,
              height: 32,
              child: Icon(FluentIcons.stop_24_filled, size: 16, color: Colors.white,),
                ),
              ),
              SizedBox(width: 12,),
              InkWell(
                onTap: doPlay,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                ),
                width: 32,
                height: 32,
                child: Icon(
                  isPlaying 
                    ? FluentIcons.pause_24_filled 
                    : FluentIcons.play_24_filled,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12,),
              StreamBuilder<Duration?>(
                stream: player?.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = player?.duration ?? Duration.zero;
                  return Text(
                    '${formatDuration(position)} / ${formatDuration(duration)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black
                    ),
                  );
                },
              ),
              SizedBox(width: 16,),
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 32,
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: doRemoveSound,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('음원 삭제하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]), textAlign: TextAlign.left,)
                  )
                )
              ),
            ],
          ),
          SizedBox(height: 24,),
          StreamBuilder<Duration?>(
            stream: player?.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return PolygonWaveform(
                samples: waveformData,
                width: 770,
                height: 48,
                style: PaintingStyle.fill,
                activeColor: Colors.black,
                  inactiveColor: const Color.fromRGBO(117, 117, 117, 1),
                  maxDuration: Duration(seconds: 15),
                  elapsedDuration: position,
                  absolute: true,
                  invert: false,  
                );
              },
            ),
        ],
      ),
    );
  }

  Widget buildSoundEmptyView() {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          dragging = false;
        });
        
        for (var file in detail.files) {
          final extension = file.name.split('.').last.toLowerCase();
          final allowedExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'wma', 'flac'];

          if (allowedExtensions.contains(extension)) {
            await initWebAudio(file);
            setState(() {
              musicFileList.add(file);
              widget.didSelect?.call(file);
            });
          } else {
            dragging = false;
          }
        }
      },
      onDragEntered: (detail) {
        setState(() {
          dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          dragging = false;
        });
      },
      child: SizedBox(
        width: double.infinity,
        height: 120,
        child: DottedBorder(
        color: dragging ? Color(0xFFf36303) : Colors.grey[300]!,
        borderType: BorderType.RRect,
        strokeWidth: 1,
        dashPattern: const [12, 8],
        radius: const Radius.circular(8),
        child: Center(
          child: Row  ( 
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            Icon(FluentIcons.music_note_2_24_regular, size: 24, color: dragging ? Color(0xFFf36303) : Colors.grey[400],),
            SizedBox(width: 8,),
            Text('음성 파일을 업로드해주세요.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: dragging ? Color(0xFFf36303) : Colors.grey[400]),),
          ],
        ),
        ),
      ),
    ));
  }

  Widget buildMainSoundView() {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitleView(),
          SizedBox(height: 12,),
          if (musicFileList.isEmpty) ...[
            buildSoundEmptyView(),
          ] else ...[
            buildSoundPlayView(musicFileList[0].name),
          ],
        ],
      ),
    );
  }

}