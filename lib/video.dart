import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'camera.dart';

class Video extends StatefulWidget {
  const Video({Key? key, required this.cameras}) : super(key: key);

  final List<CameraDescription>? cameras;

  @override
  State<Video> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  late CameraController _cameraController;
  bool _isRearCameraSelected = true;
  late File videoFile;
  late bool _isRecording = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initCamera(widget.cameras![0]);
  }

  Future<void> startRecording() async {
    if (!_cameraController.value.isInitialized || _cameraController.value.isRecordingVideo) {
      return;
    }
    try {
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } on CameraException catch (e) {
      debugPrint('Error occurred while starting video recording: $e');
      return null;
    }
  }

  static Future<String?> compressVideo(File file) async {
    try {
      await VideoCompress.setLogLevel(0);
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        includeAudio: true,
        deleteOrigin: true,
      );
      if (mediaInfo != null) {
        return mediaInfo.path;
      }
    } catch (e) {
      VideoCompress.cancelCompression();
    }
    return null;
  }

  Future<void> stopRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      return;
    }
    try {
      final XFile file = await _cameraController.stopVideoRecording();
      final File vfile = File(file.path);

      // Save the video file to cache directory
      final appDir = await getTemporaryDirectory();
      final cacheVideoPath = '${appDir.path}/compressed_video.mp4';
      await vfile.copy(cacheVideoPath);

      final String? compressedFilePath = await compressVideo(File(cacheVideoPath));
      if (compressedFilePath != null) {
        final File compressedFile = File(compressedFilePath);
        setState(() {
          _isRecording = false;
          videoFile = compressedFile;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewPage(videoFile: videoFile, originalFileSize: vfile.lengthSync()),
          ),
        );
      }
    } on CameraException catch (e) {
      debugPrint('Error occurred while stopping video recording: $e');
      return null;
    }
  }

  Future<void> initCamera(CameraDescription cameraDescription) async {
    _cameraController = CameraController(cameraDescription, ResolutionPreset.high);
    try {
      await _cameraController.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    } on CameraException catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _cameraController.value.isInitialized
                ? CameraPreview(_cameraController)
                : Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    IconButton(
                      icon: Icon(
                        _isRearCameraSelected ? Icons.camera_rear : Icons.camera_front,
                        color: Colors.blue[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isRearCameraSelected = !_isRearCameraSelected;
                          _cameraController.dispose();
                          initCamera(
                              _isRearCameraSelected ? widget.cameras![0] : widget.cameras![1]);
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.fiber_manual_record,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        if (_isRecording) {
                          stopRecording();
                        } else {
                          startRecording();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key, required this.videoFile, required this.originalFileSize}) : super(key: key);

  final File videoFile;
  final int originalFileSize;

  @override
  _PreviewPageState createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  late VideoPlayerController _videoPlayerController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future<void> _playPauseVideo() async {
    if (_videoPlayerController.value.isPlaying) {
      await _videoPlayerController.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _videoPlayerController.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Page')),
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: VideoPlayer(_videoPlayerController),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5 - 48, // Adjust the top position based on your requirements
              left: MediaQuery.of(context).size.width * 0.5 - 48, // Adjust the left position based on your requirements
              child: FloatingActionButton(
                onPressed: _playPauseVideo,
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                backgroundColor: Colors.transparent,
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  SizedBox(height: 10,),
                  FutureBuilder<Duration>(
                    future: VideoPlayerWidget.getVideoDuration(widget.videoFile),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasData) {
                        return Text(
                          'Video Duration: ${getFormattedDuration(snapshot.data!)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Text(
                          'Failed to get video duration',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                 SizedBox(height: 20),
                  Text(
                    'Original Video Size: ${getFormattedFileSize(widget.originalFileSize)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  FutureBuilder<String>(
                    future: VideoPlayerWidget.getVideoFileSize(widget.videoFile),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasData) {
                        return Text(
                          'Compressed Video Size: ${getFormattedFileSize(int.parse(snapshot.data!))}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Failed to get compressed video size',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                  SizedBox(height: 20),
                  const TextField(
                    keyboardType: TextInputType.multiline,
                    maxLines: 8,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        copyFile(widget.videoFile.path, '/storage/emulated/0/Download/dev');
                      },
                      icon: Icon(Icons.send),
                      label: Text('Send'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  String getFormattedFileSize(int fileSizeInBytes) {
    double sizeInKB = fileSizeInBytes / 1024;
    if (sizeInKB < 1024) {
      return sizeInKB.toStringAsFixed(2) + ' KB';
    }
    double sizeInMB = sizeInKB / 1024;
    return sizeInMB.toStringAsFixed(2) + ' MB';
  }

  String getFormattedDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}


class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({Key? key, required this.videoFile}) : super(key: key);

  final File videoFile;

  static Future<String> getVideoFileSize(File file) async {
    int size = await file.length();
    return size.toString();
  }

  static Future<Duration> getVideoDuration(File file) async {
    VideoPlayerController videoPlayerController = VideoPlayerController.file(file);
    await videoPlayerController.initialize();
    Duration duration = videoPlayerController.value.duration;
    videoPlayerController.dispose();
    return duration;
  }

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(_videoPlayerController);
  }
}