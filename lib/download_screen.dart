import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  double _progress = 0.0;
  String _remainingTime = "Calculating...";
  double _totalSize = 0.0;
  double _remainingSize = 0.0;

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
    final Dio _dio = Dio();
    const directory = "storage/emulated/0/download";
    const filePath = '$directory/kali-installer.iso';

    final stopwatch = Stopwatch()..start();

    try {
      await _dio.download(
        'https://cdimage.kali.org/kali-2024.2/kali-linux-2024.2-installer-netinst-amd64.iso',
        filePath,
        onReceiveProgress: (receivedBytes, totalBytes) async {
          if (totalBytes != -1) {
            setState(() {
              _totalSize = totalBytes * 0.00000095367432;
              _remainingSize = _totalSize - (receivedBytes * 0.00000095367432);
              _progress = receivedBytes / totalBytes;

              final elapsedTime = stopwatch.elapsed.inSeconds;
              final estimatedTotalTime = (elapsedTime / _progress).round();
              final remainingSeconds = estimatedTotalTime - elapsedTime;

              final minutes = (remainingSeconds / 60).floor();
              final seconds = remainingSeconds % 60;
              _remainingTime =
              '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
            });

            int progressPercentage = (_progress * 100).toInt();
            _showDownloadNotification(progressPercentage);
          }
        },
      );

      // After download completes, cancel the notification
      await flutterLocalNotificationsPlugin.cancel(0);
    } catch (e) {
      print(e);
    }
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
            ElevatedButton(
              onPressed: _startDownload,
              child: const Text('Start Download'),
            ),
          ],
        ),
      ),
    );
  }
}
