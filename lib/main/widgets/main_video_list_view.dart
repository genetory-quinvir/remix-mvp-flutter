import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:html' as html;

import '../../preview/preview_view.dart';

class MainVideoListView extends StatefulWidget {
  const MainVideoListView({super.key, this.title, this.time, required this.videoList, this.didSelect});

  final String? title;
  final String? time;
  final List<XFile> videoList;
  final Function(XFile?)? didSelect;

  @override
  State<MainVideoListView> createState() => _MainVideoListViewState();
}

class _MainVideoListViewState extends State<MainVideoListView> {  
  List<XFile> videoFileList = [];
  XFile? selectedFile;

  Map<String, String> thumbnailCache = {}; 

  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    return buildMainVideoListView();
  }
}

extension MainVideoListViewVideoExtension on _MainVideoListViewState {

Future<String?> generateWebThumbnail(XFile video) async {
  try {
    final bytes = await video.readAsBytes();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrl(blob);
    
    // 비디오 엘리먼트 생성
    final videoElement = html.VideoElement()
      ..src = url
      ..preload = 'auto'
      ..style.position = 'fixed'
      ..style.opacity = '0';
    
    html.document.body?.append(videoElement);
    
    // 비디오 로드 대기
    await videoElement.onLoadedData.first;
    
    // 캔버스 생성 및 썸네일 추출
    final canvas = html.CanvasElement(
      width: videoElement.videoWidth,
      height: videoElement.videoHeight,
    );
    canvas.context2D.drawImage(videoElement, 0, 0);
    
    videoElement.remove();
    html.Url.revokeObjectUrl(url);
    
    return canvas.toDataUrl('image/jpeg', 0.75);
    
    } catch (e) {
      print('Error generating web thumbnail: $e');
      return null;
    }
  }
}

extension MainVideoListViewEventExtension on _MainVideoListViewState {

  void doPreview(XFile video) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // 배경 투명도 조절
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Dialog 배경 투명하게
          insetPadding: EdgeInsets.zero,      // 기본 패딩 제거
          child: PreviewView(video: video, allVideoList: videoFileList),
        );
      },
    );    
  }

  void doSelectVideo(XFile video) {

    setState(() {
      if (selectedFile == video) {
        selectedFile = null;
        widget.didSelect?.call(null);
      } else {
        selectedFile = video;
        widget.didSelect?.call(video);
      }
    });
  }

  void doRemoveVideo(XFile video) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('비디오 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),),
          content: Text('이 비디오를 삭제하시겠습니까?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey[800]),),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  videoFileList.remove(video);
                  thumbnailCache.remove(video.path);
                  widget.didSelect?.call(null);
                });
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

extension MainVideoListViewWidgetExtension on _MainVideoListViewState {

  Widget buildMainVideoThumbnailItemView(XFile video) {
    if (thumbnailCache.containsKey(video.path)) {
      return buildThumbnailView(video, thumbnailCache[video.path]!);
    }

    return FutureBuilder<String?>(
      future: generateWebThumbnail(video).then((thumbnail) {
        if (thumbnail != null) {
          thumbnailCache[video.path] = thumbnail;  // 썸네일 캐시에 저장
        }
        return thumbnail;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && 
            snapshot.data != null) {
          return buildThumbnailView(video, snapshot.data!);
        }
        return const SizedBox(
          width: double.infinity,
          height: 100,
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFf36303),
            ),
          ),
        );
      },
    );
  }

  Widget buildThumbnailView(XFile video, String thumbnailUrl) {
    return Stack(
      alignment: Alignment.center,
      children: [
        InkWell(
          onTap: () => doSelectVideo(video),
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedFile == video ? Color(0xFFf36303) : Colors.transparent,
                width: 4,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Image.network(
                    thumbnailUrl,
                    filterQuality: FilterQuality.low,
                    fit: BoxFit.cover,
                  ),
                ),
                if (selectedFile != video) ...[
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => doPreview(video),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(56),
          ),
          child: const Icon(
            FluentIcons.play_24_filled, 
              size: 24, 
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => doRemoveVideo(video),
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: const Icon(
                  FluentIcons.dismiss_24_regular,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
  
  Widget buildMainVideoThumbnailView() {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          dragging = false;
        });
        
        for (var file in detail.files) {
          final extension = file.name.split('.').last.toLowerCase();
          final allowedExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm'];

          if (allowedExtensions.contains(extension)) {
            setState(() {
              videoFileList.add(file);
              print(videoFileList.length);
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
      child: Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: dragging ? Color(0xFFf36303).withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[100]!,
                blurRadius: 15,
                offset: Offset(0, 0),
              ),
            ],
          ),
        height: 500,
        child: Stack(
          children: [
            ListView.separated(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 88),
            itemBuilder: (context, index) {
              return buildMainVideoThumbnailItemView(videoFileList[index]);
            },
            separatorBuilder: (context, index) {
              return SizedBox(height: 8,);
            },
            itemCount: videoFileList.length,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[100]!,
                      blurRadius: 15,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),),
                    SizedBox(height: 4,),
                    FittedBox(
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(0xFFf36303).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.time ?? '', 
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w600, 
                            color: Color(0xFFf36303)
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget buildMainVideoEmptyView() {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          dragging = false;
        });
        
        for (var file in detail.files) {
          final extension = file.name.split('.').last.toLowerCase();
          final allowedExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm'];

          if (allowedExtensions.contains(extension)) {
            setState(() {
              videoFileList.add(file);
              print(videoFileList.length);
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
      child: Expanded(
        child: SizedBox(
        height: 500,
        child: DottedBorder(
        color: dragging ? Color(0xFFf36303) : Colors.grey[300]!,
        borderType: BorderType.RRect,
        strokeWidth: 1,
        dashPattern: const [12, 8],
        radius: const Radius.circular(8),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              Icon(FluentIcons.video_16_regular, size: 24, color: dragging ? Color(0xFFf36303) : Colors.grey[400],),
              SizedBox(height: 8,),
            Text('영상 파일을\n업로드해주세요.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: dragging ? Color(0xFFf36303) : Colors.grey[400]), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,),
          ],  
        ),
    )))));
  }

  Widget buildMainVideoListView() {
    return videoFileList.isEmpty ? buildMainVideoEmptyView() : buildMainVideoThumbnailView();
  } 

}