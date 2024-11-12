import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DownloadScreen2 extends StatefulWidget {
  const DownloadScreen2({super.key});

  @override
  _DownloadScreen2State createState() => _DownloadScreen2State();
}

class _DownloadScreen2State extends State<DownloadScreen2> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  double _progress = 0.0;
  String _remainingTime = "Calculating...";
  double _totalSize = 0.0;
  double _remainingSize = 0.0;
  int _lastUpdate = 0;
  bool _isDownloading = false;
  bool _isPaused = false;
  int _downloadedBytes = 0;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> _showDownloadNotification(int progress) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'download_channel',
      'File Download',
      channelDescription: 'Shows progress of file download',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress, // Dynamically assigned progress
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      'Downloading File',
      'Progress: $progress%',
      platformChannelSpecifics,
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _isPaused = false;
    });

    _cancelToken = CancelToken();
    final Dio _dio = Dio();
    const directory = "storage/emulated/0/download";
    const filePath = '$directory/kali-installer.iso';

    final stopwatch = Stopwatch()..start();

    try {
      await _dio.download(
        'https://cdimage.kali.org/kali-2024.2/kali-linux-2024.2-installer-netinst-amd64.iso',
        filePath,
        cancelToken: _cancelToken,
        options: Options(
          headers: _downloadedBytes > 0 ? {'Range': 'bytes=$_downloadedBytes-'} : null,
        ),
        onReceiveProgress: (receivedBytes, totalBytes) async {
          if (_cancelToken!.isCancelled) return;

          if (_isPaused) {
            _downloadedBytes = receivedBytes;
            stopwatch.stop();
            return;
          }

          if (totalBytes != -1) {
            final elapsedSeconds = stopwatch.elapsed.inSeconds;

            // if (elapsedSeconds - _lastUpdate >= 1) //it will update ui after 1 second
            // {
              setState(() {
                _totalSize = totalBytes * 0.00000095367432;
                _remainingSize = _totalSize - (receivedBytes * 0.00000095367432);
                _progress = receivedBytes / totalBytes;

                final estimatedTotalTime = (elapsedSeconds / _progress).round();
                final remainingSeconds = estimatedTotalTime - elapsedSeconds;

                final minutes = (remainingSeconds / 60).floor();
                final seconds = remainingSeconds % 60;
                _remainingTime =
                '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
              });

              int progressPercentage = (_progress * 100).toInt();
              _showDownloadNotification(progressPercentage);

            //   _lastUpdate = elapsedSeconds;
            // }
          }
        },
      );

      setState(() {
        _isDownloading = false;
      });
      await flutterLocalNotificationsPlugin.cancel(0);
    } catch (e) {
      print(e);
      if (e is DioError && e.type == DioErrorType.cancel) {
        print("Download canceled");
      }
    }
  }

  void _pauseDownload() {
    setState(() {
      _isPaused = true;
    });
    _cancelToken?.cancel("Paused by user");
  }

  void _resumeDownload() {
    setState(() {
      _isPaused = false;
    });
    _startDownload();
  }

  void _cancelDownload() {
    _cancelToken?.cancel("Canceled by user");
    setState(() {
      _isDownloading = false;
      _isPaused = false;
      _progress = 0.0;
      _remainingTime = "Calculating...";
      _totalSize = 0.0;
      _remainingSize = 0.0;
      _downloadedBytes = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Download')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 20),
            Text(
              'Progress: ${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Remaining Time: $_remainingTime',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Total Size: ${_totalSize.toStringAsFixed(0)} MB',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Remaining Size: ${_remainingSize.toStringAsFixed(0)} MB',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            _isDownloading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isPaused ? _resumeDownload : _pauseDownload,
                  child: Text(_isPaused ? 'Resume' : 'Pause'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _cancelDownload,
                  child: const Text('Cancel'),
                ),
              ],
            )
                : ElevatedButton(
              onPressed: _startDownload,
              child: const Text('Start Download'),
            ),
          ],
        ),
      ),
    );
  }
}
